"""RoadContext tables (docs/DATABASE_DESIGN.md §3.14–3.15)."""

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any

from geoalchemy2 import Geography
from sqlalchemy import CheckConstraint, ForeignKey, Index, Integer, Numeric, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import DateTime

from app.db.base import Base, created_at_column, updated_at_column, uuid_pk
from app.modules.road.rules import (
    AI_STATUSES,
    CATEGORIES,
    DESCRIPTION_MAX_LENGTH,
    INCIDENT_STATUSES,
    REPORT_TYPES,
    sql_in,
)


def _point() -> Geography:
    # A new instance per column: geoalchemy2 keeps column nullability on the type object.
    return Geography(geometry_type="POINT", srid=4326, spatial_index=False)


class RoadIncident(Base):
    """One real-world incident; nearby reports of the same category are grouped into it.

    Shared by all riders, but reporters are never exposed. `status` is the stored state: an
    active incident whose `expires_at` has passed counts as expired when read and is written as
    `expired` on the next RoadContext write.
    """

    __tablename__ = "road_incidents"
    __table_args__ = (
        CheckConstraint(f"category IN ({sql_in(CATEGORIES)})", name="category"),
        CheckConstraint(f"status IN ({sql_in(INCIDENT_STATUSES)})", name="status"),
        CheckConstraint("report_count >= 0", name="report_count"),
        CheckConstraint("distinct_reporters >= 0", name="distinct_reporters"),
        CheckConstraint("last_reported_at >= first_reported_at", name="report_order"),
        Index("ix_road_incidents_location", "location", postgresql_using="gist"),
        Index("ix_road_incidents_status_expires_at", "status", "expires_at"),
        Index("ix_road_incidents_category_last_reported_at", "category", text("last_reported_at DESC")),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    category: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'unverified'"))
    location: Mapped[Any] = mapped_column(_point(), nullable=False)
    first_reported_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    last_reported_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    report_count: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    distinct_reporters: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    status_changed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


class IncidentReport(Base):
    """A rider's report ("report") or confirmation ("still_present" / "cleared") of an incident.

    One report per rider per incident, and one current confirmation per rider per incident (a new
    confirmation replaces the old one). `ai_*` is only a suggestion from the image classifier.
    """

    __tablename__ = "incident_reports"
    __table_args__ = (
        CheckConstraint(f"category IN ({sql_in(CATEGORIES)})", name="category"),
        CheckConstraint(f"report_type IN ({sql_in(REPORT_TYPES)})", name="report_type"),
        CheckConstraint(f"ai_status IN ({sql_in(AI_STATUSES)})", name="ai_status"),
        CheckConstraint("ai_confidence IS NULL OR ai_confidence BETWEEN 0 AND 1", name="ai_confidence"),
        CheckConstraint(
            f"description IS NULL OR char_length(description) <= {DESCRIPTION_MAX_LENGTH}",
            name="description_length",
        ),
        CheckConstraint("(report_type = 'report') = (location IS NOT NULL)", name="location_on_reports"),
        CheckConstraint(
            "report_type = 'report' OR (image_key IS NULL AND description IS NULL)",
            name="confirmation_has_no_content",
        ),
        Index(
            "uq_incident_reports_report_per_user",
            "incident_id",
            "user_id",
            unique=True,
            postgresql_where=text("report_type = 'report'"),
        ),
        Index(
            "uq_incident_reports_confirmation_per_user",
            "incident_id",
            "user_id",
            unique=True,
            postgresql_where=text("report_type IN ('still_present', 'cleared')"),
        ),
        Index("ix_incident_reports_incident_id_created_at", "incident_id", "created_at"),
        Index("ix_incident_reports_user_id_created_at", "user_id", text("created_at DESC")),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    incident_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("road_incidents.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    report_type: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[str] = mapped_column(Text, nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    location: Mapped[Any | None] = mapped_column(_point(), nullable=True)
    image_key: Mapped[str | None] = mapped_column(Text)
    ai_status: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'none'"))
    ai_label: Mapped[str | None] = mapped_column(Text)
    ai_confidence: Mapped[Decimal | None] = mapped_column(Numeric(4, 3))
    ai_model_version_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("model_versions.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = created_at_column()
