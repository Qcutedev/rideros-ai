"""Checks on the trained artifact in ml/artifacts/<model>/<version>/ (skipped when it is absent).

These mirror what the Phase 2 backend must do: verify sha256 before unpickling, load, validate input, predict.
"""

from __future__ import annotations

import json
from datetime import datetime

import joblib
import numpy as np
import pandas as pd
import pytest

from rideros_ml.data.build import TARGET, temporal_split
from rideros_ml.data.download import sha256_file
from rideros_ml.features.inference import make_feature_row
from rideros_ml.intervals.conformal import ConformalInterval
from rideros_ml.models.metrics import regression_metrics
from rideros_ml.paths import ARTIFACTS_DIR, PROCESSED_DIR, REPORTS_DIR

pytestmark = pytest.mark.artifact

REQUIRED_FILES = [
    "pipeline.joblib",
    "preprocessor.joblib",
    "feature_schema.json",
    "conformal.json",
    "metrics.json",
    "metadata.json",
    "model_card.md",
]


@pytest.fixture(scope="module")
def art_dir():
    from rideros_ml.config import load_config

    cfg = load_config()
    return ARTIFACTS_DIR / cfg.model_name / cfg.model_version


@pytest.fixture(scope="module")
def meta(art_dir):
    return json.loads((art_dir / "metadata.json").read_text(encoding="utf-8"))


@pytest.fixture(scope="module")
def pipeline(art_dir, meta):
    path = art_dir / "pipeline.joblib"
    assert sha256_file(path) == meta["files"]["pipeline.joblib"], "refusing to unpickle: sha256 mismatch"
    return joblib.load(path)


def _read(art_dir, name):
    return json.loads((art_dir / name).read_text(encoding="utf-8"))


def test_all_files_present(art_dir, meta):
    for name in REQUIRED_FILES:
        assert (art_dir / name).is_file(), name
    for name in meta["files"]:
        assert (art_dir / name).is_file(), name


def test_file_hashes_match_metadata(art_dir, meta):
    for name, digest in meta["files"].items():
        assert sha256_file(art_dir / name) == digest, name


def test_metadata_is_complete(meta, cfg):
    assert meta["version"] == cfg.model_version
    assert meta["seed"] == cfg.training["seed"]
    assert meta["data"]["commit"] == cfg.dataset.commit
    assert meta["features"] in (cfg.features.deployable, ["poi_id"], ["-"])
    for lib in ["python", "scikit-learn", "catboost", "xgboost", "pandas", "numpy"]:
        assert meta["libraries"][lib] != "not installed"


def test_artifact_is_not_a_smoke_run(art_dir):
    m = _read(art_dir, "metrics.json")
    assert m["quick_smoke_test"] is False
    assert m["tuning"]["xgboost"]["n_trials_completed"] >= 1


def test_feature_schema_matches_config(art_dir, cfg):
    schema = _read(art_dir, "feature_schema.json")
    assert [i["name"] for i in schema["inputs"]] == cfg.features.deployable
    assert schema["target"]["name"] == TARGET


def test_conformal_json_matches_metadata(art_dir, meta, cfg):
    conf = ConformalInterval(**_read(art_dir, "conformal.json"))
    assert conf.to_dict() == meta["conformal"]
    assert conf.alpha == cfg.conformal_alpha
    assert conf.q_low < 0 < conf.q_high


def test_artifact_metrics_equal_report_metrics(art_dir, cfg, meta):
    report = REPORTS_DIR / cfg.model_name / meta["version"] / "metrics.json"
    assert _read(art_dir, "metrics.json") == json.loads(report.read_text(encoding="utf-8"))


def test_predict_from_backend_row(pipeline, art_dir):
    ref = pd.read_csv(
        ARTIFACTS_DIR / "restaurant_stats" / art_dir.name / "restaurant_reference.csv",
        dtype={"poi_id": str, "reference_da_id": str},
    )
    sample = ref[ref["data_availability"] == "sufficient"].head(20)
    rows = pd.concat(
        [
            make_feature_row(p, d, datetime(2022, 10, 24, 12, 15))
            for p, d in zip(sample["poi_id"], sample["reference_da_id"], strict=True)
        ]
    )
    pred = pipeline.predict(rows)
    assert pred.shape == (len(sample),)
    assert np.isfinite(pred).all()
    assert ((pred > 0) & (pred < 120)).all()


def test_unseen_restaurant_still_predicts(pipeline):
    pred = pipeline.predict(
        make_feature_row("not-a-real-poi", "not-a-real-da", datetime(2022, 10, 24, 18, 0))
    )
    assert np.isfinite(pred).all() and 0 < pred[0] < 120


def test_prediction_varies_with_time_of_day(pipeline):
    rows = pd.concat([make_feature_row("1", "1", datetime(2022, 10, 24, h, 0)) for h in range(24)])
    assert np.ptp(pipeline.predict(rows)) > 0


def test_missing_input_column_raises(pipeline):
    row = make_feature_row("1", "1", datetime(2022, 10, 24, 12)).drop(columns=["hour"])
    with pytest.raises(KeyError):
        pipeline.predict(row)


def test_non_numeric_input_raises(pipeline):
    row = make_feature_row("1", "1", datetime(2022, 10, 24, 12)).assign(is_weekend="yes")
    with pytest.raises((ValueError, TypeError)):
        pipeline.predict(row)


def test_forbidden_column_in_request_is_ignored_not_used(pipeline):
    row = make_feature_row("1", "1", datetime(2022, 10, 24, 12))
    leaky = row.assign(fetch_time=0, estimate_meal_prepare_time=999_999_999)
    assert pipeline.predict(leaky) == pytest.approx(pipeline.predict(row))


@pytest.mark.data
def test_reloaded_artifact_reproduces_reported_test_metrics(pipeline, art_dir, meta, cfg):
    """Loading the exported pipeline and scoring the test day gives exactly the numbers in metrics.json."""
    orders = pd.read_parquet(PROCESSED_DIR / "orders.parquet")
    test = temporal_split(orders, cfg)["test"]
    reported = _read(art_dir, "metrics.json")
    sel = reported["selected_model"]
    got = regression_metrics(test[TARGET], pipeline.predict(test))
    for k in ["n", "mae", "rmse", "r2", "median_ae", "bias"]:
        assert got[k] == pytest.approx(reported["test"][sel][k], abs=1e-6), k

    conf = ConformalInterval(**_read(art_dir, "conformal.json"))
    low, high = conf.interval(pipeline.predict(test))
    inside = float(((test[TARGET] >= low) & (test[TARGET] <= high)).mean())
    assert inside == pytest.approx(reported["conformal_test"]["coverage"], abs=1e-9)


@pytest.mark.data
def test_parquet_hash_matches_artifact_metadata(meta):
    assert sha256_file(PROCESSED_DIR / "orders.parquet") == meta["data"]["orders_parquet_sha256"]
