"""Regression metrics, segment helpers and baselines."""

from __future__ import annotations

import math

import numpy as np
import pandas as pd
import pytest

from rideros_ml.models.baselines import GlobalMedianRegressor, PoiMedianRegressor
from rideros_ml.models.metrics import hour_band, poi_bucket, regression_metrics, segment_metrics


def test_metrics_hand_example():
    m = regression_metrics([1, 2, 3], [2, 2, 2])
    assert m["n"] == 3
    assert m["mae"] == pytest.approx(2 / 3)
    assert m["rmse"] == pytest.approx(math.sqrt(2 / 3))
    assert m["r2"] == pytest.approx(0.0)
    assert m["median_ae"] == pytest.approx(1.0)
    assert m["bias"] == pytest.approx(0.0)


def test_bias_sign_is_prediction_minus_truth():
    assert regression_metrics([10, 10], [12, 14])["bias"] == pytest.approx(3.0)


def test_perfect_prediction():
    m = regression_metrics([1.0, 4.0, 9.0], [1.0, 4.0, 9.0])
    assert m["mae"] == 0 and m["rmse"] == 0 and m["r2"] == pytest.approx(1.0)


def test_r2_undefined_for_constant_truth():
    assert math.isnan(regression_metrics([5, 5, 5], [4, 5, 6])["r2"])


def test_hour_band_covers_every_hour_once():
    bands = hour_band(pd.Series(range(24)))
    assert bands.notna().all()
    assert bands[12] == "11-13 lunch" and bands[18] == "17-20 dinner" and bands[0] == "00-05"


def test_poi_bucket_edges():
    b = poi_bucket(pd.Series([0, 1, 29, 30, 99, 100, 499, 500, 10_000]))
    assert b.tolist() == [
        "unseen in train",
        "1-29",
        "1-29",
        "30-99",
        "30-99",
        "100-499",
        "100-499",
        "500+",
        "500+",
    ]


def test_segment_metrics_per_group():
    df = pd.DataFrame({"y": [1.0, 2.0, 10.0, 20.0], "p": [1.0, 3.0, 10.0, 10.0]})
    seg = pd.Series(["a", "a", "b", "b"])
    out = segment_metrics(df, "y", "p", seg)
    assert out["a"]["n"] == 2 and out["a"]["mae"] == pytest.approx(0.5)
    assert out["b"]["mae"] == pytest.approx(5.0)


def test_global_median_baseline():
    m = GlobalMedianRegressor().fit(pd.DataFrame({"x": range(5)}), [1, 2, 3, 100, 200])
    assert m.predict(pd.DataFrame({"x": [0, 1]})).tolist() == [3.0, 3.0]


def test_poi_median_baseline_with_fallback():
    X = pd.DataFrame({"poi_id": ["a"] * 5 + ["b"] * 2})
    y = [10, 11, 12, 13, 14, 50, 60]
    m = PoiMedianRegressor(min_count=5).fit(X, y)
    pred = m.predict(pd.DataFrame({"poi_id": ["a", "b", "unseen"]}))
    # "b" has 2 < 5 orders and unseen has none -> global median of all 7 values (13)
    assert pred.tolist() == [12.0, 13.0, 13.0]
    assert np.isfinite(pred).all()
