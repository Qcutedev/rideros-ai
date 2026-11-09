"""Pickup Intelligence use cases: restaurants, analytics, Pickup Log, predictions, model info."""

import uuid
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from typing import Any

import structlog
from fastapi import Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import AppError, NotFoundError, ServiceUnavailableError
from app.core.pagination import InvalidCursorError, Page, decode_cursor, encode_cursor
from app.ml import predictor
from app.ml.registry import LoadedModel
from app.modules.pickup import repository as repo
from app.modules.pickup.models import DATASET_SOURCES, PickupLog, PickupPrediction, Restaurant
from app.modules.pickup.schemas import (
    ACKNOWLEDGEMENT,
    Coordinates,
    Interval,
    ModelInfo,
    OverallStats,
    PickupLogCreate,
    PickupLogOut,
    PredictionCreate,
    PredictionOut,
    RestaurantAnalytics,
    RestaurantCreate,
    RestaurantOut,
    StatCell,
    WaitStats,
)
from app.modules.users.service import get_locale

log = structlog.get_logger(__name__)

MAX_PICKUP_WAIT = timedelta(hours=3)
WAIT_STATS_MIN_N = 5
WAIT_STATS_OK_N = 20
_CENT = Decimal("0.01")


class RestaurantNotSupportedError(AppError):
    code = "restaurant_not_supported"
    message = "Predictions are only available for dataset restaurants"


class InvalidPickupTimesError(AppError):
    code = "invalid_pickup_times"


def _restaurant_not_found() -> NotFoundError:
    return NotFoundError("Restaurant not found", code="restaurant_not_found")


def _dec(value: float | Decimal | None) -> Decimal | None:
    return None if value is None else Decimal(str(value)).quantize(_CENT)


# ---- model ----


def model_unavailable() -> ServiceUnavailableError:
    return ServiceUnavailableError("The pickup model is not loaded", code="model_unavailable")


def get_model(request: Request) -> tuple[LoadedModel, uuid.UUID]:
    model: LoadedModel | None = getattr(request.app.state, "model", None)
    model_version_id: uuid.UUID | None = getattr(request.app.state, "model_version_id", None)
    if model is None or model_version_id is None:
        raise model_unavailable()
    return model, model_version_id


async def activate_model(session: AsyncSession, model: LoadedModel) -> uuid.UUID:
    """Record the loaded artifact in model_versions (metrics copied from metrics.json) and activate it."""
    meta = model.metadata
    data = meta.get("data", {})
    created = meta.get("created_at")
    values = {
        "name": model.name,
        "version": model.version,
        "task": f"regression:{model.feature_schema['target']['name']}",
        "dataset": f"Meituan INFORMS TSL dataset @ {str(data.get('commit', 'unknown'))[:12]} "
        f"({data.get('rows', '?')} orders)",
        "metrics": model.metrics,
        "feature_schema": model.feature_schema,
        "artifact_uri": model.artifact_uri,
        "trained_at": datetime.fromisoformat(created) if created else None,
    }
    model_version_id = await repo.activate_model_version(session, values)
    await session.commit()
    log.info(
        "model_activated", model=model.name, version=model.version, model_version_id=str(model_version_id)
    )
    return model_version_id


