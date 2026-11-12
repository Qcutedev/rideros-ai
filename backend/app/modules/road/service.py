"""RoadContext use cases: reports with duplicate grouping, confirmations, map queries, admin status.

Rules (docs/DATABASE_DESIGN.md §4, values in settings):
- A report joins the closest open incident of the same category within the category's radius
  whose last report is within the category's window; otherwise it opens a new `unverified` one.
- Reports and "still present" confirmations move `last_reported_at` and push `expires_at` to
  last report + TTL.
- `unverified` -> `corroborated` once enough distinct riders reported or confirmed it within the
  window. `unverified`/`corroborated` -> `resolved` once enough riders said "cleared" after the
  last report. Only an admin can reject (or resolve directly).
- An open incident past `expires_at` is expired: reads report it as expired at once, and the row
  is written as `expired` by the next RoadContext write. No background scheduler.
"""

import asyncio
import uuid
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from sqlalchemy import Select, and_, delete, func, literal, select, text, tuple_, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql import ColumnElement

from app.core.config import Settings
from app.core.errors import AppError, ConflictError, ForbiddenError, NotFoundError
from app.core.pagination import InvalidCursorError, Page, decode_cursor, encode_cursor
from app.modules.road.images import ImageStorageUnavailableError, ImageStore, reencode
from app.modules.road.models import IncidentReport, RoadIncident
from app.modules.road.rules import ACTIVE_STATUSES, AI_PENDING_TIMEOUT, Category
from app.modules.road.schemas import (
    Coordinates,
    IncidentDetail,
    IncidentList,
    IncidentOut,
    MyConfirmation,
    OwnReportOut,
    ReportCreated,
)
from app.modules.users.models import User

MAX_BBOX_SPAN_DEG = 2.0
BBOX_LIMIT = 300
NEARBY_LIMIT = 100


def utcnow() -> datetime:
    """The service's clock (tests replace it to step over window / TTL boundaries)."""
    return datetime.now(UTC)


class AlreadyReportedError(ConflictError):
    code = "already_reported"
    message = "You already reported this incident; confirm it instead"


class IncidentClosedError(ConflictError):
    code = "incident_closed"
    message = "This incident is no longer open"


class InvalidBBoxError(AppError):
    code = "invalid_bbox"
    message = f"bbox must be min_lng,min_lat,max_lng,max_lat spanning at most {MAX_BBOX_SPAN_DEG} degrees"


def _incident_not_found() -> NotFoundError:
    return NotFoundError("Incident not found", code="incident_not_found")


def image_store(settings: Settings) -> ImageStore | None:
    return ImageStore(settings.road_image_dir) if settings.road_image_dir else None


def _ewkt(lat: float, lng: float) -> str:
    return f"SRID=4326;POINT({lng!r} {lat!r})"


def _geog(lat: float, lng: float) -> ColumnElement[Any]:
    return func.ST_GeogFromText(literal(_ewkt(lat, lng)))


def _lat_lng(column: Any) -> tuple[ColumnElement[float], ColumnElement[float]]:
    geom = func.geometry(column)
    return func.ST_Y(geom), func.ST_X(geom)


def _cleared_count() -> ColumnElement[int]:
    return (
        select(func.count())
        .where(
            IncidentReport.incident_id == RoadIncident.id,
            IncidentReport.report_type == "cleared",
            IncidentReport.created_at > RoadIncident.last_reported_at,
        )
        .correlate(RoadIncident)
        .scalar_subquery()
    )


def _open(now: datetime) -> ColumnElement[bool]:
    return and_(RoadIncident.status.in_(ACTIVE_STATUSES), RoadIncident.expires_at > now)


def _effective_status(row: RoadIncident, now: datetime) -> str:
    if row.status in ACTIVE_STATUSES and row.expires_at <= now:
        return "expired"
    return row.status


