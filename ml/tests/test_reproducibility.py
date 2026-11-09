"""Same seed -> same models and the same results.

Fast tests refit every candidate twice on synthetic data. The slow `data` test re-runs the real
`train --quick` pipeline into a temporary directory and compares it with the stored quick-smoke run.
"""

from __future__ import annotations

import json

import numpy as np
import pytest

from rideros_ml.data.build import TARGET, temporal_split
from rideros_ml.models import candidates as C
from rideros_ml.models.tuning import tune
from rideros_ml.paths import REPORTS_DIR

SEED = 42
DEPLOY = ["poi_id", "da_id", "hour", "minute_sin", "minute_cos", "is_weekend"]
# Tolerance for "same result": exact up to floating-point noise from multithreaded summation.
ATOL = 1e-6


@pytest.fixture
def parts(synthetic_orders, cfg):
    p = temporal_split(synthetic_orders(n_per_day=250), cfg)
    return p["train"], p["train"][TARGET].to_numpy(), p["val"], p["val"][TARGET].to_numpy()


def _fit_twice(fit):
    return fit(), fit()


@pytest.mark.parametrize(
    "name",
    ["global_median", "poi_median", "linear", "random_forest", "xgboost", "catboost"],
)
def test_candidate_refit_is_identical(parts, name):
    train, y, val, y_val = parts
    builders = {
        "global_median": lambda: C.fit_global_median(train, y),
        "poi_median": lambda: C.fit_poi_median(train, y),
        "linear": lambda: C.fit_linear(train, y, DEPLOY, SEED),
        "random_forest": lambda: C.fit_random_forest(
            train,
            y,
            DEPLOY,
            SEED,
            {"n_estimators": 20, "min_samples_leaf": 5, "max_features": 0.6, "max_samples": 0.5},
        ),
        "xgboost": lambda: C.fit_xgboost(
            train, y, val, y_val, DEPLOY, SEED, {"learning_rate": 0.2, "max_depth": 4, "subsample": 0.8}
        ),
        "catboost": lambda: C.fit_catboost(
            train, y, val, y_val, DEPLOY, SEED, {"learning_rate": 0.3, "depth": 4, "bagging_temperature": 0.5}
        ),
    }
    a, b = _fit_twice(builders[name])
    np.testing.assert_allclose(a.predict(val), b.predict(val), atol=ATOL, rtol=0)


def test_different_seed_changes_a_stochastic_model(parts):
    train, y, val, _ = parts
    params = {"n_estimators": 20, "min_samples_leaf": 5, "max_features": 0.6, "max_samples": 0.5}
    a = C.fit_random_forest(train, y, DEPLOY, 1, params).predict(val)
    b = C.fit_random_forest(train, y, DEPLOY, 2, params).predict(val)
    assert not np.allclose(a, b)


def test_tuning_is_reproducible(parts):
    train, y, val, y_val = parts
    a = tune("xgboost", train, y, val, y_val, DEPLOY, SEED, n_trials=3, timeout_s=None)
    b = tune("xgboost", train, y, val, y_val, DEPLOY, SEED, n_trials=3, timeout_s=None)
    assert a["best_params"] == b["best_params"]
    assert a["best_val_mae"] == pytest.approx(b["best_val_mae"], abs=ATOL)
    assert [t["params"] for t in a["trials"]] == [t["params"] for t in b["trials"]]


def _numeric_leaves(obj, prefix=""):
    if isinstance(obj, dict):
        for k, v in obj.items():
            yield from _numeric_leaves(v, f"{prefix}/{k}")
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from _numeric_leaves(v, f"{prefix}[{i}]")
    elif isinstance(obj, (int, float)) and not isinstance(obj, bool):
        yield prefix, float(obj)


@pytest.mark.data
@pytest.mark.slow
def test_quick_pipeline_matches_stored_smoke_run(cfg, tmp_path, monkeypatch):
    """End-to-end: raw-derived orders.parquet -> train --quick gives the same numbers as the stored run."""
    reference = REPORTS_DIR / cfg.model_name / "quick-smoke" / "metrics.json"
    if not reference.exists():
        pytest.skip("no stored quick-smoke run to compare against (run `rideros-ml train --quick` once)")
    from rideros_ml.models import train as train_mod

    monkeypatch.setattr(train_mod, "REPORTS_DIR", tmp_path / "reports")
    monkeypatch.setattr(train_mod, "ARTIFACTS_DIR", tmp_path / "artifacts")
    train_mod.run_training(cfg, quick=True)

    new = json.loads(
        (tmp_path / "reports" / cfg.model_name / "quick-smoke" / "metrics.json").read_text(encoding="utf-8")
    )
    old = json.loads(reference.read_text(encoding="utf-8"))
    assert new["selected_model"] == old["selected_model"]
    assert new["split_sizes"] == old["split_sizes"]
    for section in [
        "validation",
        "test",
        "benchmark_meituan_estimate",
        "conformal_test",
        "conformal_test_by_poi_bucket",
    ]:
        a, b = dict(_numeric_leaves(new[section])), dict(_numeric_leaves(old[section]))
        assert a.keys() == b.keys(), section
        for key in a:
            assert a[key] == pytest.approx(b[key], abs=ATOL), f"{section}{key}"
    assert new["tuning"]["xgboost"]["best_params"] == pytest.approx(old["tuning"]["xgboost"]["best_params"])
    assert new["tuning"]["catboost"]["best_params"] == pytest.approx(old["tuning"]["catboost"]["best_params"])
