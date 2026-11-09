"""TrueProfit arithmetic (docs/DATABASE_DESIGN.md §3.7). Pure functions: no I/O, no AI.

Periods are calendar based in the rider's time zone: a day, an ISO week (Monday–Sunday) or a
calendar month. A work session counts towards the local date on which it *started*, also when
it runs past midnight.
"""

from dataclasses import dataclass
from datetime import date, timedelta
from decimal import ROUND_HALF_UP, Decimal
from typing import Literal

type Period = Literal["day", "week", "month"]

MAX_TREND_POINTS = 366
_CENT = Decimal("0.01")
_MICROSECONDS_PER_HOUR = Decimal(3_600_000_000)


def bucket_start(day: date, period: Period) -> date:
    if period == "day":
        return day
    if period == "week":
        return day - timedelta(days=day.weekday())
    return day.replace(day=1)


def next_bucket_start(start: date, period: Period) -> date:
    if period == "day":
        return start + timedelta(days=1)
    if period == "week":
        return start + timedelta(days=7)
    return date(start.year + 1, 1, 1) if start.month == 12 else date(start.year, start.month + 1, 1)


def bucket_range(day: date, period: Period) -> tuple[date, date]:
    """First and last (inclusive) date of the bucket that contains `day`."""
    start = bucket_start(day, period)
    return start, next_bucket_start(start, period) - timedelta(days=1)


def buckets_between(first: date, last: date, period: Period) -> list[tuple[date, date]]:
    """Every bucket from the one containing `first` to the one containing `last` (inclusive)."""
    out: list[tuple[date, date]] = []
    start = bucket_start(first, period)
    while start <= last:
        nxt = next_bucket_start(start, period)
        out.append((start, nxt - timedelta(days=1)))
        start = nxt
    return out


def count_buckets(first: date, last: date, period: Period) -> int:
    a, b = bucket_start(first, period), bucket_start(last, period)
    if period == "day":
        return (b - a).days + 1
    if period == "week":
        return (b - a).days // 7 + 1
    return (b.year - a.year) * 12 + (b.month - a.month) + 1


@dataclass(slots=True)
class Totals:
    revenue: Decimal = Decimal(0)
    expenses: Decimal = Decimal(0)
    session_microseconds: int = 0
    unlinked_hours: Decimal = Decimal(0)  # income.working_hours where work_session_id IS NULL
    income_count: int = 0
    expense_count: int = 0
    work_session_count: int = 0

    def add(self, other: Totals) -> None:
        self.revenue += other.revenue
        self.expenses += other.expenses
        self.session_microseconds += other.session_microseconds
        self.unlinked_hours += other.unlinked_hours
        self.income_count += other.income_count
        self.expense_count += other.expense_count
        self.work_session_count += other.work_session_count

    def add_session(self, duration: timedelta) -> None:
        self.session_microseconds += duration // timedelta(microseconds=1)
        self.work_session_count += 1


@dataclass(slots=True)
class Metrics:
    total_revenue: Decimal
    total_expenses: Decimal
    net_profit: Decimal
    working_hours: Decimal
    revenue_per_hour: Decimal | None
    net_profit_per_hour: Decimal | None
    reason: Literal["no_working_hours"] | None
    income_count: int
    expense_count: int
    work_session_count: int


def _round(value: Decimal) -> Decimal:
    return value.quantize(_CENT, rounding=ROUND_HALF_UP)


def compute_metrics(t: Totals) -> Metrics:
    hours = Decimal(t.session_microseconds) / _MICROSECONDS_PER_HOUR + t.unlinked_hours
    net = t.revenue - t.expenses
    if hours > 0:
        per_hour, net_per_hour, reason = _round(t.revenue / hours), _round(net / hours), None
    else:
        # Never 0 or Infinity: the client shows "no working hours recorded" instead.
        per_hour, net_per_hour, reason = None, None, "no_working_hours"
    return Metrics(
        total_revenue=_round(t.revenue),
        total_expenses=_round(t.expenses),
        net_profit=_round(net),
        working_hours=_round(hours),
        revenue_per_hour=per_hour,
        net_profit_per_hour=net_per_hour,
        reason=reason,
        income_count=t.income_count,
        expense_count=t.expense_count,
        work_session_count=t.work_session_count,
    )
