"""Net profit per hour by weekday × 2-hour slot (`GET /profit/heatmap`). Pure: no I/O.

Income and expense records carry a date only, so the time of day comes from work sessions:
  1. A session's money is its linked income and expenses plus a share of the records of its local
     start day (docs/DATABASE_DESIGN.md §3.7) that are linked to no session. A day's unlinked money
     is split over that day's counted sessions in proportion to their length. Unlinked income with
     its own `working_hours` stands for untimed work of its own, so it is never placed.
  2. Only sessions with income (linked, or a share of the day's unlinked income) are counted. A
     session without any income is most often one whose income was never recorded; counting its
     hours would pull every cell it touches down. Its linked expenses are left out with it.
  3. A counted session spreads its money evenly over its length: nothing records when inside the
     session an order paid. A cell gets the money of the minutes that fall in it, so a session past
     midnight puts its later minutes on the next weekday (the map answers "which hours pay").
  4. A cell shows per-hour figures only with >= MIN_CELL_SESSIONS sessions and >= MIN_CELL_HOURS
     hours in it; the map needs >= MIN_SESSIONS counted sessions in the window.
"""

from collections import defaultdict
from dataclasses import dataclass, field
from datetime import UTC, date, datetime, timedelta
from decimal import ROUND_HALF_UP, Decimal
from typing import Literal
from zoneinfo import ZoneInfo

from app.modules.profit.patterns import SessionRow

WINDOW_DAYS = 90
SLOT_HOURS = 2
SLOTS_PER_DAY = 24 // SLOT_HOURS
MIN_SESSIONS = 10
MIN_CELL_SESSIONS = 2
MIN_CELL_HOURS = 1

type Status = Literal["ok", "insufficient_data"]

_CENT = Decimal("0.01")
_TENTH = Decimal("0.1")
_US_PER_HOUR = 3_600_000_000


@dataclass(frozen=True, slots=True)
class UnlinkedDay:
    """Records of one local date that are linked to no work session."""

    revenue: Decimal = Decimal(0)  # income without working_hours
    income_count: int = 0
    hours_income_count: int = 0  # income with its own working_hours: never placed
    expenses: Decimal = Decimal(0)
    expense_count: int = 0


@dataclass(frozen=True, slots=True)
class Cell:
    weekday: int  # 0 = Monday, local
    slot: int  # local start hour = slot * SLOT_HOURS
    hours: Decimal
    session_count: int
    revenue_per_hour: Decimal | None  # None below the cell minimum
    net_profit_per_hour: Decimal | None


@dataclass(frozen=True, slots=True)
class Result:
    status: Status
    session_count: int  # counted sessions
    excluded_session_count: int
    excluded_income_count: int
    excluded_expense_count: int
    hours: Decimal
    revenue_per_hour: Decimal | None
    net_profit_per_hour: Decimal | None
    cells: tuple[Cell, ...] = ()  # cells with any counted minute, by weekday then slot; ok only


@dataclass(slots=True)
class _Acc:
    revenue: Decimal = Decimal(0)
    net: Decimal = Decimal(0)
    microseconds: int = 0
    sessions: set[int] = field(default_factory=set)


def _us(delta: timedelta) -> int:
    return delta // timedelta(microseconds=1)


def _per_hour(amount: Decimal, microseconds: int) -> Decimal:
    return (amount * _US_PER_HOUR / microseconds).quantize(_CENT, ROUND_HALF_UP)


def _hours(microseconds: int) -> Decimal:
    return (Decimal(microseconds) / _US_PER_HOUR).quantize(_TENTH, ROUND_HALF_UP)