def _incident_select(*extra: Any) -> Select[Any]:
    lat, lng = _lat_lng(RoadIncident.location)
    return select(RoadIncident, lat, lng, _cleared_count(), *extra)


def _incident_out(row: Any, now: datetime, distance: float | None = None) -> dict[str, Any]:
    incident, lat, lng, cleared = row[0], row[1], row[2], row[3]
    return {
        "id": incident.id,
        "category": incident.category,
        "status": _effective_status(incident, now),
        "location": Coordinates(lat=lat, lng=lng),
        "first_reported_at": incident.first_reported_at,
        "last_reported_at": incident.last_reported_at,
        "report_count": incident.report_count,
        "distinct_reporters": incident.distinct_reporters,
        "cleared_count": cleared,
        "expires_at": incident.expires_at,
        "distance_m": distance,
    }


async def expire_overdue(session: AsyncSession, now: datetime) -> None:
    await session.execute(
        update(RoadIncident)
        .where(RoadIncident.status.in_(ACTIVE_STATUSES), RoadIncident.expires_at <= now)
        .values(status="expired", status_changed_at=now)
    )


async def _refresh(
    session: AsyncSession, incident: RoadIncident, settings: Settings, now: datetime, *, transitions: bool
) -> None:
    """Recompute the counters from incident_reports and apply the status rules."""
    rule = settings.road_rules[incident.category]  # type: ignore[index]
    seen = IncidentReport.report_type.in_(("report", "still_present"))
    stmt = select(
        func.count().filter(IncidentReport.report_type == "report"),
        func.count(func.distinct(IncidentReport.user_id)).filter(seen),
        func.count(func.distinct(IncidentReport.user_id)).filter(
            seen, IncidentReport.created_at >= now - rule.window
        ),
        func.count().filter(
            IncidentReport.report_type == "cleared",
            IncidentReport.created_at > incident.last_reported_at,
        ),
    ).where(IncidentReport.incident_id == incident.id)
    reports, distinct, recent, cleared = (await session.execute(stmt)).one()
    incident.report_count = reports
    incident.distinct_reporters = distinct
    if not transitions or incident.status not in ACTIVE_STATUSES:
        return
    if cleared >= settings.road_resolve_min_cleared:
        incident.status, incident.status_changed_at = "resolved", now
    elif incident.status == "unverified" and recent >= settings.road_corroborate_min_reporters:
        incident.status, incident.status_changed_at = "corroborated", now


async def _load_incident(session: AsyncSession, incident_id: uuid.UUID, now: datetime) -> Any:
    row = (await session.execute(_incident_select().where(RoadIncident.id == incident_id))).first()
    if row is None:
        raise _incident_not_found()
    return row


# ---- reports ----


@dataclass
class NewReport:
    category: Category
    lat: float
    lng: float
    description: str | None
    image: bytes | None = field(default=None, repr=False)


