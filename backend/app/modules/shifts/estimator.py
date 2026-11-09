"""Shift Simulator arithmetic. Pure functions; results are estimates, never actual TrueProfit data.

Methods:
- `assumption`: hours x orders/hour x income/order. Costs from km/order with fuel and depreciation
  (scenario value, else rider profile, else not included + a warning) plus fixed `other_costs`.
- `historical`: the rider's own revenue and expenses per working hour over the last 84 days
  (same weekday when there are enough such days). The range is the 20th-80th percentile of the
  daily net profit per hour, times the shift hours.
- `ml`: reserved; no trained shift-earnings model exists, so the service rejects it.
"""

import statistics
from dataclasses import dataclass, field
from datetime import date, time
from decimal import ROUND_HALF_UP, Decimal
from typing import Any

from app.core.errors import AppError
from app.modules.profit.calculator import Totals

MIN_DURATION_MINUTES = 30
MAX_DURATION_MINUTES = 960
HISTORY_DAYS = 84
MIN_HISTORY_DAYS = 5
_CENT = Decimal("0.01")
_US_PER_HOUR = Decimal(3_600_000_000)


class InvalidShiftLengthError(AppError):
    code = "invalid_shift_length"


class MissingAssumptionError(AppError):
    code = "missing_assumption"


class InsufficientHistoryError(AppError):
    code = "insufficient_history"


def _round(value: Decimal) -> Decimal:
    return value.quantize(_CENT, rounding=ROUND_HALF_UP)


def _s(value: Decimal | None) -> str | None:
    return None if value is None else str(_round(value))


def duration_minutes(start: time, end: time) -> int:
    """Minutes from start to end; an end earlier than the start means the next day."""
    minutes = ((end.hour * 60 + end.minute) - (start.hour * 60 + start.minute)) % 1440
    if not MIN_DURATION_MINUTES <= minutes <= MAX_DURATION_MINUTES:
        raise InvalidShiftLengthError(
            f"A shift must last {MIN_DURATION_MINUTES}-{MAX_DURATION_MINUTES} minutes (got {minutes})"
        )
    return minutes


@dataclass(slots=True)
class Estimate:
    revenue: Decimal
    expenses: Decimal
    net: Decimal
    low: Decimal | None = None
    high: Decimal | None = None
    details: dict[str, Any] = field(default_factory=dict)


def _pick(
    name: str, assumptions: dict[str, Any], profile: dict[str, Any]
) -> tuple[Decimal | None, str | None]:
    if assumptions.get(name) is not None:
        return Decimal(str(assumptions[name])), "scenario"
    if profile.get(name) is not None:
        return Decimal(str(profile[name])), "rider_profile"
    return None, None


def from_assumptions(minutes: int, assumptions: dict[str, Any], profile: dict[str, Any]) -> Estimate:
    missing = [k for k in ("orders_per_hour", "income_per_order") if assumptions.get(k) is None]
    if missing:
        raise MissingAssumptionError(
            "The assumption method needs " + " and ".join(missing),
            details=[
                {"loc": ["body", "assumptions", k], "msg": "required for method 'assumption'"}
                for k in missing
            ],
        )
    hours = Decimal(minutes) / 60
    orders = hours * Decimal(str(assumptions["orders_per_hour"]))
    revenue = orders * Decimal(str(assumptions["income_per_order"]))
    other = Decimal(str(assumptions.get("other_costs") or 0))
    warnings: list[str] = []
    sources: dict[str, str | None] = {}
    fuel = depreciation = Decimal(0)
    km: Decimal | None = None
    if assumptions.get("km_per_order") is not None:
        km = orders * Decimal(str(assumptions["km_per_order"]))
        km_per_liter, sources["fuel_km_per_liter"] = _pick("fuel_km_per_liter", assumptions, profile)
        price, sources["fuel_price_per_liter"] = _pick("fuel_price_per_liter", assumptions, profile)
        per_km, sources["depreciation_per_km"] = _pick("depreciation_per_km", assumptions, profile)
        if km_per_liter and price is not None:
            fuel = km / km_per_liter * price
        else:
            warnings.append("fuel_cost_not_included")
        if per_km is not None:
            depreciation = km * per_km
        else:
            warnings.append("depreciation_not_included")
    else:
        warnings.append("distance_costs_not_included")
    expenses = fuel + depreciation + other
    return Estimate(
        revenue=_round(revenue),
        expenses=_round(expenses),
        net=_round(revenue - expenses),
        details={
            "method": "assumption",
            "hours": _s(hours),
            "expected_orders": _s(orders),
            "expected_km": _s(km),
            "fuel_cost": _s(fuel),
            "depreciation_cost": _s(depreciation),
            "other_costs": _s(other),
            "sources": sources,
            "warnings": warnings,
        },
    )


def _hours(t: Totals) -> Decimal:
    return Decimal(t.session_microseconds) / _US_PER_HOUR + t.unlinked_hours


def from_history(
    minutes: int,
    days: dict[date, Totals],
    *,
    planned_weekday: int | None,
    other_costs: Decimal,
    window: tuple[date, date],
) -> Estimate:
    worked = {d: t for d, t in days.items() if _hours(t) > 0}
    basis, warnings = "all_days", []
    if planned_weekday is not None:
        same = {d: t for d, t in worked.items() if d.weekday() == planned_weekday}
        if len(same) >= MIN_HISTORY_DAYS:
            worked, basis = same, "same_weekday"
        else:
            warnings.append("few_days_for_weekday_used_all_days")
    if len(worked) < MIN_HISTORY_DAYS:
        raise InsufficientHistoryError(
            f"Need at least {MIN_HISTORY_DAYS} days with working hours in the last {HISTORY_DAYS} days "
            f"(found {len(worked)})",
            details=[{"n_days": len(worked), "required": MIN_HISTORY_DAYS}],
        )
    total_hours = sum((_hours(t) for t in worked.values()), Decimal(0))
    revenue_per_hour = sum((t.revenue for t in worked.values()), Decimal(0)) / total_hours
    expenses_per_hour = sum((t.expenses for t in worked.values()), Decimal(0)) / total_hours
    hours = Decimal(minutes) / 60
    revenue = revenue_per_hour * hours
    expenses = expenses_per_hour * hours + other_costs
    daily_net_per_hour = [float((t.revenue - t.expenses) / _hours(t)) for t in worked.values()]
    q20, _, _, q80 = statistics.quantiles(daily_net_per_hour, n=5, method="inclusive")
    low = Decimal(str(q20)) * hours - other_costs
    high = Decimal(str(q80)) * hours - other_costs
    return Estimate(
        revenue=_round(revenue),
        expenses=_round(expenses),
        net=_round(revenue - expenses),
        low=_round(min(low, high)),
        high=_round(max(low, high)),
        details={
            "method": "historical",
            "hours": _s(hours),
            "basis": basis,
            "window_start": window[0].isoformat(),
            "window_end": window[1].isoformat(),
            "n_days": len(worked),
            "historical_hours": _s(total_hours),
            "revenue_per_hour": _s(revenue_per_hour),
            "expenses_per_hour": _s(expenses_per_hour),
            "other_costs": _s(other_costs),
            "range": "P20-P80 of daily net profit per hour x shift hours",
            "note": "Uses whole-day averages; the time of day of the shift is not modelled.",
            "warnings": warnings,
        },
    )
