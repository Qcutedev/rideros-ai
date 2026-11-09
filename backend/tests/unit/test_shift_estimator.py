"""Shift Simulator arithmetic (no database)."""

from datetime import date, time, timedelta
from decimal import Decimal

import pytest

from app.modules.profit.calculator import Totals
from app.modules.shifts import estimator as est

WINDOW = (date(2026, 8, 31), date(2026, 11, 22))


@pytest.mark.parametrize(
    ("start", "end", "minutes"),
    [
        (time(17), time(21, 30), 270),
        (time(22), time(2), 240),
        (time(8), time(8, 30), 30),
        (time(6), time(22), 960),
    ],
)
def test_duration(start: time, end: time, minutes: int) -> None:
    assert est.duration_minutes(start, end) == minutes


@pytest.mark.parametrize(
    ("start", "end"), [(time(8), time(8)), (time(8), time(8, 29)), (time(6), time(22, 1))]
)
def test_duration_out_of_range(start: time, end: time) -> None:
    with pytest.raises(est.InvalidShiftLengthError):
        est.duration_minutes(start, end)


def test_assumption_estimate() -> None:
    a = {"orders_per_hour": "2.5", "income_per_order": "45", "km_per_order": "4", "other_costs": "20"}
    profile = {
        "fuel_km_per_liter": Decimal("40"),
        "fuel_price_per_liter": Decimal("38"),
        "depreciation_per_km": Decimal("0.5"),
    }
    e = est.from_assumptions(270, a, profile)
    # 4.5 h x 2.5 = 11.25 orders -> 506.25 revenue, 45 km -> fuel 42.75, depreciation 22.50, other 20
    assert (e.revenue, e.expenses, e.net) == (Decimal("506.25"), Decimal("85.25"), Decimal("421.00"))
    assert e.low is None and e.high is None
    assert e.details["sources"] == {
        "fuel_km_per_liter": "rider_profile",
        "fuel_price_per_liter": "rider_profile",
        "depreciation_per_km": "rider_profile",
    }
    assert e.details["warnings"] == []


def test_scenario_values_win_over_profile_and_missing_costs_are_flagged() -> None:
    a = {"orders_per_hour": 2, "income_per_order": 50, "km_per_order": 5, "fuel_km_per_liter": 50}
    e = est.from_assumptions(60, a, {"fuel_km_per_liter": Decimal("10")})
    assert e.details["sources"]["fuel_km_per_liter"] == "scenario"
    assert e.details["warnings"] == ["fuel_cost_not_included", "depreciation_not_included"]
    assert e.expenses == Decimal("0.00") and e.revenue == Decimal("100.00")

    no_km = est.from_assumptions(60, {"orders_per_hour": 1, "income_per_order": 1}, {})
    assert (
        no_km.details["warnings"] == ["distance_costs_not_included"] and no_km.details["expected_km"] is None
    )


def test_missing_required_assumptions() -> None:
    with pytest.raises(est.MissingAssumptionError) as err:
        est.from_assumptions(60, {"orders_per_hour": 2}, {})
    assert "income_per_order" in err.value.message and err.value.details[0]["loc"][-1] == "income_per_order"


def _day(revenue: str, expenses: str, hours: float) -> Totals:
    t = Totals(revenue=Decimal(revenue), expenses=Decimal(expenses))
    t.add_session(timedelta(hours=hours))
    return t


def test_history_estimate_and_range() -> None:
    mondays = [date(2026, 11, 2) - timedelta(weeks=i) for i in range(5)]
    days = {d: _day(str(100 * (i + 1)), "10", 2) for i, d in enumerate(mondays)}  # net/h: 45, 95, ..., 245
    days[date(2026, 11, 3)] = _day("0", "0", 0)  # no hours: ignored
    e = est.from_history(240, days, planned_weekday=0, other_costs=Decimal("15"), window=WINDOW)
    # pooled: revenue 1500 / 10 h = 150/h, expenses 50 / 10 h = 5/h -> 4 h: 600 revenue, 20 + 15 expenses
    assert (e.revenue, e.expenses, e.net) == (Decimal("600.00"), Decimal("35.00"), Decimal("565.00"))
    assert e.details["basis"] == "same_weekday" and e.details["n_days"] == 5
    # P20 / P80 of [45, 95, 145, 195, 245] (inclusive) = 85 / 205 -> x 4 h - 15
    assert (e.low, e.high) == (Decimal("325.00"), Decimal("805.00"))
    assert e.low <= e.net <= e.high


def test_history_falls_back_to_all_days_for_a_sparse_weekday() -> None:
    days = {date(2026, 11, 2) + timedelta(days=i): _day("100", "0", 1) for i in range(6)}  # Mon..Sat
    e = est.from_history(60, days, planned_weekday=6, other_costs=Decimal(0), window=WINDOW)
    assert e.details["basis"] == "all_days" and e.details["warnings"] == [
        "few_days_for_weekday_used_all_days"
    ]
    assert e.low == e.high == e.net == Decimal("100.00")


def test_history_needs_five_worked_days() -> None:
    days = {date(2026, 11, 2) + timedelta(days=i): _day("100", "0", 1) for i in range(4)}
    with pytest.raises(est.InsufficientHistoryError) as err:
        est.from_history(60, days, planned_weekday=None, other_costs=Decimal(0), window=WINDOW)
    assert err.value.details == [{"n_days": 4, "required": 5}]
