"""Pickup data access. Dataset restaurants are shared; everything else is scoped by `user_id`."""

import uuid
from datetime import datetime
from typing import Any, NamedTuple

from sqlalchemy import Select, delete, func, or_, select, tuple_, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql import ColumnElement

from app.modules.pickup.models import (
    ModelVersion,
    PickupLog,
    PickupPrediction,
    Restaurant,
    RestaurantTimeStat,
)

type RestaurantCursor = tuple[bool, str, uuid.UUID]  # (is_dataset, name, id): own restaurants first
type CreatedCursor = tuple[datetime, uuid.UUID]  # (created_at | arrived_at, id), newest first


def _visible_to(user_id: uuid.UUID) -> ColumnElement[bool]:
    return or_(Restaurant.owner_user_id.is_(None), Restaurant.owner_user_id == user_id)


def _escape_like(value: str) -> str:
    return value.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


# ---- restaurants ----


async def get_visible_restaurant(
    session: AsyncSession, user_id: uuid.UUID, restaurant_id: uuid.UUID
) -> Restaurant | None:
    stmt = select(Restaurant).where(Restaurant.id == restaurant_id, _visible_to(user_id))
    return (await session.execute(stmt)).scalar_one_or_none()


async def restaurant_coordinates(
    session: AsyncSession, restaurant_ids: list[uuid.UUID]
) -> dict[uuid.UUID, tuple[float, float]]:
    """(lat, lng) of the restaurants that have a location."""
    if not restaurant_ids:
        return {}
    geom = func.geometry(Restaurant.location)
    stmt = select(Restaurant.id, func.ST_Y(geom), func.ST_X(geom)).where(
        Restaurant.id.in_(restaurant_ids), Restaurant.location.is_not(None)
    )
    return {rid: (lat, lng) for rid, lat, lng in await session.execute(stmt)}


async def list_restaurants(
    session: AsyncSession,
    user_id: uuid.UUID,
    *,
    q: str | None,
    source: str | None,
    after: RestaurantCursor | None,
    limit: int,
) -> list[Restaurant]:
    is_dataset = Restaurant.owner_user_id.is_(None)  # False for own rows, so they sort first
    stmt: Select[tuple[Restaurant]] = select(Restaurant).where(_visible_to(user_id))
    if source == "dataset":
        stmt = stmt.where(Restaurant.owner_user_id.is_(None))
    elif source == "user":
        stmt = stmt.where(Restaurant.owner_user_id == user_id)
    if q:
        stmt = stmt.where(Restaurant.name.ilike(f"%{_escape_like(q)}%", escape="\\"))
    if after is not None:
        stmt = stmt.where(tuple_(is_dataset, Restaurant.name, Restaurant.id) > tuple_(*after))
    stmt = stmt.order_by(is_dataset, Restaurant.name, Restaurant.id).limit(limit)
    return list((await session.execute(stmt)).scalars())


async def add_restaurant(session: AsyncSession, row: Restaurant) -> Restaurant:
    session.add(row)
    await session.flush()
    await session.refresh(row)
    return row


async def time_stats(session: AsyncSession, restaurant_id: uuid.UUID) -> list[RestaurantTimeStat]:
    stmt = select(RestaurantTimeStat).where(RestaurantTimeStat.restaurant_id == restaurant_id)
    return list((await session.execute(stmt)).scalars())


# ---- pickup logs ----


async def add_log(session: AsyncSession, row: PickupLog) -> PickupLog:
    session.add(row)
    await session.flush()
    await session.refresh(row)
    return row


async def list_logs(
    session: AsyncSession,
    user_id: uuid.UUID,
    *,
    restaurant_id: uuid.UUID | None,
    after: CreatedCursor | None,
    limit: int,
) -> list[tuple[PickupLog, str]]:
    stmt = (
        select(PickupLog, Restaurant.name)
        .join(Restaurant, Restaurant.id == PickupLog.restaurant_id)
        .where(PickupLog.user_id == user_id)
    )
    if restaurant_id is not None:
        stmt = stmt.where(PickupLog.restaurant_id == restaurant_id)
    if after is not None:
        stmt = stmt.where(tuple_(PickupLog.arrived_at, PickupLog.id) < tuple_(*after))
    stmt = stmt.order_by(PickupLog.arrived_at.desc(), PickupLog.id.desc()).limit(limit)
    return [(log, name) for log, name in await session.execute(stmt)]


async def delete_log(session: AsyncSession, user_id: uuid.UUID, log_id: uuid.UUID) -> bool:
    stmt = (
        delete(PickupLog).where(PickupLog.id == log_id, PickupLog.user_id == user_id).returning(PickupLog.id)
    )
    return (await session.execute(stmt)).scalar_one_or_none() is not None


class WaitAggregate(NamedTuple):
    n: int
    median: float | None
    p80: float | None


async def wait_stats(session: AsyncSession, user_id: uuid.UUID, restaurant_id: uuid.UUID) -> WaitAggregate:
    minutes = func.extract("epoch", PickupLog.picked_up_at - PickupLog.arrived_at) / 60
    stmt = select(
        func.count(),
        func.percentile_cont(0.5).within_group(minutes),
        func.percentile_cont(0.8).within_group(minutes),
    ).where(PickupLog.user_id == user_id, PickupLog.restaurant_id == restaurant_id)
    n, median, p80 = (await session.execute(stmt)).one()
    return WaitAggregate(int(n), median, p80)


# ---- model versions ----


async def activate_model_version(session: AsyncSession, values: dict[str, Any]) -> uuid.UUID:
    """Upsert (name, version) from the artifact and make it the only active version of `name`."""
    await session.execute(
        update(ModelVersion)
        .where(ModelVersion.name == values["name"], ModelVersion.version != values["version"])
        .values(is_active=False)
    )
    stmt = (
        insert(ModelVersion)
        .values(**values, is_active=True)
        .on_conflict_do_update(
            index_elements=[ModelVersion.name, ModelVersion.version],
            set_={k: v for k, v in values.items() if k not in ("name", "version")} | {"is_active": True},
        )
        .returning(ModelVersion.id)
    )
    return (await session.execute(stmt)).scalar_one()


async def get_model_version(session: AsyncSession, model_version_id: uuid.UUID) -> ModelVersion | None:
    return await session.get(ModelVersion, model_version_id)


# ---- predictions ----


async def add_prediction(session: AsyncSession, row: PickupPrediction) -> PickupPrediction:
    session.add(row)
    await session.flush()
    await session.refresh(row)
    return row


async def list_predictions(
    session: AsyncSession, user_id: uuid.UUID, *, after: CreatedCursor | None, limit: int
) -> list[tuple[PickupPrediction, str | None, str]]:
    stmt = (
        select(PickupPrediction, Restaurant.name, ModelVersion.version)
        .outerjoin(Restaurant, Restaurant.id == PickupPrediction.restaurant_id)
        .join(ModelVersion, ModelVersion.id == PickupPrediction.model_version_id)
        .where(PickupPrediction.user_id == user_id)
    )
    if after is not None:
        stmt = stmt.where(tuple_(PickupPrediction.created_at, PickupPrediction.id) < tuple_(*after))
    stmt = stmt.order_by(PickupPrediction.created_at.desc(), PickupPrediction.id.desc()).limit(limit)
    return [(p, name, version) for p, name, version in await session.execute(stmt)]