async def model_info(session: AsyncSession, request: Request) -> ModelInfo:
    model, model_version_id = get_model(request)
    row = await repo.get_model_version(session, model_version_id)
    if row is None:  # pragma: no cover - the row is written at startup
        raise model_unavailable()
    metrics, schema = row.metrics, row.feature_schema
    selected = metrics.get("selected_model", "")
    test = metrics.get("test", {})
    conformal = metrics.get("conformal_test", {})
    model_test, baseline = test.get(selected, {}), test.get("baseline_poi_median")
    limitations = [f"Not {item}." for item in schema.get("target", {}).get("is_not", [])]
    limitations.append(schema.get("domain", ""))
    if baseline and model_test.get("mae") and baseline.get("mae"):
        gain = (baseline["mae"] - model_test["mae"]) / baseline["mae"] * 100
        limitations.append(
            f"Test MAE {model_test['mae']:.2f} min vs {baseline['mae']:.2f} min for the per-restaurant "
            f"median baseline ({gain:.1f}% better): show the range, not a single number."
        )
    unseen = metrics.get("conformal_test_by_poi_bucket", {}).get("unseen in train")  # coverage (float)
    if isinstance(unseen, int | float):
        limitations.append(
            f"For restaurants not seen in training the {1 - model.conformal.alpha:.0%} interval covered only "
            f"{unseen:.1%} of test orders."
        )
    return ModelInfo(
        name=row.name,
        version=row.version,
        task=row.task,
        target=schema.get("target", {}),
        dataset=row.dataset,
        domain=schema.get("domain", ""),
        trained_at=row.trained_at,
        test_metrics={"model": selected, **model_test},
        baseline_test_metrics=baseline,
        interval={
            "method": "split conformal",
            "nominal_coverage": 1 - model.conformal.alpha,
            "test_coverage": conformal.get("coverage"),
            "test_mean_width_minutes": conformal.get("mean_width"),
        },
        limitations=[item for item in limitations if item],
        acknowledgement=ACKNOWLEDGEMENT,
    )


# ---- restaurants ----


def _restaurant_out(row: Restaurant, user_id: uuid.UUID, coords: tuple[float, float] | None) -> RestaurantOut:
    own = row.owner_user_id == user_id
    return RestaurantOut(
        id=row.id,
        source=row.source,
        name=row.name,
        is_own=own,
        supports_prediction=row.source in DATASET_SOURCES and row.reference_da_id is not None,
        data_availability=row.data_availability,  # type: ignore[arg-type]
        n_orders=row.n_orders,
        location=Coordinates(lat=coords[0], lng=coords[1]) if own and coords else None,
        created_at=row.created_at,
    )


async def _visible(session: AsyncSession, user_id: uuid.UUID, restaurant_id: uuid.UUID) -> Restaurant:
    row = await repo.get_visible_restaurant(session, user_id, restaurant_id)
    if row is None:  # missing, or another rider's private restaurant
        raise _restaurant_not_found()
    return row


async def list_restaurants(
    session: AsyncSession,
    user_id: uuid.UUID,
    *,
    q: str | None,
    source: str | None,
    cursor: str | None,
    limit: int,
) -> Page[RestaurantOut]:
    after: repo.RestaurantCursor | None = None
    if cursor is not None:
        flag, name, row_id = decode_cursor(cursor, 3)
        if flag not in ("0", "1"):
            raise InvalidCursorError()
        try:
            after = (flag == "1", name, uuid.UUID(row_id))
        except ValueError as exc:
            raise InvalidCursorError() from exc
    rows = await repo.list_restaurants(session, user_id, q=q, source=source, after=after, limit=limit + 1)
    next_cursor = None
    if len(rows) > limit:
        rows = rows[:limit]
        last = rows[-1]
        next_cursor = encode_cursor(["1" if last.owner_user_id is None else "0", last.name, str(last.id)])
    coords = await repo.restaurant_coordinates(session, [r.id for r in rows if r.owner_user_id == user_id])
    items = [_restaurant_out(r, user_id, coords.get(r.id)) for r in rows]
    return Page[RestaurantOut](items=items, next_cursor=next_cursor)


async def create_restaurant(
    session: AsyncSession, user_id: uuid.UUID, body: RestaurantCreate
) -> RestaurantOut:
    location = f"SRID=4326;POINT({body.location.lng} {body.location.lat})" if body.location else None
    row = await repo.add_restaurant(
        session, Restaurant(source="user", owner_user_id=user_id, name=body.name, location=location)
    )
    await session.commit()
    coords = (body.location.lat, body.location.lng) if body.location else None
    return _restaurant_out(row, user_id, coords)


