"""Shift Simulator use cases (create = estimate immediately, re-estimate, compare)."""

import uuid
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Any

from sqlalchemy import select, tuple_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.core.pagination import InvalidCursorError, Page, decode_cursor, encode_cursor
from app.core.timezones import today_in
from app.modules.profit import repository as profit_repo
from app.modules.profit.service import InvalidWorkSessionError, daily_totals
from app.modules.shifts import estimator
from app.modules.shifts.models import ShiftScenario
from app.modules.shifts.schemas import (
    CompareRequest,
    CompareResult,
    ShiftScenarioCreate,
    ShiftScenarioOut,
    ShiftScenarioUpdate,
)
from app.modules.users.service import get_locale, get_rider_profile

_ESTIMATE_INPUTS = {"start_time", "end_time", "planned_weekday", "estimation_method", "assumptions"}


def _not_found() -> NotFoundError:
    return NotFoundError("Shift scenario not found", code="shift_scenario_not_found")


def to_out(row: ShiftScenario) -> ShiftScenarioOut:
    return ShiftScenarioOut.model_validate(row)


async def _estimate(session: AsyncSession, user_id: uuid.UUID, values: dict[str, Any]) -> dict[str, Any]:
    """Compute duration + estimate for the scenario inputs in `values`; returns the columns to store."""
    method = values["estimation_method"]
    minutes = estimator.duration_minutes(values["start_time"], values["end_time"])
    assumptions: dict[str, Any] = values["assumptions"]
    if method == "assumption":
        profile = (await get_rider_profile(session, user_id)).model_dump()
        result = estimator.from_assumptions(minutes, assumptions, profile)
    else:
        locale = await get_locale(session, user_id)
        last = today_in(locale.zone)
        first = last - timedelta(days=estimator.HISTORY_DAYS - 1)
        days = await daily_totals(session, user_id, first, last, locale)
        result = estimator.from_history(
            minutes,
            days,
            planned_weekday=values.get("planned_weekday"),
            other_costs=Decimal(str(assumptions.get("other_costs") or 0)),
            window=(first, last),
        )
        result.details["timezone"] = locale.timezone
    return {
        "duration_minutes": minutes,
        "estimated_revenue": result.revenue,
        "estimated_expenses": result.expenses,
        "estimated_net_profit": result.net,
        "estimate_low": result.low,
        "estimate_high": result.high,
        "estimate_details": result.details,
    }


async def _check_session_link(
    session: AsyncSession, user_id: uuid.UUID, session_id: uuid.UUID | None
) -> None:
    if session_id is not None and not await profit_repo.owns_work_session(session, user_id, session_id):
        raise InvalidWorkSessionError(
            details=[{"loc": ["body", "actual_work_session_id"], "msg": "not found"}]
        )


def _assumptions_json(model: Any) -> dict[str, Any]:
    return model.model_dump(mode="json", exclude_none=True)


async def create(session: AsyncSession, user_id: uuid.UUID, body: ShiftScenarioCreate) -> ShiftScenarioOut:
    await _check_session_link(session, user_id, body.actual_work_session_id)
    values = body.model_dump(exclude={"assumptions"}) | {"assumptions": _assumptions_json(body.assumptions)}
    row = ShiftScenario(user_id=user_id, **values, **(await _estimate(session, user_id, values)))
    session.add(row)
    await session.commit()
    await session.refresh(row)
    return to_out(row)


async def _get(session: AsyncSession, user_id: uuid.UUID, scenario_id: uuid.UUID) -> ShiftScenario:
    stmt = select(ShiftScenario).where(ShiftScenario.id == scenario_id, ShiftScenario.user_id == user_id)
    row = (await session.execute(stmt)).scalar_one_or_none()
    if row is None:
        raise _not_found()
    return row


async def get(session: AsyncSession, user_id: uuid.UUID, scenario_id: uuid.UUID) -> ShiftScenarioOut:
    return to_out(await _get(session, user_id, scenario_id))


def _inputs(row: ShiftScenario) -> dict[str, Any]:
    return {k: getattr(row, k) for k in _ESTIMATE_INPUTS}


async def update(
    session: AsyncSession, user_id: uuid.UUID, scenario_id: uuid.UUID, body: ShiftScenarioUpdate
) -> ShiftScenarioOut:
    row = await _get(session, user_id, scenario_id)
    changes = body.changes()
    if "assumptions" in changes:
        changes["assumptions"] = _assumptions_json(body.assumptions)
    if "actual_work_session_id" in changes:
        await _check_session_link(session, user_id, changes["actual_work_session_id"])
    if _ESTIMATE_INPUTS & changes.keys():
        changes |= await _estimate(session, user_id, _inputs(row) | changes)
    for key, value in changes.items():
        setattr(row, key, value)
    await session.commit()
    await session.refresh(row)
    return to_out(row)


async def re_estimate(session: AsyncSession, user_id: uuid.UUID, scenario_id: uuid.UUID) -> ShiftScenarioOut:
    """Same inputs, latest rider profile and history."""
    row = await _get(session, user_id, scenario_id)
    for key, value in (await _estimate(session, user_id, _inputs(row))).items():
        setattr(row, key, value)
    await session.commit()
    await session.refresh(row)
    return to_out(row)


async def delete(session: AsyncSession, user_id: uuid.UUID, scenario_id: uuid.UUID) -> None:
    row = await _get(session, user_id, scenario_id)
    await session.delete(row)
    await session.commit()


async def list_scenarios(
    session: AsyncSession, user_id: uuid.UUID, *, cursor: str | None, limit: int
) -> Page[ShiftScenarioOut]:
    stmt = select(ShiftScenario).where(ShiftScenario.user_id == user_id)
    if cursor is not None:
        stamp, row_id = decode_cursor(cursor, 2)
        try:
            after = (datetime.fromisoformat(stamp), uuid.UUID(row_id))
        except ValueError as exc:
            raise InvalidCursorError() from exc
        stmt = stmt.where(tuple_(ShiftScenario.created_at, ShiftScenario.id) < tuple_(*after))
    stmt = stmt.order_by(ShiftScenario.created_at.desc(), ShiftScenario.id.desc()).limit(limit + 1)
    rows = list((await session.execute(stmt)).scalars())
    next_cursor = None
    if len(rows) > limit:
        rows = rows[:limit]
        next_cursor = encode_cursor([rows[-1].created_at.isoformat(), str(rows[-1].id)])
    return Page[ShiftScenarioOut](items=[to_out(r) for r in rows], next_cursor=next_cursor)


async def compare(session: AsyncSession, user_id: uuid.UUID, body: CompareRequest) -> CompareResult:
    stmt = select(ShiftScenario).where(ShiftScenario.user_id == user_id, ShiftScenario.id.in_(body.ids))
    found = {row.id: row for row in (await session.execute(stmt)).scalars()}
    if len(found) != len(body.ids):  # any id missing or owned by someone else
        raise _not_found()
    scenarios = [to_out(found[i]) for i in body.ids]
    return CompareResult(
        scenarios=scenarios,
        best_net_profit_id=max(scenarios, key=lambda s: s.estimated_net_profit).id,
        best_net_profit_per_hour_id=max(scenarios, key=lambda s: s.estimated_net_profit_per_hour).id,
    )
