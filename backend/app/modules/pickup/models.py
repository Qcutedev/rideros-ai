"""Pickup Intelligence tables (docs/DATABASE_DESIGN.md §3.9–3.13)."""

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any

from geoalchemy2 import Geography
from sqlalchemy import (
    Boolean,
    CheckConstraint,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    SmallInteger,
    Text,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import DateTime

from app.db.base import Base, created_at_column, updated_at_column, uuid_pk

RESTAURANT_SOURCES = ("dataset_meituan", "dataset_skip", "user")
DATASET_SOURCES = ("dataset_meituan", "dataset_skip")
DATA_AVAILABILITY = ("sufficient", "limited", "insufficient")
PICKUP_LOG_NOTES_MAX_LENGTH = 300
RESTAURANT_NAME_MAX_LENGTH = 120

_STAT = Numeric(7, 3)  # minutes, as exported by the ML pipeline (3 decimals)


class Restaurant(Base):
    """Dataset POIs (shared, read-only) and restaurants a rider creates for the Pickup Log.

    Dataset rows also carry the aggregate statistics of restaurant_reference.csv and the
    `reference_da_id` the model needs as input. Dataset coordinates are shifted in the source,
    so dataset rows have no location.
    """

    __tablename__ = "restaurants"
    __table_args__ = (
        CheckConstraint("source IN ('dataset_meituan', 'dataset_skip', 'user')", name="source"),
        CheckConstraint("(source = 'user') = (owner_user_id IS NOT NULL)", name="owner_matches_source"),
        CheckConstraint(f"char_length(name) BETWEEN 1 AND {RESTAURANT_NAME_MAX_LENGTH}", name="name_length"),
        CheckConstraint(
            "data_availability IN ('sufficient', 'limited', 'insufficient')", name="data_availability"
        ),
        CheckConstraint("n_orders IS NULL OR n_orders >= 0", name="n_orders"),
        CheckConstraint("peak_hour IS NULL OR peak_hour BETWEEN 0 AND 23", name="peak_hour"),
        Index(
            "uq_restaurants_source_external_ref",
            "source",
            "external_ref",
            unique=True,
            postgresql_where=text("external_ref IS NOT NULL"),
        ),
        Index("ix_restaurants_owner_user_id", "owner_user_id"),
        Index("ix_restaurants_location", "location", postgresql_using="gist"),
        Index(
            "ix_restaurants_name_trgm",
            "name",
            postgresql_using="gin",
            postgresql_ops={"name": "gin_trgm_ops"},
        ),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    source: Mapped[str] = mapped_column(Text, nullable=False)
    external_ref: Mapped[str | None] = mapped_column(Text)
    owner_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE")
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    location: Mapped[Any | None] = mapped_column(
        Geography(geometry_type="POINT", srid=4326, spatial_index=False)
    )
    # ---- dataset aggregates (NULL for user restaurants) ----
    reference_da_id: Mapped[str | None] = mapped_column(Text)
    n_orders: Mapped[int | None] = mapped_column(Integer)
    median_min: Mapped[Decimal | None] = mapped_column(_STAT)
    p25_min: Mapped[Decimal | None] = mapped_column(_STAT)
    p75_min: Mapped[Decimal | None] = mapped_column(_STAT)
    p90_min: Mapped[Decimal | None] = mapped_column(_STAT)
    peak_hour: Mapped[int | None] = mapped_column(SmallInteger)
    data_availability: Mapped[str | None] = mapped_column(Text)
    dataset_version: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


class RestaurantTimeStat(Base):
    __tablename__ = "restaurant_time_stats"
    __table_args__ = (
        CheckConstraint("day_type IN ('weekday', 'weekend')", name="day_type"),
        CheckConstraint("hour BETWEEN 0 AND 23", name="hour"),
        CheckConstraint("n_orders >= 0", name="n_orders"),
    )

    restaurant_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("restaurants.id", ondelete="CASCADE"), primary_key=True
    )
    day_type: Mapped[str] = mapped_column(Text, primary_key=True)
    hour: Mapped[int] = mapped_column(SmallInteger, primary_key=True)
    n_orders: Mapped[int] = mapped_column(Integer, nullable=False)
    median_min: Mapped[Decimal | None] = mapped_column(_STAT)
    p25_min: Mapped[Decimal | None] = mapped_column(_STAT)
    p75_min: Mapped[Decimal | None] = mapped_column(_STAT)
    p90_min: Mapped[Decimal | None] = mapped_column(_STAT)
    dataset_version: Mapped[str] = mapped_column(Text, nullable=False)


class PickupLog(Base):
    """Personal Pickup Log: the only real rider-wait data in the system."""

    __tablename__ = "pickup_logs"
    __table_args__ = (
        CheckConstraint("picked_up_at >= arrived_at", name="picked_up_after_arrival"),
        CheckConstraint("picked_up_at - arrived_at <= interval '3 hours'", name="max_3_hours"),
        CheckConstraint(
            f"notes IS NULL OR char_length(notes) <= {PICKUP_LOG_NOTES_MAX_LENGTH}", name="notes_length"
        ),
        Index(
            "ix_pickup_logs_user_id_restaurant_id_arrived_at",
            "user_id",
            "restaurant_id",
            text("arrived_at DESC"),
        ),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    restaurant_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("restaurants.id", ondelete="CASCADE"), nullable=False
    )
    arrived_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    picked_up_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = created_at_column()


class ModelVersion(Base):
    """Synced from the artifact folder at startup. `metrics` is metrics.json verbatim (never hand-made)."""

    __tablename__ = "model_versions"
    __table_args__ = (
        Index("uq_model_versions_name_version", "name", "version", unique=True),
        Index("uq_model_versions_active_name", "name", unique=True, postgresql_where=text("is_active")),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    name: Mapped[str] = mapped_column(Text, nullable=False)
    version: Mapped[str] = mapped_column(Text, nullable=False)
    task: Mapped[str] = mapped_column(Text, nullable=False)
    dataset: Mapped[str] = mapped_column(Text, nullable=False)
    metrics: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    feature_schema: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    artifact_uri: Mapped[str] = mapped_column(Text, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))
    trained_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = created_at_column()


class PickupPrediction(Base):
    """Every prediction is stored; this table is also the prediction history (§3.13)."""

    __tablename__ = "pickup_predictions"
    __table_args__ = (
        CheckConstraint(
            "data_availability IN ('sufficient', 'limited', 'insufficient')", name="data_availability"
        ),
        CheckConstraint(
            "interval_low <= predicted_minutes AND predicted_minutes <= interval_high", name="interval"
        ),
        Index("ix_pickup_predictions_user_id_created_at", "user_id", text("created_at DESC")),
        Index("ix_pickup_predictions_model_version_id", "model_version_id"),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    restaurant_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("restaurants.id", ondelete="SET NULL")
    )
    model_version_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("model_versions.id", ondelete="RESTRICT"), nullable=False
    )
    requested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    input_features: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    predicted_minutes: Mapped[Decimal] = mapped_column(Numeric(6, 2), nullable=False)
    interval_low: Mapped[Decimal] = mapped_column(Numeric(6, 2), nullable=False)
    interval_high: Mapped[Decimal] = mapped_column(Numeric(6, 2), nullable=False)
    data_availability: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = created_at_column()
