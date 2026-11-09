"""TrueProfit tables: work sessions, income and expense records (docs/DATABASE_DESIGN.md §3.4–3.6)."""

import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Boolean, CheckConstraint, Date, ForeignKey, Index, Integer, Numeric, Text, func, text
from sqlalchemy.dialects.postgresql import UUID, ExcludeConstraint
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import DateTime

from app.db.base import Base, created_at_column, updated_at_column, uuid_pk

EXPENSE_CATEGORIES = ("fuel", "maintenance", "depreciation", "other")
NOTES_MAX_LENGTH = 500
SOURCE_LABEL_MAX_LENGTH = 50
WORK_SESSION_OVERLAP_CONSTRAINT = "ex_work_sessions_no_overlap"


def _user_fk() -> Mapped[uuid.UUID]:
    return mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)


def _work_session_fk() -> Mapped[uuid.UUID | None]:
    return mapped_column(UUID(as_uuid=True), ForeignKey("work_sessions.id", ondelete="SET NULL"))


def _is_demo() -> Mapped[bool]:
    return mapped_column(Boolean, nullable=False, server_default=text("false"))


class WorkSession(Base):
    __tablename__ = "work_sessions"
    __table_args__ = (
        CheckConstraint("ended_at > started_at", name="ended_after_started"),
        CheckConstraint("ended_at - started_at <= interval '24 hours'", name="max_24_hours"),
        CheckConstraint("distance_km IS NULL OR distance_km >= 0", name="distance_km"),
        CheckConstraint("order_count IS NULL OR order_count >= 0", name="order_count"),
        CheckConstraint(f"notes IS NULL OR char_length(notes) <= {NOTES_MAX_LENGTH}", name="notes_length"),
        # Sessions of one user may touch ([) bounds) but never overlap. The service checks first to
        # return a clear error; this constraint closes the race between two concurrent writes.
        ExcludeConstraint(
            ("user_id", "="),
            (func.tstzrange(text("started_at"), text("ended_at")), "&&"),
            name=WORK_SESSION_OVERLAP_CONSTRAINT,
            using="gist",
        ),
        Index("ix_work_sessions_user_id_started_at", "user_id", text("started_at DESC")),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    user_id: Mapped[uuid.UUID] = _user_fk()
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ended_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    distance_km: Mapped[Decimal | None] = mapped_column(Numeric(8, 2))
    order_count: Mapped[int | None] = mapped_column(Integer)
    notes: Mapped[str | None] = mapped_column(Text)
    is_demo: Mapped[bool] = _is_demo()
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


class IncomeRecord(Base):
    __tablename__ = "income_records"
    __table_args__ = (
        CheckConstraint("amount >= 0", name="amount"),
        CheckConstraint("order_count IS NULL OR order_count >= 0", name="order_count"),
        CheckConstraint("distance_km IS NULL OR distance_km >= 0", name="distance_km"),
        CheckConstraint(
            "working_hours IS NULL OR (working_hours > 0 AND working_hours <= 24)", name="working_hours"
        ),
        CheckConstraint(
            f"source_label IS NULL OR char_length(source_label) <= {SOURCE_LABEL_MAX_LENGTH}",
            name="source_label_length",
        ),
        CheckConstraint(f"notes IS NULL OR char_length(notes) <= {NOTES_MAX_LENGTH}", name="notes_length"),
        Index("ix_income_records_user_id_occurred_on", "user_id", text("occurred_on DESC")),
        Index("ix_income_records_work_session_id", "work_session_id"),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    user_id: Mapped[uuid.UUID] = _user_fk()
    work_session_id: Mapped[uuid.UUID | None] = _work_session_fk()
    occurred_on: Mapped[date] = mapped_column(Date, nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    order_count: Mapped[int | None] = mapped_column(Integer)
    distance_km: Mapped[Decimal | None] = mapped_column(Numeric(8, 2))
    # Counted in TrueProfit only while the record is not linked to a work session (no double count).
    working_hours: Mapped[Decimal | None] = mapped_column(Numeric(5, 2))
    source_label: Mapped[str | None] = mapped_column(Text)  # free text typed by the rider, not an integration
    notes: Mapped[str | None] = mapped_column(Text)
    is_demo: Mapped[bool] = _is_demo()
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


class ExpenseRecord(Base):
    __tablename__ = "expense_records"
    __table_args__ = (
        CheckConstraint("category IN ('fuel', 'maintenance', 'depreciation', 'other')", name="category"),
        CheckConstraint("amount >= 0", name="amount"),
        CheckConstraint(
            f"description IS NULL OR char_length(description) <= {NOTES_MAX_LENGTH}",
            name="description_length",
        ),
        Index("ix_expense_records_user_id_occurred_on", "user_id", text("occurred_on DESC")),
        Index("ix_expense_records_user_id_category", "user_id", "category"),
        Index("ix_expense_records_work_session_id", "work_session_id"),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    user_id: Mapped[uuid.UUID] = _user_fk()
    work_session_id: Mapped[uuid.UUID | None] = _work_session_fk()
    occurred_on: Mapped[date] = mapped_column(Date, nullable=False)
    category: Mapped[str] = mapped_column(Text, nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    is_demo: Mapped[bool] = _is_demo()
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()
