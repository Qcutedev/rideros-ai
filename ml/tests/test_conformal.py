"""Split conformal intervals."""

from __future__ import annotations

import numpy as np
import pytest

from rideros_ml.intervals.conformal import ConformalInterval, _finite_sample_level, calibrate, coverage


def test_needs_100_calibration_points():
    with pytest.raises(ValueError, match="at least 100"):
        calibrate(np.zeros(99), np.zeros(99), 0.2)


@pytest.mark.parametrize("alpha", [0.1, 0.2])
def test_marginal_coverage_on_exchangeable_data(alpha):
    rng = np.random.default_rng(0)
    y_cal = rng.normal(0, 1, 3000)
    y_test = rng.normal(0, 1, 50_000)
    ci = calibrate(y_cal, np.zeros_like(y_cal), alpha)
    low, high = ci.interval(np.zeros_like(y_test), floor=-np.inf)
    cov = coverage(y_test, low, high)["coverage"]
    assert cov >= 1 - alpha - 0.01
    assert cov <= 1 - alpha + 0.03


def test_skewed_residuals_give_asymmetric_interval():
    rng = np.random.default_rng(1)
    y = rng.exponential(5, 2000)  # right-skewed, like pickup delays
    ci = calibrate(y, np.full_like(y, np.median(y)), 0.2)
    assert ci.q_low < 0 < ci.q_high
    assert ci.q_high > -ci.q_low


def test_interval_floor_clips_low_bound():
    ci = ConformalInterval(alpha=0.2, q_low=-5.0, q_high=4.0, n_calibration=100)
    low, high = ci.interval([2.0, 10.0])
    assert low.tolist() == [0.0, 5.0]
    assert high.tolist() == [6.0, 14.0]


def test_finite_sample_levels_are_conservative_and_bounded():
    n = 1000
    assert _finite_sample_level(n, 0.1, upper=True) >= 0.9
    assert _finite_sample_level(n, 0.1, upper=False) <= 0.1
    assert _finite_sample_level(100, 0.001, upper=True) == 1.0
    assert _finite_sample_level(100, 0.001, upper=False) == 0.0


def test_coverage_hand_example():
    out = coverage([1, 5, 10], np.array([0, 6, 9]), np.array([2, 8, 10]))
    assert out["coverage"] == pytest.approx(2 / 3)
    assert out["mean_width"] == pytest.approx((2 + 2 + 1) / 3)


def test_to_dict_round_trip():
    ci = ConformalInterval(alpha=0.2, q_low=-1.5, q_high=2.5, n_calibration=123)
    assert ConformalInterval(**ci.to_dict()) == ci
