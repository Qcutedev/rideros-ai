"""Profit heat map (app/modules/profit/heatmap.py): slot cutting, money placement, minimums."""

from datetime import UTC, date, datetime, timedelta
from decimal import Decimal
from zoneinfo import ZoneInfo

from app.modules.profit import heatmap as hm
from app.modules.profit.heatmap import UnlinkedDay, build, segments
from app.modules.profit.patterns import SessionRow

BKK = ZoneInfo("Asia/Bangkok")
BERLIN = ZoneInfo("Europe/Berlin")
MONDAY = datetime(2026, 6, 1, tzinfo=BKK)  # a Monday
H = 3_600_000_000  # microseconds per hour


def row(
    day: int, hour: float, hours: float, revenue: str = "0", expenses: str = "0", incomes: int = 0
) -> SessionRow:
    start = MONDAY + timedelta(days=day, hours=hour)
    return SessionRow(start, start + timedelta(hours=hours), Decimal(revenue), Decimal(expenses), incomes)


def mondays(n: int, hour: float = 18, hours: float = 2, revenue: str = "400", expenses: str = "40") -> list:
    """n paid sessions on consecutive Mondays (weekday 0)."""
    return [row(7 * i, hour, hours, revenue, expenses, 1) for i in range(n)]


def cell(result: hm.Result, weekday: int, slot: int) -> hm.Cell:
    return next(c for c in result.cells if (c.weekday, c.slot) == (weekday, slot))


# ---- segments ----


