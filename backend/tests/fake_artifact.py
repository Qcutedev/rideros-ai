"""A small artifact with the same layout and pipeline classes as ml/artifacts/pickup_o2p/<version>/.

Trained on synthetic rows so API tests run without the real (gitignored, licence-restricted) model.
It is only a test fixture: its numbers say nothing about real accuracy.
"""

import json
import platform
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import sklearn
import xgboost
from rideros_ml.features.pipelines import FeatureFrame, tree_preprocessor
from sklearn.pipeline import Pipeline
from xgboost import XGBRegressor

from app.ml.registry import EXPECTED_FEATURES, EXPECTED_TARGET, sha256_file

NAME, VERSION = "pickup_o2p", "0.0.0-test"
Q_LOW, Q_HIGH = -3.0, 5.0


def _training_frame(rows: int = 600) -> tuple[pd.DataFrame, np.ndarray]:
    rng = np.random.default_rng(7)
    poi = rng.integers(0, 6, rows).astype(str)
    hour = rng.integers(0, 24, rows)
    minute = hour * 60 + rng.integers(0, 60, rows)
    angle = 2 * np.pi * minute / 1440
    frame = pd.DataFrame(
        {
            "poi_id": poi,
            "da_id": (rng.integers(0, 3, rows)).astype(str),
            "hour": hour,
            "minute_sin": np.sin(angle),
            "minute_cos": np.cos(angle),
            "is_weekend": rng.integers(0, 2, rows),
        }
    )
    y = 8 + poi.astype(int) * 1.5 + (hour >= 17) * 4 + rng.normal(0, 1, rows)
    return frame, y


def build(root: Path) -> Path:
    """Write <root>/pickup_o2p/0.0.0-test/ and return its folder."""
    folder = root / NAME / VERSION
    folder.mkdir(parents=True, exist_ok=True)
    train, y = _training_frame()
    frame = FeatureFrame(EXPECTED_FEATURES).fit(train)
    pre = tree_preprocessor(EXPECTED_FEATURES, seed=0)
    xt = pre.fit_transform(frame.transform(train), y)
    model = XGBRegressor(n_estimators=30, max_depth=3, random_state=0, n_jobs=1).fit(xt, y)
    joblib.dump(Pipeline([("frame", frame), ("pre", pre), ("model", model)]), folder / "pipeline.joblib")

    schema = {
        "model": NAME,
        "version": VERSION,
        "target": {"name": EXPECTED_TARGET, "unit": "minutes", "is_not": ["food preparation time"]},
        "inputs": [{"name": n} for n in EXPECTED_FEATURES],
        "domain": "Synthetic test data.",
    }
    metrics = {
        "selected_model": "xgboost",
        "test": {"xgboost": {"mae": 1.0, "rmse": 1.2, "r2": 0.5}, "baseline_poi_median": {"mae": 1.25}},
        "conformal_test": {"coverage": 0.8, "mean_width": 8.0},
        "conformal_test_by_poi_bucket": {"30-99": 0.8, "unseen in train": 0.6},  # same shape as metrics.json
    }
    (folder / "feature_schema.json").write_text(json.dumps(schema), encoding="utf-8")
    (folder / "metrics.json").write_text(json.dumps(metrics), encoding="utf-8")
    (folder / "conformal.json").write_text(
        json.dumps({"alpha": 0.2, "q_low": Q_LOW, "q_high": Q_HIGH, "n_calibration": 100}), encoding="utf-8"
    )
    write_metadata(folder)
    return folder


def write_metadata(folder: Path, **overrides: object) -> None:
    metadata = {
        "model": NAME,
        "version": VERSION,
        "features": EXPECTED_FEATURES,
        "data": {"commit": "test-fixture", "rows": 600},
        "created_at": "2026-11-09T00:00:00+00:00",
        "libraries": {
            "python": platform.python_version(),
            "scikit-learn": sklearn.__version__,
            "xgboost": xgboost.__version__,
            "pandas": pd.__version__,
            "numpy": np.__version__,
            "joblib": joblib.__version__,
        },
        "files": {"pipeline.joblib": sha256_file(folder / "pipeline.joblib")},
    }
    metadata.update(overrides)
    (folder / "metadata.json").write_text(json.dumps(metadata), encoding="utf-8")
