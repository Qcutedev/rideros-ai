"""K-Means work patterns (app/modules/profit/patterns.py) on synthetic sessions with known groups."""

import random
from datetime import datetime, timedelta
from decimal import Decimal
from zoneinfo import ZoneInfo

import numpy as np
import pytest

from app.modules.profit import patterns as pat
from app.modules.profit.patterns import SessionRow, find_patterns

BKK = ZoneInfo("Asia/Bangkok")
MONDAY = datetime(2026, 6, 1, tzinfo=BKK)  # a Monday


def row(
    day: int, hour: float, hours: float, revenue: str = "0", expenses: str = "0", incomes: int = 0
) -> SessionRow:
    start = MONDAY + timedelta(days=day, hours=hour)
    return SessionRow(start, start + timedelta(hours=hours), Decimal(revenue), Decimal(expenses), incomes)


def weekday(i: int) -> int:
    return (i // 5) * 7 + i % 5  # Mon..Fri of consecutive weeks


def weekend(i: int) -> int:
    return (i // 2) * 7 + 5 + i % 2  # Sat, Sun of consecutive weeks


def two_habits(seed: int = 0) -> list[SessionRow]:
    """24 weekday evenings (~18:30, ~3 h, paid) + 12 weekend days (~09:00, ~9 h, half paid)."""
    rng = random.Random(seed)
    evenings = [row(weekday(i), rng.gauss(18.5, 0.5), rng.gauss(3, 0.4), "450", "50", 1) for i in range(24)]
    days = [
        row(weekend(i), rng.gauss(9, 0.6), rng.gauss(9, 0.7), *(("1200", "100", 2) if i % 2 else ()))
        for i in range(12)
    ]
    return evenings + days


def test_below_the_minimum_is_insufficient() -> None:
    result = find_patterns(two_habits()[: pat.MIN_SESSIONS - 1], BKK)
    assert result.status == "insufficient_data"
    assert result.session_count == pat.MIN_SESSIONS - 1 and result.groups == ()


def test_start_hour_is_circular() -> None:
    x = pat.features([row(0, 23, 2), row(1, 1, 2), row(2, 12, 2)], BKK)
    late, early, noon = x[:, :2]
    assert np.linalg.norm(late - early) < np.linalg.norm(late - noon) / 3


def test_features_use_local_time_and_weekend() -> None:
    utc_start = datetime(2026, 6, 6, 3, 0, tzinfo=ZoneInfo("UTC"))  # Sat 10:00 in Bangkok
    x = pat.features(
        [SessionRow(utc_start, utc_start + timedelta(hours=2.5), Decimal(0), Decimal(0), 0)], BKK
    )
    angle = np.arctan2(x[0, 0], x[0, 1]) % (2 * np.pi)
    assert angle == pytest.approx(2 * np.pi * 10 / 24)
    assert x[0, 2] == pytest.approx(2.5) and x[0, 3] == 1.0


def test_scale_weights_and_constant_columns() -> None:
    raw = pat.features(two_habits(), BKK)
    x = pat.scale(raw)
    assert x[:, 2].std() == pytest.approx(1.0)
    assert x[:, 3].std() == pytest.approx(pat.WEEKEND_WEIGHT)
    assert x[:, 0].var() + x[:, 1].var() == pytest.approx(1.0)
    raw[:, 3] = 0.0
    assert not pat.scale(raw)[:, 3].any()


def test_finds_two_planted_habits() -> None:
    rows = two_habits()
    result = find_patterns(rows, BKK)
    assert result.status == "ok" and result.k == 2
    assert result.silhouette is not None and result.silhouette >= pat.MIN_SILHOUETTE
    assert result.null_silhouette is not None and result.silhouette > result.null_silhouette
    assert result.stability is not None and result.stability >= pat.MIN_STABILITY
    evening, day = result.groups  # largest first
    assert (evening.time_of_day, evening.length, evening.day_type) == ("evening", "short", "weekday")
    assert (day.time_of_day, day.length, day.day_type) == ("morning", "long", "weekend")
    assert (evening.session_count, day.session_count) == (24, 12)
    assert evening.share == pytest.approx(24 / 36, abs=1e-3)
    assert list(result.labels) == [0] * 24 + [1] * 12  # every session in its planted group


def test_profit_per_hour_uses_only_sessions_with_linked_income() -> None:
    result = find_patterns(two_habits(), BKK)
    evening, day = result.groups
    rows = two_habits()
    paid_days = [r for r in rows[24:] if r.income_count]
    hours = sum((r.ended_at - r.started_at).total_seconds() for r in paid_days) / 3600
    assert day.profit_session_count == 6
    assert float(day.revenue_per_hour) == pytest.approx(1200 * 6 / hours, abs=0.005)
    assert float(day.net_profit_per_hour) == pytest.approx(1100 * 6 / hours, abs=0.005)
    assert evening.profit_session_count == 24 and evening.net_profit_per_hour is not None


def test_group_without_income_has_no_per_hour_figures() -> None:
    rows = [SessionRow(r.started_at, r.ended_at, Decimal(0), Decimal(0), 0) for r in two_habits()]
    result = find_patterns(rows, BKK)
    assert result.status == "ok"
    assert all(g.profit_session_count == 0 and g.net_profit_per_hour is None for g in result.groups)


@pytest.mark.parametrize("seed", range(3))
def test_uniform_random_sessions_show_no_pattern(seed: int) -> None:
    rng = random.Random(seed)
    rows = [row(rng.randrange(180), rng.uniform(0, 24), rng.uniform(1, 12)) for _ in range(60)]
    assert find_patterns(rows, BKK).status == "no_clear_pattern"


def test_one_habit_shows_no_pattern() -> None:
    rng = random.Random(1)
    rows = [row(d, rng.gauss(18.5, 1.0), rng.gauss(3.5, 0.7)) for d in range(45)]
    assert find_patterns(rows, BKK).status == "no_clear_pattern"


def test_identical_sessions_do_not_crash() -> None:
    rows = [row(weekday(i), 18, 3) for i in range(40)]
    result = find_patterns(rows, BKK)
    assert result.status == "no_clear_pattern" and result.k is None


def test_result_is_deterministic() -> None:
    assert find_patterns(two_habits(3), BKK) == find_patterns(two_habits(3), BKK)


def test_mean_start_across_midnight() -> None:
    rows = [row(i, 23, 3) for i in range(5)] + [row(i, 25, 3) for i in range(5)]  # 23:00 and 01:00
    group = pat.describe(rows, pat.features(rows, BKK))
    assert group.mean_start_minute == 0 and group.time_of_day == "night"


@pytest.mark.parametrize(
    ("minute", "expected"),
    [
        (4 * 60 + 59, "night"),
        (5 * 60, "morning"),
        (11 * 60, "midday"),
        (15 * 60, "evening"),
        (20 * 60, "night"),
    ],
)
def test_time_of_day_bands(minute: int, expected: str) -> None:
    assert pat._time_of_day(minute) == expected


@pytest.mark.parametrize(
    ("hours", "expected"), [(3.9, "short"), (4.0, "medium"), (7.9, "medium"), (8.0, "long")]
)
def test_length_bands(hours: float, expected: str) -> None:
    assert pat._length(hours) == expected


@pytest.mark.parametrize(("share", "expected"), [(0.3, "weekday"), (0.5, "mixed"), (0.7, "weekend")])
def test_day_type_bands(share: float, expected: str) -> None:
    assert pat._day_type(share) == expected


def test_cached_result_is_reused_for_the_same_sessions() -> None:
    rows = tuple(two_habits(5))
    first = pat.find_patterns_cached(rows, BKK)
    assert pat.find_patterns_cached(tuple(two_habits(5)), BKK) is first
    assert pat.find_patterns_cached(rows[:-1], BKK) is not first
