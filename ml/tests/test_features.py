"""Feature selection guards, encoders, and train/serve parity of the inference row builder."""

from __future__ import annotations

from datetime import UTC, datetime

import numpy as np
import pandas as pd
import pytest

from rideros_ml.data.build import add_time_features
from rideros_ml.data.schema import PLATFORM_ESTIMATE_COLUMNS, POST_T0_COLUMNS
from rideros_ml.export.artifact import feature_schema
from rideros_ml.features.inference import make_feature_row
from rideros_ml.features.pipelines import CountEncoder, FeatureFrame, tree_preprocessor

DEPLOY = ["poi_id", "da_id", "hour", "minute_sin", "minute_cos", "is_weekend"]


def test_config_deployable_set_is_the_documented_one(cfg):
    assert cfg.features.deployable == DEPLOY
    assert not set(cfg.features.deployable) & set(cfg.features.ablation_extra)


@pytest.mark.parametrize(
    "bad",
    [
        *sorted(POST_T0_COLUMNS),
        *sorted(PLATFORM_ESTIMATE_COLUMNS),
        "order_to_pickup_min",
        "meituan_est_ready_min",
    ],
)
def test_feature_frame_rejects_forbidden_columns(bad):
    with pytest.raises(ValueError, match="forbidden"):
        FeatureFrame([*DEPLOY, bad]).fit(pd.DataFrame())


def test_config_feature_sets_contain_no_forbidden_column(cfg):
    FeatureFrame(cfg.features.deployable + cfg.features.ablation_extra).fit(pd.DataFrame())


def test_feature_frame_missing_column_raises():
    frame = FeatureFrame(DEPLOY).fit(None)
    with pytest.raises(KeyError, match="minute_cos"):
        frame.transform(make_feature_row("1", "2", datetime(2022, 10, 24, 12)).drop(columns=["minute_cos"]))


def test_feature_frame_coerces_types_and_drops_extra_columns():
    X = pd.DataFrame(
        {
            "poi_id": [5],
            "da_id": [3],
            "hour": ["7"],
            "minute_sin": [0],
            "minute_cos": [1],
            "is_weekend": [0],
            "fetch_time": [1],
        }
    )
    out = FeatureFrame(DEPLOY).fit(X).transform(X)
    assert list(out.columns) == DEPLOY
    assert out.loc[0, "poi_id"] == "5" and out.loc[0, "da_id"] == "3"
    assert out["hour"].dtype == "int64" and out["is_weekend"].dtype == "int64"
    assert out["minute_sin"].dtype == "float64"


def test_feature_frame_non_numeric_value_raises():
    X = make_feature_row("1", "2", datetime(2022, 10, 24, 12)).assign(hour="noon")
    with pytest.raises((ValueError, TypeError)):
        FeatureFrame(DEPLOY).fit(X).transform(X)


def test_count_encoder_unseen_is_zero():
    enc = CountEncoder().fit(pd.DataFrame({"poi_id": ["a", "a", "b"]}))
    out = enc.transform(pd.DataFrame({"poi_id": ["a", "b", "zzz"]}))
    assert out[:, 0].tolist() == pytest.approx([np.log1p(2), np.log1p(1), 0.0])


def test_poi_target_encoding_is_cross_fitted():
    """A restaurant with a single extreme training row must not see its own target in fit_transform."""
    rng = np.random.default_rng(0)
    n = 500
    X = pd.DataFrame(
        {
            "poi_id": [*rng.integers(0, 10, n - 1).astype(str), "lonely"],
            "da_id": "1",
            "hour": 12,
            "minute_sin": 0.0,
            "minute_cos": 1.0,
            "is_weekend": 0,
        }
    )
    y = np.r_[rng.normal(10, 1, n - 1), 1000.0]
    pre = tree_preprocessor(DEPLOY, seed=42)
    names = list(pre.fit(FeatureFrame(DEPLOY).transform(X), y).get_feature_names_out())
    te_col = names.index("poi_id")
    pre = tree_preprocessor(DEPLOY, seed=42)
    cross_fitted = pre.fit_transform(FeatureFrame(DEPLOY).transform(X), y)[:, te_col]
    full_fit = pre.transform(FeatureFrame(DEPLOY).transform(X))[:, te_col]
    # Out-of-fold value of the lonely row: prior from the other folds (~ mean of y without itself, ~ 10-12)
    assert cross_fitted[-1] < 50
    # Inference-time value uses full-train statistics and therefore does include the row
    assert full_fit[-1] > cross_fitted[-1]
    assert not np.allclose(cross_fitted, full_fit)


# ---------------- make_feature_row ----------------


def test_make_feature_row_values():
    row = make_feature_row(123, 7, datetime(2022, 10, 22, 12, 0)).iloc[0]  # Saturday noon
    assert list(row.index) == DEPLOY
    assert row["poi_id"] == "123" and row["da_id"] == "7"
    assert row["hour"] == 12 and row["is_weekend"] == 1
    assert row["minute_sin"] == pytest.approx(0.0, abs=1e-12)
    assert row["minute_cos"] == pytest.approx(-1.0)


def test_make_feature_row_weekday_and_midnight():
    row = make_feature_row("1", "1", datetime(2022, 10, 24, 0, 0)).iloc[0]  # Monday
    assert row["is_weekend"] == 0 and row["hour"] == 0
    assert row["minute_sin"] == pytest.approx(0.0) and row["minute_cos"] == pytest.approx(1.0)


def test_make_feature_row_rejects_aware_datetime():
    with pytest.raises(ValueError, match="naive LOCAL"):
        make_feature_row("1", "1", datetime(2022, 10, 24, 12, tzinfo=UTC))


@pytest.mark.parametrize(
    "utc", ["2022-10-16 17:59:00", "2022-10-21 18:30:00", "2022-10-24 03:07:00", "2022-10-23 15:59:00"]
)
def test_inference_row_matches_training_features(utc, cfg):
    """Train/serve parity: the backend row for a local time equals what build.py computed for that order."""
    t0 = int(pd.Timestamp(utc).timestamp())
    train_row = add_time_features(
        pd.DataFrame({"platform_order_time": [t0]}), cfg.dataset.local_utc_offset_hours
    ).iloc[0]
    local = datetime.fromtimestamp(t0, UTC).replace(tzinfo=None) + pd.Timedelta(
        hours=cfg.dataset.local_utc_offset_hours
    )
    serve_row = make_feature_row("1", "1", local).iloc[0]
    assert serve_row["hour"] == train_row["hour"]
    assert serve_row["minute_sin"] == pytest.approx(train_row["minute_sin"])
    assert serve_row["minute_cos"] == pytest.approx(train_row["minute_cos"])
    assert serve_row["is_weekend"] == int(pd.Timestamp(train_row["local_date"]).weekday() >= 5)


def test_feature_schema_lists_exactly_the_deployable_inputs(cfg):
    schema = feature_schema(cfg.model_name, cfg.model_version, cfg.features.deployable, cfg.conformal_alpha)
    assert [i["name"] for i in schema["inputs"]] == cfg.features.deployable
    assert schema["target"]["name"] == "order_to_pickup_min"
    assert "rider waiting time at the restaurant" in schema["target"]["is_not"]
    assert "80%" in schema["output"]["interval"]
