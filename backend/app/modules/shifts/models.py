"""Shift Simulator (docs/DATABASE_DESIGN.md §3.8). Estimates only: never mixed into TrueProfit actuals."""

import uuid
from datetime import datetime, time
from decimal import Decimal
from typing import Any

from sqlalchemy import CheckConstraint, ForeignKey, Index, Integer, Numeric, SmallInteger, Text, Time, text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, created_at_column, updated_at_column, uuid_pk

ESTIMATION_METHODS = ("assumption", "historical", "ml")
SCENARIO_NAME_MAX_LENGTH = 60


class ShiftScenario(Base):
    __tablename__ = "shift_scenarios"
    __table_args__ = (
        CheckConstraint(f"char_length(name) BETWEEN 1 AND {SCENARIO_NAME_MAX_LENGTH}", name="name_length"),
        CheckConstraint("duration_minutes BETWEEN 30 AND 960", name="duration_minutes"),
        CheckConstraint("planned_weekday IS NULL OR planned_weekday BETWEEN 0 AND 6", name="planned_weekday"),
        CheckConstraint("estimation_method IN ('assumption', 'historical', 'ml')", name="estimation_method"),
        CheckConstraint("estimation_method = 'ml' OR model_version_id IS NULL", name="model_only_for_ml"),
        CheckConstraint(
            "estimate_low IS NULL OR estimate_high IS NULL OR estimate_low <= estimate_high",
            name="estimate_range",
        ),
        Index("ix_shift_scenarios_user_id_created_at", "user_id", text("created_at DESC")),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    start_time: Mapped[time] = mapped_column(Time, nullable=False)
    end_time: Mapped[time] = mapped_column(Time, nullable=False)  # end < start: crosses midnight
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    planned_weekday: Mapped[int | None] = mapped_column(SmallInteger)  # 0 = Monday … 6 = Sunday
    assumptions: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    estimation_method: Mapped[str] = mapped_column(Text, nullable=False)
    estimated_revenue: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    estimated_expenses: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    estimated_net_profit: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    estimate_low: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))  # range of net profit
    estimate_high: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    # How the estimate was made (inputs used, their source, warnings) so the app can explain it.
    estimate_details: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    model_version_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("model_versions.id", ondelete="RESTRICT")
    )
    actual_work_session_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("work_sessions.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()
