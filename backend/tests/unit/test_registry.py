"""Model artifact verification: nothing is unpickled unless hashes, schema and versions check out."""

import json
import shutil
from datetime import datetime
from pathlib import Path

import pytest

from app.ml import predictor
from app.ml.registry import ArtifactError, Conformal, load_model
from tests import fake_artifact


@pytest.fixture(scope="module")
def pristine(tmp_path_factory: pytest.TempPathFactory) -> Path:
    root = tmp_path_factory.mktemp("pristine")
    fake_artifact.build(root)
    return root


@pytest.fixture
def root(pristine: Path, tmp_path: Path) -> Path:
    shutil.copytree(pristine, tmp_path / "artifacts")
    return tmp_path / "artifacts"


def folder(root: Path) -> Path:
    return root / fake_artifact.NAME / fake_artifact.VERSION


def load(root: Path):
    return load_model(root, fake_artifact.NAME, fake_artifact.VERSION)


def test_loads_valid_artifact(root: Path) -> None:
    model = load(root)
    assert model.artifact_uri == "pickup_o2p/0.0.0-test"
    assert model.conformal == Conformal(0.2, fake_artifact.Q_LOW, fake_artifact.Q_HIGH)
    assert model.pipeline.steps[-1][1].get_params()["n_jobs"] == 1


async def test_prediction_and_interval(root: Path) -> None:
    model = load(root)
    result = await predictor.predict(model, poi_id="3", da_id="1", local_time=datetime(2026, 11, 9, 18, 30))
    assert result.low == max(result.minutes + fake_artifact.Q_LOW, 0) and result.high == result.minutes + 5
    assert result.features["hour"] == 18 and result.features["is_weekend"] == 0
    assert result.features["local_time"] == "2026-11-09T18:30:00"
    with pytest.raises(ValueError, match="naive LOCAL"):
        await predictor.predict(model, poi_id="3", da_id="1", local_time=datetime.now().astimezone())


def test_interval_floor_is_zero() -> None:
    assert Conformal(0.2, -6.0, 8.0).interval(2.0) == (0.0, 10.0)


def test_tampered_pickle_is_rejected_before_loading(root: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    with (folder(root) / "pipeline.joblib").open("ab") as fh:
        fh.write(b"\0")
    called = []
    monkeypatch.setattr("app.ml.registry.joblib.load", lambda *_a, **_k: called.append(1))
    with pytest.raises(ArtifactError, match="SHA-256 mismatch"):
        load(root)
    assert called == []  # never unpickled


@pytest.mark.parametrize(
    ("overrides", "message"),
    [
        ({"files": {}}, "no SHA-256"),
        ({"files": {"../metadata.json": "x", "pipeline.joblib": "0" * 64}}, "missing: ../metadata.json"),
        ({"features": ["poi_id"]}, "does not match"),
        ({"version": "9.9.9"}, "describes"),
        ({"libraries": {"python": "3.14", "scikit-learn": "0.1"}}, "library versions differ"),
        ({"libraries": {**{"python": "2.7"}}}, "python"),
    ],
    ids=["no-hashes", "path-in-files", "features", "version", "sklearn-version", "python-version"],
)
def test_metadata_problems_fail_fast(root: Path, overrides: dict, message: str) -> None:
    fake_artifact.write_metadata(folder(root), **overrides)
    with pytest.raises(ArtifactError, match=message):
        load(root)


def test_schema_target_mismatch(root: Path) -> None:
    path = folder(root) / "feature_schema.json"
    schema = json.loads(path.read_text(encoding="utf-8"))
    schema["target"]["name"] = "rider_wait_min"
    path.write_text(json.dumps(schema), encoding="utf-8")
    with pytest.raises(ArtifactError, match="unexpected target"):
        load(root)


@pytest.mark.parametrize("name", ["conformal.json", "metrics.json", "pipeline.joblib"])
def test_missing_file(root: Path, name: str) -> None:
    (folder(root) / name).unlink()
    with pytest.raises(ArtifactError, match="not found"):
        load(root)


def test_unreadable_json_and_bad_conformal(root: Path) -> None:
    (folder(root) / "conformal.json").write_text("{}", encoding="utf-8")
    with pytest.raises(ArtifactError, match="invalid conformal"):
        load(root)
    (folder(root) / "metadata.json").write_text("not json", encoding="utf-8")
    with pytest.raises(ArtifactError, match="cannot read metadata.json"):
        load(root)


def test_unknown_version_folder(root: Path) -> None:
    with pytest.raises(ArtifactError, match="not found"):
        load_model(root, fake_artifact.NAME, "1.2.3")