async def create_report(
    session: AsyncSession, settings: Settings, user_id: uuid.UUID, body: NewReport
) -> ReportCreated:
    store = image_store(settings)
    jpeg: bytes | None = None
    if body.image is not None:
        if store is None:
            raise ImageStorageUnavailableError()
        jpeg = await asyncio.to_thread(reencode, body.image)

    now = utcnow()
    rule = settings.road_rules[body.category]
    await expire_overdue(session, now)
    # One writer per category at a time, so two simultaneous first reports cannot open two incidents.
    await session.execute(select(func.pg_advisory_xact_lock(func.hashtext(f"road:{body.category}"))))
    point = _geog(body.lat, body.lng)
    candidate = (
        await session.execute(
            select(RoadIncident)
            .where(
                RoadIncident.category == body.category,
                _open(now),
                RoadIncident.last_reported_at >= now - rule.window,
                func.ST_DWithin(RoadIncident.location, point, rule.radius_m),
            )
            .order_by(func.ST_Distance(RoadIncident.location, point), RoadIncident.last_reported_at.desc())
            .limit(1)
            .with_for_update()
        )
    ).scalar_one_or_none()

    if candidate is not None:
        own = await session.scalar(
            select(IncidentReport.id).where(
                IncidentReport.incident_id == candidate.id,
                IncidentReport.user_id == user_id,
                IncidentReport.report_type == "report",
            )
        )
        if own is not None:
            raise AlreadyReportedError(details=[{"incident_id": str(candidate.id)}])
        incident, merged = candidate, True
    else:
        incident = RoadIncident(
            category=body.category,
            status="unverified",
            location=_ewkt(body.lat, body.lng),
            first_reported_at=now,
            last_reported_at=now,
            report_count=0,
            distinct_reporters=0,
            expires_at=now + rule.ttl,
            status_changed_at=now,
        )
        session.add(incident)
        await session.flush()
        merged = False

    key = store.save(jpeg) if store is not None and jpeg is not None else None
    try:
        report = IncidentReport(
            incident_id=incident.id,
            user_id=user_id,
            report_type="report",
            category=body.category,
            description=body.description,
            location=_ewkt(body.lat, body.lng),
            image_key=key,
            # The router queues the classifier for a photo when cv_service is configured.
            ai_status="pending" if key is not None and settings.cv_service_url else "none",
            created_at=now,
        )
        session.add(report)
        incident.last_reported_at = now
        incident.expires_at = now + rule.ttl
        await session.flush()
        await _refresh(session, incident, settings, now, transitions=True)
        await session.commit()
    except BaseException:
        await session.rollback()
        if key is not None and store is not None:
            store.delete([key])
        raise

    out = IncidentOut(**_incident_out(await _load_incident(session, incident.id, now), now))
    return ReportCreated(
        report_id=report.id, incident_id=incident.id, merged=merged, status=out.status, incident=out
    )


async def confirm(
    session: AsyncSession, settings: Settings, user_id: uuid.UUID, incident_id: uuid.UUID, still_present: bool
) -> IncidentDetail:
    now = utcnow()
    await expire_overdue(session, now)
    incident = (
        await session.execute(select(RoadIncident).where(RoadIncident.id == incident_id).with_for_update())
    ).scalar_one_or_none()
    if incident is None:
        raise _incident_not_found()
    if incident.status not in ACTIVE_STATUSES:
        raise IncidentClosedError(details=[{"status": incident.status}])

    report_type = "still_present" if still_present else "cleared"
    stmt = insert(IncidentReport).values(
        incident_id=incident.id,
        user_id=user_id,
        report_type=report_type,
        category=incident.category,
        created_at=now,
    )
    await session.execute(
        stmt.on_conflict_do_update(
            index_elements=["incident_id", "user_id"],
            index_where=text("report_type IN ('still_present', 'cleared')"),
            set_={"report_type": stmt.excluded.report_type, "created_at": stmt.excluded.created_at},
        )
    )
    if still_present:
        incident.last_reported_at = now
        incident.expires_at = now + settings.road_rules[incident.category].ttl  # type: ignore[index]
    await _refresh(session, incident, settings, now, transitions=True)
    await session.commit()
    return await get_incident(session, user_id, incident_id, now=now)


# ---- reads ----


def _ai_status(report: IncidentReport, now: datetime) -> str:
    if report.ai_status == "pending" and report.created_at < now - AI_PENDING_TIMEOUT:
        return "failed"
    return report.ai_status


def _own_report_out(
    report: IncidentReport, lat: float, lng: float, incident_status: str, now: datetime
) -> OwnReportOut:
    return OwnReportOut(
        id=report.id,
        incident_id=report.incident_id,
        category=report.category,  # type: ignore[arg-type]
        description=report.description,
        location=Coordinates(lat=lat, lng=lng),
        has_image=report.image_key is not None,
        ai_status=_ai_status(report, now),  # type: ignore[arg-type]
        ai_label=report.ai_label,
        ai_confidence=report.ai_confidence,
        created_at=report.created_at,
        incident_status=incident_status,  # type: ignore[arg-type]
    )


