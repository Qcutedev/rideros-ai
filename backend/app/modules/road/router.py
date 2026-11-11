"""RoadContext HTTP API (/road/...)."""

import uuid
from typing import Annotated

from fastapi import APIRouter, File, Form, Query, Request, UploadFile, status
from fastapi.responses import FileResponse
from pydantic import StringConstraints

from app.core.deps import CurrentUser, SessionDep, SettingsDep
from app.core.pagination import DEFAULT_PAGE_SIZE, CursorQuery, LimitQuery, Page
from app.core.rate_limit import get_limiter
from app.modules.road import service
from app.modules.road.images import ImageTooLargeError
from app.modules.road.rules import DESCRIPTION_MAX_LENGTH, MAX_NEARBY_RADIUS_M, Category
from app.modules.road.schemas import (
    ConfirmationIn,
    IncidentDetail,
    IncidentList,
    IncidentOut,
    OwnReportOut,
    ReportCreated,
    StatusUpdate,
)

router = APIRouter(prefix="/road", tags=["road"])

_NOT_FOUND = {404: {"description": "Not found"}}
_MULTIPART_OVERHEAD = 64 * 1024  # form fields + boundaries on top of the photo itself

Description = Annotated[str, StringConstraints(strip_whitespace=True, max_length=DESCRIPTION_MAX_LENGTH)]


def _limit_reports(request: Request, settings: SettingsDep, user: CurrentUser) -> None:
    get_limiter(request).hit(settings.rate_limit_road_report, "road_report", str(user.id))


@router.post(
    "/reports",
    status_code=status.HTTP_201_CREATED,
    response_model=ReportCreated,
    responses={
        409: {"description": "You already reported the incident this report would join (`already_reported`)"},
        413: {"description": "Photo larger than the limit (`image_too_large`)"},
        415: {"description": "Photo is not JPEG / PNG / WebP (`unsupported_image`)"},
        503: {"description": "Photo storage not configured (`image_storage_unavailable`)"},
    },
)
async def create_report(
    request: Request,
    user: CurrentUser,
    session: SessionDep,
    settings: SettingsDep,
    category: Annotated[Category, Form()],
    lat: Annotated[float, Form(ge=-90, le=90)],
    lng: Annotated[float, Form(ge=-180, le=180)],
    description: Annotated[Description | None, Form()] = None,
    image: Annotated[UploadFile | None, File(description="JPEG / PNG / WebP, at most 5 MB")] = None,
) -> ReportCreated:
    """Report an incident at a location. Nearby reports of the same category join one incident."""
    max_bytes = settings.road_image_max_bytes
    declared = request.headers.get("content-length")
    if declared and declared.isdigit() and int(declared) > max_bytes + _MULTIPART_OVERHEAD:
        raise ImageTooLargeError(f"The photo must be at most {max_bytes // (1024 * 1024)} MB")
    _limit_reports(request, settings, user)
    data: bytes | None = None
    if image is not None:
        data = await image.read(max_bytes + 1)
        if len(data) > max_bytes:
            raise ImageTooLargeError(f"The photo must be at most {max_bytes // (1024 * 1024)} MB")
        if not data:
            data = None
    body = service.NewReport(category=category, lat=lat, lng=lng, description=description or None, image=data)
    return await service.create_report(session, settings, user.id, body)


@router.get("/reports", response_model=Page[OwnReportOut])
async def list_own_reports(
    user: CurrentUser,
    session: SessionDep,
    limit: LimitQuery = DEFAULT_PAGE_SIZE,
    cursor: CursorQuery = None,
) -> Page[OwnReportOut]:
    """The current rider's own reports, newest first."""
    return await service.list_own_reports(session, user.id, cursor=cursor, limit=limit)


@router.get(
    "/reports/{report_id}/image",
    response_class=FileResponse,
    responses={200: {"content": {"image/jpeg": {}}}, **_NOT_FOUND},
)
async def own_report_image(
    report_id: uuid.UUID, user: CurrentUser, session: SessionDep, settings: SettingsDep
) -> FileResponse:
    """The photo of one of the rider's own reports (re-encoded JPEG without metadata)."""
    path = await service.own_image_path(session, settings, user.id, report_id)
    return FileResponse(path, media_type="image/jpeg", headers={"Cache-Control": "private, max-age=3600"})


@router.get(
    "/incidents",
    response_model=IncidentList,
    responses={400: {"description": "Bad bbox (`invalid_bbox`)"}},
)
async def incidents_in_bbox(
    user: CurrentUser,
    session: SessionDep,
    bbox: Annotated[str, Query(max_length=100, description="min_lng,min_lat,max_lng,max_lat (≤ 2°)")],
) -> IncidentList:
    """Open incidents inside the map view, most recently reported first (at most 300)."""
    return await service.list_in_bbox(session, service.parse_bbox(bbox))


@router.get("/incidents/nearby", response_model=IncidentList)
async def incidents_nearby(
    user: CurrentUser,
    session: SessionDep,
    lat: Annotated[float, Query(ge=-90, le=90)],
    lng: Annotated[float, Query(ge=-180, le=180)],
    radius_m: Annotated[int, Query(ge=50, le=MAX_NEARBY_RADIUS_M)] = 2000,
) -> IncidentList:
    """Open incidents within `radius_m` of a point, closest first (at most 100)."""
    return await service.list_nearby(session, lat, lng, radius_m)


@router.get("/incidents/{incident_id}", response_model=IncidentDetail, responses=_NOT_FOUND)
async def get_incident(incident_id: uuid.UUID, user: CurrentUser, session: SessionDep) -> IncidentDetail:
    return await service.get_incident(session, user.id, incident_id)


@router.post(
    "/incidents/{incident_id}/confirmations",
    response_model=IncidentDetail,
    responses={**_NOT_FOUND, 409: {"description": "Incident is no longer open (`incident_closed`)"}},
)
async def confirm_incident(
    request: Request,
    incident_id: uuid.UUID,
    body: ConfirmationIn,
    user: CurrentUser,
    session: SessionDep,
    settings: SettingsDep,
) -> IncidentDetail:
    """Say the incident is still there (`true`) or gone (`false`). A new answer replaces your old one."""
    _limit_reports(request, settings, user)
    return await service.confirm(session, settings, user.id, incident_id, body.still_present)


@router.patch(
    "/incidents/{incident_id}/status",
    response_model=IncidentOut,
    responses={
        **_NOT_FOUND,
        403: {"description": "Not an admin (`admin_only`)"},
        409: {"description": "Incident is no longer open (`incident_closed`)"},
    },
)
async def set_incident_status(
    incident_id: uuid.UUID, body: StatusUpdate, user: CurrentUser, session: SessionDep
) -> IncidentOut:
    """Admin only: mark an open incident resolved or rejected."""
    return await service.set_status(session, user, incident_id, body.status)
