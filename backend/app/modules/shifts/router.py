"""Shift Simulator HTTP API (/shift-scenarios)."""

import uuid

from fastapi import APIRouter, Response, status

from app.core.deps import CurrentUser, SessionDep
from app.core.pagination import DEFAULT_PAGE_SIZE, CursorQuery, LimitQuery, Page
from app.modules.shifts import service
from app.modules.shifts.schemas import (
    CompareRequest,
    CompareResult,
    ShiftScenarioCreate,
    ShiftScenarioOut,
    ShiftScenarioUpdate,
)

router = APIRouter(prefix="/shift-scenarios", tags=["shift simulator"])
_NOT_FOUND = {404: {"description": "Not found, or owned by another user"}}


@router.get("", response_model=Page[ShiftScenarioOut])
async def list_scenarios(
    user: CurrentUser, session: SessionDep, limit: LimitQuery = DEFAULT_PAGE_SIZE, cursor: CursorQuery = None
) -> Page[ShiftScenarioOut]:
    return await service.list_scenarios(session, user.id, cursor=cursor, limit=limit)


@router.post("", status_code=status.HTTP_201_CREATED, response_model=ShiftScenarioOut)
async def create_scenario(
    body: ShiftScenarioCreate, user: CurrentUser, session: SessionDep
) -> ShiftScenarioOut:
    """Creates the scenario and computes its estimate immediately."""
    return await service.create(session, user.id, body)


@router.post("/compare", response_model=CompareResult, responses=_NOT_FOUND)
async def compare_scenarios(body: CompareRequest, user: CurrentUser, session: SessionDep) -> CompareResult:
    """2-5 of the rider's scenarios side by side, with the best by net profit and by net profit/hour."""
    return await service.compare(session, user.id, body)


@router.get("/{scenario_id}", response_model=ShiftScenarioOut, responses=_NOT_FOUND)
async def get_scenario(scenario_id: uuid.UUID, user: CurrentUser, session: SessionDep) -> ShiftScenarioOut:
    return await service.get(session, user.id, scenario_id)


@router.patch("/{scenario_id}", response_model=ShiftScenarioOut, responses=_NOT_FOUND)
async def update_scenario(
    scenario_id: uuid.UUID, body: ShiftScenarioUpdate, user: CurrentUser, session: SessionDep
) -> ShiftScenarioOut:
    """Re-estimates when times, weekday, method or assumptions change."""
    return await service.update(session, user.id, scenario_id, body)


@router.delete("/{scenario_id}", status_code=status.HTTP_204_NO_CONTENT, responses=_NOT_FOUND)
async def delete_scenario(scenario_id: uuid.UUID, user: CurrentUser, session: SessionDep) -> Response:
    await service.delete(session, user.id, scenario_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/{scenario_id}/estimate", response_model=ShiftScenarioOut, responses=_NOT_FOUND)
async def re_estimate(scenario_id: uuid.UUID, user: CurrentUser, session: SessionDep) -> ShiftScenarioOut:
    """Recompute with the latest rider profile and TrueProfit history."""
    return await service.re_estimate(session, user.id, scenario_id)
