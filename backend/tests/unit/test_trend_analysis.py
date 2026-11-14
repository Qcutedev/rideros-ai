"""Moving average + linear trend of net profit (app/modules/profit/trend_analysis.py)."""

import random
from decimal import Decimal

import pytest

from app.modules.profit import trend_analysis as ta


def d(values: list[float]) -> list[Decimal]:
    return [Decimal(str(v)) for v in values]


def test_no_records_is_insufficient_with_empty_series() -> None:
    result = ta.analyse(d([0, 0, 0]), [False] * 3, "day")
    assert result.status == "insufficient_data" and result.active_buckets == 0
    assert result.direction is None and result.slope_per_bucket is None
    assert result.moving_average == [None] * 3 and result.trend_line == [None] * 3


def test_fewer_than_min_active_buckets_is_insufficient_but_keeps_moving_average() -> None:
    values = [100, 0, 0, 0, 0, 0, 120]  # records on the first and the last day only
    flags = [True, False, False, False, False, False, True]
    result = ta.analyse(d(values), flags, "day")
    assert result.status == "insufficient_data" and result.active_buckets == 2
    assert result.direction is None and result.trend_line == [None] * 7
    assert result.moving_average == [None] * 6 + [Decimal("31.43")]  # 220 / 7


def test_moving_average_window_and_span() -> None:
    # Buckets 0-1 before the first record and bucket 7 after the last one are outside the span.
    values = [0, 0, 30, 60, 90, 120, 150, 0]
    flags = [False, False, True, True, True, True, True, False]
    result = ta.analyse(d(values), flags, "month")  # window 3
    assert result.moving_average_window == 3
    assert result.moving_average == [
        None,
        None,
        None,
        None,
        Decimal("60.00"),
        Decimal("90.00"),
        Decimal("120.00"),
        None,
    ]


@pytest.mark.parametrize(("granularity", "window"), [("day", 7), ("week", 4), ("month", 3)])
def test_window_per_granularity(granularity: ta.Granularity, window: int) -> None:
    assert ta.analyse(d([1] * 10), [True] * 10, granularity).moving_average_window == window


def test_clear_rise_is_up_with_exact_line() -> None:
    values = [100 + 25 * i for i in range(8)]
    result = ta.analyse(d(values), [True] * 8, "week")
    assert result.status == "ok" and result.direction == "up"
    assert (
        result.slope_per_bucket == Decimal("25.00") and result.p_value is not None and result.p_value < 0.05
    )
    assert result.trend_line == d([100 + 25 * i for i in range(8)])


def test_clear_fall_is_down() -> None:
    rng = random.Random(1)
    values = [1000 - 40 * i + rng.uniform(-30, 30) for i in range(20)]
    result = ta.analyse(d(values), [True] * 20, "day")
    assert result.direction == "down" and result.slope_per_bucket is not None and result.slope_per_bucket < 0


def test_noise_without_trend_is_flat_and_draws_no_line() -> None:
    rng = random.Random(7)
    values = [500 + rng.uniform(-200, 200) for _ in range(30)]
    result = ta.analyse(d(values), [True] * 30, "day")
    assert result.status == "ok" and result.direction == "flat"
    assert result.p_value is not None and result.p_value >= 0.05
    assert result.trend_line == [None] * 30


def test_constant_values_are_flat() -> None:
    result = ta.analyse(d([200] * 6), [True] * 6, "week")
    assert result.direction == "flat" and result.slope_per_bucket == Decimal("0.00")


def test_days_off_inside_the_span_count_as_zero_but_leading_days_do_not() -> None:
    # Ten empty days before the rider started must not create an upward trend.
    flags = [False] * 10 + [True, False] * 10
    values = [0] * 10 + [800, 0] * 10
    result = ta.analyse(d(values), flags, "day")
    assert result.status == "ok" and result.direction == "flat"


def test_false_up_or_down_rate_on_random_series_is_near_the_test_level() -> None:
    """Random series without a trend: 'up'/'down' should appear in about 5% of riders, not more."""
    rng = random.Random(2026)
    hits = 0
    runs = 400
    for _ in range(runs):
        values = [rng.gauss(600, 250) for _ in range(30)]
        if ta.analyse(d([round(v, 2) for v in values]), [True] * 30, "day").direction != "flat":
            hits += 1
    assert hits / runs < 0.09


def test_lengths_must_match() -> None:
    with pytest.raises(ValueError, match="same length"):
        ta.analyse(d([1, 2]), [True], "day")