def _own_reports_select(user_id: uuid.UUID) -> Select[Any]:
    lat, lng = _lat_lng(IncidentReport.location)
    return (
        select(IncidentReport, lat, lng, RoadIncident)
        .join(RoadIncident, RoadIncident.id == IncidentReport.incident_id)
        .where(IncidentReport.user_id == user_id, IncidentReport.report_type == "report")
    )


async def get_incident(
    session: AsyncSession, user_id: uuid.UUID, incident_id: uuid.UUID, *, now: datetime | None = None
) -> IncidentDetail:
    now = now or utcnow()
    row = await _load_incident(session, incident_id, now)
    base = _incident_out(row, now)
    mine = (
        await session.execute(_own_reports_select(user_id).where(IncidentReport.incident_id == incident_id))
    ).first()
    confirmation = (
        await session.execute(
            select(IncidentReport).where(
                IncidentReport.incident_id == incident_id,
                IncidentReport.user_id == user_id,
                IncidentReport.report_type.in_(("still_present", "cleared")),
            )
        )
    ).scalar_one_or_none()
    return IncidentDetail(
        **base,
        my_report=_own_report_out(mine[0], mine[1], mine[2], base["status"], now) if mine else None,
        my_confirmation=MyConfirmation(
            still_present=confirmation.report_type == "still_present", created_at=confirmation.created_at
        )
        if confirmation
        else None,
    )


def parse_bbox(raw: str) -> tuple[float, float, float, float]:
    try:
        min_lng, min_lat, max_lng, max_lat = (float(v) for v in raw.split(","))
    except ValueError as exc:
        raise InvalidBBoxError() from exc
    ok = (
        -180 <= min_lng < max_lng <= 180
        and -90 <= min_lat < max_lat <= 90
        and max_lng - min_lng <= MAX_BBOX_SPAN_DEG
        and max_lat - min_lat <= MAX_BBOX_SPAN_DEG
    )
    if not ok:
        raise InvalidBBoxError()
    return min_lng, min_lat, max_lng, max_lat


async def list_in_bbox(session: AsyncSession, bbox: tuple[float, float, float, float]) -> IncidentList:
    now = utcnow()
    min_lng, min_lat, max_lng, max_lat = bbox
    lat, lng = _lat_lng(RoadIncident.location)
    stmt = (
        _incident_select()
        .where(
            _open(now),
            func.ST_Intersects(
                RoadIncident.location,
                func.geography(func.ST_MakeEnvelope(min_lng, min_lat, max_lng, max_lat, 4326)),
            ),
            lat.between(min_lat, max_lat),
            lng.between(min_lng, max_lng),
        )
        .order_by(RoadIncident.last_reported_at.desc(), RoadIncident.id)
        .limit(BBOX_LIMIT + 1)
    )
    rows = (await session.execute(stmt)).all()
    items = [IncidentOut(**_incident_out(r, now)) for r in rows[:BBOX_LIMIT]]
    return IncidentList(items=items, truncated=len(rows) > BBOX_LIMIT)


async def list_nearby(session: AsyncSession, lat: float, lng: float, radius_m: int) -> IncidentList:
    now = utcnow()
    point = _geog(lat, lng)
    distance = func.ST_Distance(RoadIncident.location, point)
    stmt = (
        _incident_select(distance)
        .where(_open(now), func.ST_DWithin(RoadIncident.location, point, radius_m))
        .order_by(distance, RoadIncident.id)
        .limit(NEARBY_LIMIT + 1)
    )
    rows = (await session.execute(stmt)).all()
    items = [IncidentOut(**_incident_out(r, now, distance=round(r[4], 1))) for r in rows[:NEARBY_LIMIT]]
    return IncidentList(items=items, truncated=len(rows) > NEARBY_LIMIT)


