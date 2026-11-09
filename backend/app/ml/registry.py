"""Load and verify the active pickup model artifact (docs/HANDOFF.md §2, SYSTEM_ARCHITECTURE §2.2).

Order of checks, all before anything is unpickled (pickle can run code):
1. every file listed in metadata.json `files` exists and matches its SHA-256;
2. feature_schema.json / metadata.json describe exactly the features the backend builds;
3. the installed library versions equal the ones the model was trained with.
Any failure raises ArtifactError, and the app refuses to start (fail fast).
"""

import hashlib
import json
import platform
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import joblib
import numpy
import pandas
import sklearn
import xgboost

# What app/ml/predictor.py builds via rideros_ml.features.inference.make_feature_row.
EXPECTED_FEATURES = ["poi_id", "da_id", "hour", "minute_sin", "minute_cos", "is_weekend"]
EXPECTED_TARGET = "order_to_pickup_min"
REQUIRED_FILES = ("metadata.json", "feature_schema.json", "conformal.json", "metrics.json", "pipeline.joblib")
_INSTALLED = {
    "scikit-learn": sklearn.__version__,
    "xgboost": xgboost.__version__,
    "pandas": pandas.__version__,
    "numpy": numpy.__version__,
    "joblib": joblib.__version__,
}


class ArtifactError(RuntimeError):
    """The artifact is missing, altered or incompatible. Raised at startup."""


@dataclass(frozen=True, slots=True)
class Conformal:
    alpha: float
    q_low: float
    q_high: float

    def interval(self, y_hat: float) -> tuple[float, float]:
        return max(y_hat + self.q_low, 0.0), y_hat + self.q_high


@dataclass(frozen=True, slots=True)
class LoadedModel:
    name: str
    version: str
    pipeline: Any
    conformal: Conformal
    metadata: dict[str, Any]
    metrics: dict[str, Any]
    feature_schema: dict[str, Any]

    @property
    def artifact_uri(self) -> str:
        return f"{self.name}/{self.version}"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _read_json(folder: Path, name: str) -> dict[str, Any]:
    try:
        return json.loads((folder / name).read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise ArtifactError(f"cannot read {name}: {exc}") from exc


def _verify_hashes(folder: Path, metadata: dict[str, Any]) -> None:
    files = metadata.get("files")
    if not isinstance(files, dict) or "pipeline.joblib" not in files:
        raise ArtifactError("metadata.json has no SHA-256 for pipeline.joblib; refusing to unpickle")
    for name, expected in files.items():
        path = folder / name
        if Path(name).name != name or not path.is_file():
            raise ArtifactError(f"artifact file missing: {name}")
        if sha256_file(path) != expected:
            raise ArtifactError(f"SHA-256 mismatch for {name}; refusing to load")


def _verify_schema(metadata: dict[str, Any], schema: dict[str, Any], name: str, version: str) -> None:
    if metadata.get("model") != name or metadata.get("version") != version:
        raise ArtifactError(f"metadata.json describes {metadata.get('model')}/{metadata.get('version')}")
    inputs = [item.get("name") for item in schema.get("inputs", [])]
    if inputs != EXPECTED_FEATURES or metadata.get("features") != EXPECTED_FEATURES:
        raise ArtifactError(f"feature schema {inputs} does not match the backend builder {EXPECTED_FEATURES}")
    if schema.get("target", {}).get("name") != EXPECTED_TARGET:
        raise ArtifactError(f"unexpected target {schema.get('target')!r}")


def _verify_libraries(metadata: dict[str, Any]) -> None:
    trained = metadata.get("libraries", {})
    problems = [
        f"{lib} {installed} (trained with {trained.get(lib)})"
        for lib, installed in _INSTALLED.items()
        if trained.get(lib) != installed
    ]
    trained_py = str(trained.get("python", ""))
    if trained_py.split(".")[:2] != platform.python_version().split(".")[:2]:
        problems.append(f"python {platform.python_version()} (trained with {trained_py})")
    if problems:
        raise ArtifactError("library versions differ from training: " + ", ".join(problems))


def load_model(model_dir: Path, name: str, version: str) -> LoadedModel:
    folder = model_dir / name / version
    for required in REQUIRED_FILES:
        if not (folder / required).is_file():
            raise ArtifactError(f"{folder}: {required} not found")
    metadata = _read_json(folder, "metadata.json")
    schema = _read_json(folder, "feature_schema.json")
    conformal = _read_json(folder, "conformal.json")
    metrics = _read_json(folder, "metrics.json")

    _verify_hashes(folder, metadata)
    _verify_schema(metadata, schema, name, version)
    _verify_libraries(metadata)

    pipeline = joblib.load(folder / "pipeline.joblib")  # hash verified above
    estimator = pipeline.steps[-1][1] if hasattr(pipeline, "steps") else pipeline
    if hasattr(estimator, "set_params") and "n_jobs" in estimator.get_params():
        estimator.set_params(n_jobs=1)  # one request = one row; avoid a thread pool per call
    try:
        interval = Conformal(float(conformal["alpha"]), float(conformal["q_low"]), float(conformal["q_high"]))
    except (KeyError, TypeError, ValueError) as exc:
        raise ArtifactError(f"invalid conformal.json: {exc}") from exc
    return LoadedModel(name, version, pipeline, interval, metadata, metrics, schema)
