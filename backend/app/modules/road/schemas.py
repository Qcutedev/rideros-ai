"""RoadContext request / response models."""

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field

from app.core.schemas import StrictModel
from app.modules.road.rules import AiStatus, Category, IncidentStatus

REPORTED_BY_USERS = (
    "Reported by riders, not verified by RiderOS. Locations and times come from the reports and "
    "may be out of date."
)


class Coordinates(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)


class IncidentOut(BaseModel):
    """Aggregate view of an incident. Never names or counts reporters beyond the totals."""

    id: uuid.UUID
    category: Category
    status: IncidentStatus = Field(
        description="Effective status: an open incident past expires_at is expired"
    )
    location: Coordinates
    first_reported_at: datetime
    last_reported_at: datetime
    report_count: int
    distinct_reporters: int = Field(description="Riders who reported it or said it is still there")
    cleared_count: int = Field(description="Riders who said it is gone since the last report")
    expires_at: datetime
    distance_m: float | None = Field(default=None, description="Only in /nearby results")


class MyConfirmation(BaseModel):
    still_present: bool
    created_at: datetime


class OwnReportOut(BaseModel):
    """A report the current rider submitted (only ever returned to its author)."""

    id: uuid.UUID
    incident_id: uuid.UUID
    category: Category
    description: str | None
    location: Coordinates
    has_image: bool
    ai_status: AiStatus
    ai_label: str | None = Field(description="Suggested category from the photo; a suggestion only")
    ai_confidence: Decimal | None
    created_at: datetime
    incident_status: IncidentStatus


class IncidentDetail(IncidentOut):
    my_report: OwnReportOut | None
    my_confirmation: MyConfirmation | None
    notice: str = REPORTED_BY_USERS


class IncidentList(BaseModel):
    items: list[IncidentOut]
    truncated: bool = Field(description="More incidents matched than `limit`; zoom in or move closer")
    notice: str = REPORTED_BY_USERS


class ReportCreated(BaseModel):
    report_id: uuid.UUID
    incident_id: uuid.UUID
    merged: bool = Field(description="True when the report joined an existing nearby incident")
    status: IncidentStatus
    incident: IncidentOut


class ConfirmationIn(StrictModel):
    still_present: bool


class StatusUpdate(StrictModel):
    status: Literal["resolved", "rejected"]