async def list_own_reports(
    session: AsyncSession, user_id: uuid.UUID, *, cursor: str | None, limit: int
) -> Page[OwnReportOut]:
    now = utcnow()
    stmt = _own_reports_select(user_id)
    if cursor is not None:
        created, report_id = decode_cursor(cursor, 2)
        try:
            after = (datetime.fromisoformat(created), uuid.UUID(report_id))
        except ValueError as exc:
            raise InvalidCursorError() from exc
        stmt = stmt.where(tuple_(IncidentReport.created_at, IncidentReport.id) < tuple_(*after))
    stmt = stmt.order_by(IncidentReport.created_at.desc(), IncidentReport.id.desc()).limit(limit + 1)
    rows = (await session.execute(stmt)).all()
    items = [_own_report_out(r[0], r[1], r[2], _effective_status(r[3], now), now) for r in rows[:limit]]
    next_cursor = None
    if len(rows) > limit:
        last = rows[limit - 1][0]
        next_cursor = encode_cursor([last.created_at.isoformat(), str(last.id)])
    return Page(items=items, next_cursor=next_cursor)


async def own_image_path(
    session: AsyncSession, settings: Settings, user_id: uuid.UUID, report_id: uuid.UUID
) -> Path:
    key = await session.scalar(
        select(IncidentReport.image_key).where(
            IncidentReport.id == report_id,
            IncidentReport.user_id == user_id,
            IncidentReport.image_key.is_not(None),
        )
    )
    store = image_store(settings)
    if key is None or store is None:
        raise NotFoundError("Photo not found", code="image_not_found")
    path = store.path(key)
    if not path.is_file():
        raise NotFoundError("Photo not found", code="image_not_found")
    return path


# ---- admin ----


async def set_status(session: AsyncSession, user: User, incident_id: uuid.UUID, status: str) -> IncidentOut:
    if user.role != "admin":
        raise ForbiddenError("Only an admin can change an incident's status", code="admin_only")
    now = utcnow()
    await expire_overdue(session, now)
    incident = await session.get(RoadIncident, incident_id, with_for_update=True)
    if incident is None:
        raise _incident_not_found()
    if incident.status not in ACTIVE_STATUSES:
        raise IncidentClosedError(details=[{"status": incident.status}])
    incident.status, incident.status_changed_at = status, now
    await session.commit()
    return IncidentOut(**_incident_out(await _load_incident(session, incident_id, now), now))


# ---- account deletion (users.service.delete_me) ----


@dataclass
class UserCleanup:
    incident_ids: list[uuid.UUID]
    image_keys: list[str]


async def prepare_user_deletion(session: AsyncSession, user_id: uuid.UUID) -> UserCleanup:
    rows = (
        await session.execute(
            select(IncidentReport.incident_id, IncidentReport.image_key).where(
                IncidentReport.user_id == user_id
            )
        )
    ).all()
    return UserCleanup(
        incident_ids=sorted({r[0] for r in rows}),
        image_keys=[r[1] for r in rows if r[1] is not None],
    )


async def finish_user_deletion(session: AsyncSession, settings: Settings, cleanup: UserCleanup) -> None:
    """After the user's rows are gone (same transaction): fix counters, drop incidents left empty."""
    if not cleanup.incident_ids:
        return
    now = utcnow()
    incidents = (
        await session.execute(select(RoadIncident).where(RoadIncident.id.in_(cleanup.incident_ids)))
    ).scalars()
    for incident in incidents:
        await _refresh(session, incident, settings, now, transitions=False)
    await session.flush()
    await session.execute(
        delete(RoadIncident).where(RoadIncident.id.in_(cleanup.incident_ids), RoadIncident.report_count == 0)
    )


def delete_images(settings: Settings, keys: list[str]) -> None:
    store = image_store(settings)
    if store is not None and keys:
        store.delete(keys)
