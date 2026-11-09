"""TrueProfit arithmetic, periods, cursors and time-zone bounds (no database)."""

from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

import pytest

from app.core.pagination import InvalidCursorError, decode_cursor, encode_cursor
from app.core.timezones import get_zone, is_valid_timezone, local_dates_to_utc_range, today_in
from app.modules.profit import calculator as calc

# ---- periods ----


@pytest.mark.parametrize(
    ("day", "period", "expected"),
    [
        (date(2026, 11, 11), "day", (date(2026, 11, 11), date(2026, 11, 11))),
        (date(2026, 11, 11), "week", (date(2026, 11, 9), date(2026, 11, 15))),  # Monday-Sunday
        (date(2026, 11, 9), "week", (date(2026, 11, 9), date(2026, 11, 15))),
        (date(2026, 11, 15), "week", (date(2026, 11, 9), date(2026, 11, 15))),
        (date(2026, 11, 30), "month", (date(2026, 11, 1), date(2026, 11, 30))),
        (date(2026, 12, 31), "month", (date(2026, 12, 1), date(2026, 12, 31))),  # year rollover
        (date(2028, 2, 10), "month", (date(2028, 2, 1), date(2028, 2, 29))),  # leap year
        (date(2026, 12, 30), "week", (date(2026, 12, 28), date(2027, 1, 3))),  # week across years
    ],
)
def test_bucket_range(day: date, period: calc.Period, expected: tuple[date, date]) -> None:
    assert calc.bucket_range(day, period) == expected


def test_buckets_between_covers_whole_buckets() -> None:
    weeks = calc.buckets_between(date(2026, 11, 11), date(2026, 11, 17), "week")
    assert weeks == [(date(2026, 11, 9), date(2026, 11, 15)), (date(2026, 11, 16), date(2026, 11, 22))]
    months = calc.buckets_between(date(2026, 11, 20), date(2027, 1, 2), "month")
    assert [m[0] for m in months] == [date(2026, 11, 1), date(2026, 12, 1), date(2027, 1, 1)]
    assert len(calc.buckets_between(date(2026, 1, 1), date(2026, 12, 31), "day")) == 365


@pytest.mark.parametrize("period", ["day", "week", "month"])
def test_count_buckets_matches_buckets_between(period: calc.Period) -> None:
    first, last = date(2025, 12, 29), date(2027, 3, 4)
    assert calc.count_buckets(first, last, period) == len(calc.buckets_between(first, last, period))


# ---- metrics ----


def test_metrics_with_hours() -> None:
    t = calc.Totals(revenue=Decimal("800.00"), expenses=Decimal("100.00"), unlinked_hours=Decimal("1.5"))
    t.add_session(timedelta(hours=4, minutes=30))
    m = calc.compute_metrics(t)
    assert m.working_hours == Decimal("6.00")
    assert m.net_profit == Decimal("700.00")
    assert m.revenue_per_hour == Decimal("133.33")
    assert m.net_profit_per_hour == Decimal("116.67")  # 116.666… rounds half up
    assert m.reason is None and m.work_session_count == 1


def test_metrics_without_hours_are_null_not_zero_or_infinity() -> None:
    m = calc.compute_metrics(calc.Totals(revenue=Decimal("50"), expenses=Decimal("80")))
    assert m.revenue_per_hour is None and m.net_profit_per_hour is None
    assert m.reason == "no_working_hours"
    assert m.net_profit == Decimal("-30.00")  # a loss is reported as a negative number
    assert m.working_hours == Decimal("0.00")


def test_empty_metrics_are_zero() -> None:
    m = calc.compute_metrics(calc.Totals())
    assert (m.total_revenue, m.total_expenses, m.net_profit) == (Decimal("0.00"),) * 3


def test_totals_add() -> None:
    a = calc.Totals(revenue=Decimal(1), income_count=1)
    a.add(calc.Totals(revenue=Decimal(2), expenses=Decimal(3), expense_count=1, session_microseconds=10))
    assert (a.revenue, a.expenses, a.income_count, a.expense_count, a.session_microseconds) == (
        Decimal(3),
        Decimal(3),
        1,
        1,
        10,
    )


# ---- cursors ----


def test_cursor_round_trip() -> None:
    values = ["2026-11-09", "2026-11-09T10:00:00.123456+00:00", "6f1c0f0e-0000-4000-8000-000000000000"]
    assert decode_cursor(encode_cursor(values), 3) == values


@pytest.mark.parametrize(
    "cursor",
    ["not base64 !!", encode_cursor(["a"]), encode_cursor([1, 2]), "e30", "W10", "%%%%"],
    ids=["garbage", "wrong-size", "not-strings", "object", "empty-list", "symbols"],
)
def test_invalid_cursor(cursor: str) -> None:
    with pytest.raises(InvalidCursorError):
        decode_cursor(cursor, 2)


# ---- time zones ----


def test_timezone_validation() -> None:
    assert is_valid_timezone("Asia/Bangkok") and is_valid_timezone("UTC")
    assert not is_valid_timezone("Mars/Olympus") and not is_valid_timezone("../etc/passwd")


def test_local_day_bounds_bangkok() -> None:
    start, end = local_dates_to_utc_range(date(2026, 11, 9), date(2026, 11, 9), get_zone("Asia/Bangkok"))
    assert start == datetime(2026, 11, 8, 17, tzinfo=UTC) and end == datetime(2026, 11, 9, 17, tzinfo=UTC)


def test_local_day_bounds_respect_dst() -> None:
    # 2026-03-08 is the US spring-forward day: that local day is only 23 hours long.
    start, end = local_dates_to_utc_range(date(2026, 3, 8), date(2026, 3, 8), get_zone("America/New_York"))
    assert end - start == timedelta(hours=23)


def test_today_in_zone() -> None:
    now = datetime(2026, 11, 9, 18, 30, tzinfo=UTC)  # 01:30 on the 10th in Bangkok
    assert today_in(get_zone("Asia/Bangkok"), now) == date(2026, 11, 10)
    assert today_in(get_zone("UTC"), now) == date(2026, 11, 9)