def test_segments_cut_at_two_hour_edges() -> None:
    s = row(0, 17.5, 3.5)  # Mon 17:30-21:00
    assert segments(s.started_at, s.ended_at, BKK) == [(0, 8, H // 2), (0, 9, 2 * H), (0, 10, H)]


def test_segments_past_midnight_go_to_the_next_weekday() -> None:
    s = row(6, 23, 2.5)  # Sun 23:00 - Mon 01:30
    assert segments(s.started_at, s.ended_at, BKK) == [(6, 11, H), (0, 0, H + H // 2)]


def test_segments_use_local_time() -> None:
    start = datetime(2026, 6, 6, 3, 0, tzinfo=UTC)  # Sat 10:00 in Bangkok
    assert segments(start, start + timedelta(hours=1), BKK) == [(5, 5, H)]


def test_segments_follow_real_time_across_daylight_saving() -> None:
    spring = datetime(2026, 3, 29, 1, 0, tzinfo=BERLIN)  # clocks jump 02:00 -> 03:00
    autumn = datetime(2026, 10, 25, 1, 0, tzinfo=BERLIN)  # clocks fall 03:00 -> 02:00
    for start, real_hours in ((spring, 2), (autumn, 4)):
        end = (start.astimezone(UTC) + timedelta(hours=real_hours)).astimezone(BERLIN)
        parts = segments(start, end, BERLIN)
        assert sum(us for _, _, us in parts) == real_hours * H
        assert all(us > 0 for _, _, us in parts)


def test_segments_on_the_second_pass_of_a_repeated_slot_edge() -> None:
    # Antarctica/Troll falls back two hours (03:00 +02 -> 01:00 +00, 25 Oct 2026), so 01:00-03:00
    # happens twice; 01:30 on the second pass must end its slot at the second 02:00.
    start = datetime(2026, 10, 25, 1, 30, tzinfo=UTC)
    parts = segments(start, start + timedelta(hours=1), ZoneInfo("Antarctica/Troll"))
    assert parts == [(6, 0, H // 2), (6, 1, H // 2)]


# ---- build ----


def test_linked_money_per_cell() -> None:
    result = build(mondays(10), {}, BKK)
    assert result.status == "ok" and result.session_count == 10
    (only,) = result.cells
    assert (only.weekday, only.slot, only.hours, only.session_count) == (0, 9, Decimal("20.0"), 10)
    assert only.revenue_per_hour == Decimal("200.00")
    assert only.net_profit_per_hour == Decimal("180.00")
    assert result.net_profit_per_hour == Decimal("180.00") and result.hours == Decimal("20.0")


def test_money_is_spread_evenly_over_the_session() -> None:
    sessions = mondays(10, hour=17, hours=3, revenue="300", expenses="0")  # 1 h in slot 8, 2 h in slot 9
    result = build(sessions, {}, BKK)
    early, late = cell(result, 0, 8), cell(result, 0, 9)
    assert (early.hours, late.hours) == (Decimal("10.0"), Decimal("20.0"))
    assert early.net_profit_per_hour == late.net_profit_per_hour == Decimal("100.00")


def test_below_the_minimum_is_insufficient() -> None:
    result = build(mondays(hm.MIN_SESSIONS - 1), {}, BKK)
    assert result.status == "insufficient_data"
    assert result.session_count == hm.MIN_SESSIONS - 1 and result.cells == ()
    assert result.net_profit_per_hour == Decimal("180.00")  # still reported for the progress card


def test_unlinked_money_is_split_by_session_length() -> None:
    sessions: list[SessionRow] = []
    unlinked: dict[date, UnlinkedDay] = {}
    for week in range(2):  # two Mondays, each 08:00-09:00 (slot 4) + 14:00-17:00 (slots 7-8), unlinked
        sessions += [row(7 * week, 8, 1), row(7 * week, 14, 3)]
        unlinked[(MONDAY + timedelta(days=7 * week)).date()] = UnlinkedDay(
            revenue=Decimal(400), income_count=2, expenses=Decimal(40), expense_count=1
        )
    sessions += [row(7 * week, 20, 2, "400", "40", 1) for week in range(2, 8)]
    result = build(sessions, unlinked, BKK)
    assert result.session_count == 10 and result.excluded_income_count == 0
    # By length, not per session: short gets 1/4 (90 net over 1 h), long 3/4 (270 over 3 h).
    assert cell(result, 0, 4).net_profit_per_hour == Decimal("90.00")
    assert cell(result, 0, 7).net_profit_per_hour == Decimal("90.00")
    assert (cell(result, 0, 7).hours, cell(result, 0, 8).hours) == (Decimal("4.0"), Decimal("2.0"))
    assert result.net_profit_per_hour == Decimal("144.00")  # (2 + 6) × 360 net over (2 × 4 + 6 × 2) h


def test_unplaceable_records_are_counted_as_excluded() -> None:
    sessions = [*mondays(10), row(1, 9, 2)]  # Tuesday session without any income
    unlinked = {
        date(2026, 6, 2): UnlinkedDay(expenses=Decimal(50), expense_count=1),  # Tue: no counted session
        date(2026, 6, 3): UnlinkedDay(revenue=Decimal(500), income_count=2),  # Wed: no session at all
        MONDAY.date(): UnlinkedDay(hours_income_count=1),  # own working_hours: never placed
    }
    result = build(sessions, unlinked, BKK)
    assert result.session_count == 10 and result.excluded_session_count == 1
    assert (result.excluded_income_count, result.excluded_expense_count) == (3, 1)
    assert result.net_profit_per_hour == Decimal("180.00")  # nothing above changed the counted money


def test_same_day_unlinked_income_counts_a_session_without_linked_income() -> None:
    day = MONDAY.date() + timedelta(days=1)
    sessions = [*mondays(9), row(1, 18, 2)]
    unlinked = {day: UnlinkedDay(revenue=Decimal(300), income_count=1)}
    result = build(sessions, unlinked, BKK)
    assert result.status == "ok" and result.session_count == 10
    assert cell(result, 1, 9).hours == Decimal("2.0")


def test_cell_needs_two_sessions_and_one_hour() -> None:
    sessions = [*mondays(10), row(2, 6, 0.25, "100", "0", 1), row(9, 6, 0.25, "100", "0", 1)]
    result = build(sessions, {}, BKK)
    thin = cell(result, 2, 3)  # 2 sessions but 0.5 h
    assert thin.session_count == 2 and thin.net_profit_per_hour is None and thin.revenue_per_hour is None
    assert cell(result, 0, 9).net_profit_per_hour is not None


def test_negative_profit_is_kept() -> None:
    result = build(mondays(10, revenue="50", expenses="150"), {}, BKK)
    assert result.cells[0].net_profit_per_hour == Decimal("-50.00")


def test_no_sessions() -> None:
    result = build([], {MONDAY.date(): UnlinkedDay(revenue=Decimal(1), income_count=1)}, BKK)
    assert result.status == "insufficient_data" and result.session_count == 0
    assert result.hours == Decimal("0.0") and result.net_profit_per_hour is None
    assert result.excluded_income_count == 1
