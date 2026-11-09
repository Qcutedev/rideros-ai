"""Pickup Intelligence HTTP API (/pickup/...)."""

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request, Response, status

from app.core.deps import CurrentUser, SessionDep
from app.core.pagination import DEFAULT_PAGE_SIZE, CursorQuery, LimitQuery, Page
from app.ml.registry import LoadedModel
from app.modules.pickup import service
from app.modules.pickup.schemas import (
    ModelInfo,
    PickupLogCreate,
    PickupLogOut,
    PredictionCreate,
    PredictionOut,
    RestaurantAnalytics,
    RestaurantCreate,
    RestaurantOut,
    SourceFilter,
    WaitStats,
)

router = APIRouter(prefix="/pickup", tags=["pickup"])

_NOT_FOUND = {404: {"description": "Not found, or another rider's private restaurant / log"}}
ModelDep = Annotated[tuple[LoadedModel, uuid.UUID], Depends(service.get_model)]


@router.get("/restaurants", response_model=Page[RestaurantOut])
async def list_restaurants(
    user: CurrentUser,
    session: SessionDep,
    q: Annotated[
        str | None, Query(min_length=1, max_length=120, description="Name contains (case-insensitive)")
    ] = None,
    source: SourceFilter | None = None,
    limit: LimitQuery = DEFAULT_PAGE_SIZE,
    cursor: CursorQuery = None,
) -> Page[RestaurantOut]:
    """Dataset restaurants (shared) and the rider's own restaurants (listed first)."""
    return await service.list_restaurants(session, user.id, q=q, source=source, cursor=cursor, limit=limit)


@router.post("/restaurants", status_code=status.HTTP_201_CREATED, response_model=RestaurantOut)
async def create_restaurant(body: RestaurantCreate, user: CurrentUser, session: SessionDep) -> RestaurantOut:
    """A private restaurant for the Pickup Log (the model cannot predict for it)."""
    return await service.create_restaurant(session, user.id, body)


@router.get(
    "/restaurants/{restaurant_id}/analytics", response_model=RestaurantAnalytics, responses=_NOT_FOUND
)
async def restaurant_analytics(
    restaurant_id: uuid.UUID, user: CurrentUser, session: SessionDep
) -> RestaurantAnalytics:
    return await service.analytics(session, user.id, restaurant_id)


@router.get("/restaurants/{restaurant_id}/wait-stats", response_model=WaitStats, responses=_NOT_FOUND)
async def restaurant_wait_stats(
    restaurant_id: uuid.UUID, user: CurrentUser, session: SessionDep
) -> WaitStats:
    """Median / P80 of the rider's own logged waits; null until at least 5 logs exist."""
    return await service.wait_stats(session, user.id, restaurant_id)


@router.post(
    "/predictions",
    status_code=status.HTTP_201_CREATED,
    response_model=PredictionOut,
    responses={**_NOT_FOUND, 503: {"description": "Model not loaded (`model_unavailable`)"}},
)
async def create_prediction(
    body: PredictionCreate, user: CurrentUser, session: SessionDep, model: ModelDep
) -> PredictionOut:
    loaded, model_version_id = model
    return await service.predict(session, user.id, body, loaded, model_version_id)


@router.get("/predictions", response_model=Page[PredictionOut])
async def list_predictions(
    request: Request,
    user: CurrentUser,
    session: SessionDep,
    limit: LimitQuery = DEFAULT_PAGE_SIZE,
    cursor: CursorQuery = None,
) -> Page[PredictionOut]:
    return await service.list_predictions(
        session, user.id, cursor=cursor, limit=limit, model=getattr(request.app.state, "model", None)
    )


@router.get("/model", response_model=ModelInfo, responses={503: {"description": "Model not loaded"}})
async def model_info(request: Request, user: CurrentUser, session: SessionDep) -> ModelInfo:
    """Version, dataset, test metrics and limitations of the active model (for the Model Info screen)."""
    return await service.model_info(session, request)


@router.get("/logs", response_model=Page[PickupLogOut])
async def list_logs(
    user: CurrentUser,
    session: SessionDep,
    restaurant_id: uuid.UUID | None = None,
    limit: LimitQuery = DEFAULT_PAGE_SIZE,
    cursor: CursorQuery = None,
) -> Page[PickupLogOut]:
    return await service.list_logs(session, user.id, restaurant_id=restaurant_id, cursor=cursor, limit=limit)


@router.post("/logs", status_code=status.HTTP_201_CREATED, response_model=PickupLogOut, responses=_NOT_FOUND)
async def create_log(body: PickupLogCreate, user: CurrentUser, session: SessionDep) -> PickupLogOut:
    return await service.create_log(session, user.id, body)


@router.delete("/logs/{log_id}", status_code=status.HTTP_204_NO_CONTENT, responses=_NOT_FOUND)
async def delete_log(log_id: uuid.UUID, user: CurrentUser, session: SessionDep) -> Response:
    await service.delete_log(session, user.id, log_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