async def analytics(
    session: AsyncSession, user_id: uuid.UUID, restaurant_id: uuid.UUID
) -> RestaurantAnalytics:
    row = await _visible(session, user_id, restaurant_id)
    coords = (await repo.restaurant_coordinates(session, [row.id])).get(row.id)
    cells: dict[str, dict[int, StatCell]] = {
        day_type: {
            h: StatCell(hour=h, n_orders=0, median_min=None, p25_min=None, p75_min=None, p90_min=None)
            for h in range(24)
        }
        for day_type in ("weekday", "weekend")
    }
    for stat in await repo.time_stats(session, row.id):
        cells[stat.day_type][stat.hour] = StatCell(
            hour=stat.hour,
            n_orders=stat.n_orders,
            median_min=stat.median_min,
            p25_min=stat.p25_min,
            p75_min=stat.p75_min,
            p90_min=stat.p90_min,
        )
    is_dataset = row.source in DATASET_SOURCES
    overall = (
        OverallStats(
            n_orders=row.n_orders or 0,
            median_min=row.median_min,
            p25_min=row.p25_min,
            p75_min=row.p75_min,
            p90_min=row.p90_min,
            peak_hour=row.peak_hour,
        )
        if is_dataset
        else None
    )
    return RestaurantAnalytics(
        restaurant=_restaurant_out(row, user_id, coords),
        data_availability=row.data_availability or "insufficient",  # type: ignore[arg-type]
        overall=overall,
        by_hour={k: list(v.values()) for k, v in cells.items()},  # type: ignore[misc]
        dataset_version=row.dataset_version,
        acknowledgement=ACKNOWLEDGEMENT if is_dataset else None,
    )


async def wait_stats(session: AsyncSession, user_id: uuid.UUID, restaurant_id: uuid.UUID) -> WaitStats:
    await _visible(session, user_id, restaurant_id)
    agg = await repo.wait_stats(session, user_id, restaurant_id)
    if agg.n < WAIT_STATS_MIN_N:
        return WaitStats(
            restaurant_id=restaurant_id,
            n=agg.n,
            median_minutes=None,
            p80_minutes=None,
            confidence="insufficient",
        )
    return WaitStats(
        restaurant_id=restaurant_id,
        n=agg.n,
        median_minutes=_dec(agg.median),
        p80_minutes=_dec(agg.p80),
        confidence="ok" if agg.n >= WAIT_STATS_OK_N else "low",
    )


# ---- pickup logs ----