def segments(started_at: datetime, ended_at: datetime, zone: ZoneInfo) -> list[tuple[int, int, int]]:
    """(local weekday, slot, microseconds) pieces of [started_at, ended_at), cut at local slot edges."""
    out: list[tuple[int, int, int]] = []
    cur = started_at
    while cur < ended_at:
        local = cur.astimezone(zone)
        wall = local.replace(tzinfo=None)
        slot_start = wall.replace(hour=wall.hour - wall.hour % SLOT_HOURS, minute=0, second=0, microsecond=0)
        edge_wall = slot_start + timedelta(hours=SLOT_HOURS)
        # When the wall clock goes back (end of daylight saving time) the edge's wall time can
        # occur twice: take the first occurrence that is still ahead.
        edges = (edge_wall.replace(tzinfo=zone, fold=fold).astimezone(UTC) for fold in (0, 1))
        edge = min((e for e in edges if e > cur), default=cur + timedelta(hours=SLOT_HOURS))
        nxt = min(edge, ended_at)
        out.append((local.weekday(), local.hour // SLOT_HOURS, _us(nxt - cur)))
        cur = nxt
    return out


def build(sessions: list[SessionRow], unlinked: dict[date, UnlinkedDay], zone: ZoneInfo) -> Result:
    by_day: dict[date, list[int]] = defaultdict(list)
    for i, s in enumerate(sessions):
        by_day[s.started_at.astimezone(zone).date()].append(i)
    revenue = [s.revenue for s in sessions]
    expenses = [s.expenses for s in sessions]
    counted = [s.income_count > 0 for s in sessions]
    for day, u in unlinked.items():
        if u.income_count:
            for i in by_day.get(day, ()):
                counted[i] = True

    excluded_income = excluded_expense = 0
    for day, u in unlinked.items():
        excluded_income += u.hours_income_count
        targets = [i for i in by_day.get(day, ()) if counted[i]]
        lengths = [_us(sessions[i].ended_at - sessions[i].started_at) for i in targets]
        total = sum(lengths)
        if total <= 0:
            excluded_income += u.income_count
            excluded_expense += u.expense_count
            continue
        for i, length in zip(targets, lengths, strict=True):
            share = Decimal(length) / total
            revenue[i] += u.revenue * share
            expenses[i] += u.expenses * share

    cells: dict[tuple[int, int], _Acc] = {}
    all_revenue = all_net = Decimal(0)
    all_us = 0
    for i, s in enumerate(sessions):
        length = _us(s.ended_at - s.started_at)
        if not counted[i] or length <= 0:
            continue
        net = revenue[i] - expenses[i]
        all_revenue += revenue[i]
        all_net += net
        all_us += length
        for weekday, slot, us in segments(s.started_at, s.ended_at, zone):
            acc = cells.setdefault((weekday, slot), _Acc())
            fraction = Decimal(us) / length
            acc.revenue += revenue[i] * fraction
            acc.net += net * fraction
            acc.microseconds += us
            acc.sessions.add(i)

    n = sum(counted)
    common = {
        "session_count": n,
        "excluded_session_count": len(sessions) - n,
        "excluded_income_count": excluded_income,
        "excluded_expense_count": excluded_expense,
        "hours": _hours(all_us),
        "revenue_per_hour": _per_hour(all_revenue, all_us) if all_us else None,
        "net_profit_per_hour": _per_hour(all_net, all_us) if all_us else None,
    }
    if n < MIN_SESSIONS:
        return Result(status="insufficient_data", **common)
    out = []
    for (weekday, slot), acc in sorted(cells.items()):
        enough = len(acc.sessions) >= MIN_CELL_SESSIONS and acc.microseconds >= MIN_CELL_HOURS * _US_PER_HOUR
        out.append(
            Cell(
                weekday=weekday,
                slot=slot,
                hours=_hours(acc.microseconds),
                session_count=len(acc.sessions),
                revenue_per_hour=_per_hour(acc.revenue, acc.microseconds) if enough else None,
                net_profit_per_hour=_per_hour(acc.net, acc.microseconds) if enough else None,
            )
        )
    return Result(status="ok", cells=tuple(out), **common)