def _log_out(row: PickupLog, restaurant_name: str) -> PickupLogOut:
    wait = Decimal((row.picked_up_at - row.arrived_at) // timedelta(microseconds=1)) / Decimal(60_000_000)
    return PickupLogOut(
        id=row.id,
        restaurant_id=row.restaurant_id,
        restaurant_name=restaurant_name,
        arrived_at=row.arrived_at,
        picked_up_at=row.picked_up_at,
        wait_minutes=wait.quantize(_CENT),
        notes=row.notes,
        created_at=row.created_at,
    )


async def create_log(session: AsyncSession, user_id: uuid.UUID, body: PickupLogCreate) -> PickupLogOut:
    if body.picked_up_at < body.arrived_at:
        raise InvalidPickupTimesError("picked_up_at must not be before arrived_at")
    if body.picked_up_at - body.arrived_at > MAX_PICKUP_WAIT:
        raise InvalidPickupTimesError("A pickup wait can be at most 3 hours", code="pickup_wait_too_long")
    restaurant = await _visible(session, user_id, body.restaurant_id)
    row = await repo.add_log(session, PickupLog(user_id=user_id, **body.model_dump()))
    await session.commit()
    return _log_out(row, restaurant.name)


def _created_cursor(cursor: str | None) -> repo.CreatedCursor | None:
    if cursor is None:
        return None
    stamp, row_id = decode_cursor(cursor, 2)
    try:
        return datetime.fromisoformat(stamp), uuid.UUID(row_id)
    except ValueError as exc:
        raise InvalidCursorError() from exc


async def list_logs(
    session: AsyncSession,
    user_id: uuid.UUID,
    *,
    restaurant_id: uuid.UUID | None,
    cursor: str | None,
    limit: int,
) -> Page[PickupLogOut]:
    rows = await repo.list_logs(
        session, user_id, restaurant_id=restaurant_id, after=_created_cursor(cursor), limit=limit + 1
    )
    next_cursor = None
    if len(rows) > limit:
        rows = rows[:limit]
        last = rows[-1][0]
        next_cursor = encode_cursor([last.arrived_at.isoformat(), str(last.id)])
    return Page[PickupLogOut](items=[_log_out(r, n) for r, n in rows], next_cursor=next_cursor)


async def delete_log(session: AsyncSession, user_id: uuid.UUID, log_id: uuid.UUID) -> None:
    if not await repo.delete_log(session, user_id, log_id):
        raise NotFoundError("Pickup log not found", code="pickup_log_not_found")
    await session.commit()


# ---- predictions ----


def _warnings(data_availability: str) -> list[str]:
    warnings = ["foreign_dataset"]
    if data_availability != "sufficient":
        warnings.append(f"{data_availability}_restaurant_data")
    return warnings


def _prediction_out(
    row: PickupPrediction, restaurant_name: str | None, model_version: str, nominal: float | None
) -> PredictionOut:
    return PredictionOut(
        id=row.id,
        restaurant_id=row.restaurant_id,
        restaurant_name=restaurant_name,
        predicted_minutes=row.predicted_minutes,
        interval=Interval(low=row.interval_low, high=row.interval_high, nominal_coverage=nominal),
        data_availability=row.data_availability,  # type: ignore[arg-type]
        warnings=_warnings(row.data_availability),
        model_version=model_version,
        requested_at=row.requested_at,
        input_features=row.input_features,
        created_at=row.created_at,
    )


async def predict(
    session: AsyncSession,
    user_id: uuid.UUID,
    body: PredictionCreate,
    model: LoadedModel,
    model_version_id: uuid.UUID,
) -> PredictionOut:
    restaurant = await _visible(session, user_id, body.restaurant_id)
    if restaurant.source not in DATASET_SOURCES or restaurant.reference_da_id is None:
        raise RestaurantNotSupportedError()
    requested_at = body.requested_at or datetime.now(UTC)
    zone = (await get_locale(session, user_id)).zone
    local_time = requested_at.astimezone(zone).replace(tzinfo=None)
    result = await predictor.predict(
        model, poi_id=restaurant.external_ref or "", da_id=restaurant.reference_da_id, local_time=local_time
    )
    features: dict[str, Any] = {**result.features, "timezone": zone.key}
    availability = restaurant.data_availability or "insufficient"
    point = _dec(result.minutes)
    low = min(_dec(result.low), point)  # type: ignore[type-var]
    high = max(_dec(result.high), point)  # type: ignore[type-var]
    row = await repo.add_prediction(
        session,
        PickupPrediction(
            user_id=user_id,
            restaurant_id=restaurant.id,
            model_version_id=model_version_id,
            requested_at=requested_at,
            input_features=features,
            predicted_minutes=point,
            interval_low=low,
            interval_high=high,
            data_availability=availability,
        ),
    )
    await session.commit()
    return _prediction_out(row, restaurant.name, model.version, 1 - model.conformal.alpha)


async def list_predictions(
    session: AsyncSession, user_id: uuid.UUID, *, cursor: str | None, limit: int, model: LoadedModel | None
) -> Page[PredictionOut]:
    """History. Works without a loaded model; nominal coverage is known only for the loaded version."""
    rows = await repo.list_predictions(session, user_id, after=_created_cursor(cursor), limit=limit + 1)
    next_cursor = None
    if len(rows) > limit:
        rows = rows[:limit]
        last = rows[-1][0]
        next_cursor = encode_cursor([last.created_at.isoformat(), str(last.id)])
    items = [
        _prediction_out(
            p, name, version, 1 - model.conformal.alpha if model and model.version == version else None
        )
        for p, name, version in rows
    ]
    return Page[PredictionOut](items=items, next_cursor=next_cursor)
