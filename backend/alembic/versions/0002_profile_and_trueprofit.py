"""Rider profile + TrueProfit tables: rider_profiles, work_sessions, income_records, expense_records.

Revision ID: 0002
Revises: 0001
Create Date: 2026-11-09
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_NOW = sa.text("now()")
_UUID = sa.text("gen_random_uuid()")
_FALSE = sa.text("false")


def _timestamps() -> list[sa.Column]:
    return [
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=_NOW, nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=_NOW, nullable=False),
    ]


def _user_fk(table: str) -> sa.ForeignKeyConstraint:
    return sa.ForeignKeyConstraint(
        ["user_id"], ["users.id"], name=op.f(f"fk_{table}_user_id_users"), ondelete="CASCADE"
    )


def _work_session_fk(table: str) -> sa.ForeignKeyConstraint:
    return sa.ForeignKeyConstraint(
        ["work_session_id"],
        ["work_sessions.id"],
        name=op.f(f"fk_{table}_work_session_id_work_sessions"),
        ondelete="SET NULL",
    )


def upgrade() -> None:
    # btree_gist lets the work-session exclusion constraint compare uuid with `=` inside a GiST
    # index. It is a trusted extension (PostgreSQL 13+), so the database owner can create it.
    op.execute("CREATE EXTENSION IF NOT EXISTS btree_gist")

    op.create_table(
        "rider_profiles",
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("vehicle_type", sa.Text(), nullable=True),
        sa.Column("fuel_km_per_liter", sa.Numeric(6, 2), nullable=True),
        sa.Column("fuel_price_per_liter", sa.Numeric(8, 2), nullable=True),
        sa.Column("depreciation_per_km", sa.Numeric(8, 4), nullable=True),
        sa.Column("timezone", sa.Text(), server_default=sa.text("'Asia/Bangkok'"), nullable=False),
        sa.Column("currency", sa.Text(), server_default=sa.text("'THB'"), nullable=False),
        *_timestamps(),
        sa.CheckConstraint(
            "vehicle_type IN ('motorcycle', 'ev_motorcycle', 'bicycle', 'car', 'other')",
            name=op.f("ck_rider_profiles_vehicle_type"),
        ),
        sa.CheckConstraint(
            "fuel_km_per_liter IS NULL OR fuel_km_per_liter > 0",
            name=op.f("ck_rider_profiles_fuel_km_per_liter"),
        ),
        sa.CheckConstraint(
            "fuel_price_per_liter IS NULL OR fuel_price_per_liter >= 0",
            name=op.f("ck_rider_profiles_fuel_price_per_liter"),
        ),
        sa.CheckConstraint(
            "depreciation_per_km IS NULL OR depreciation_per_km >= 0",
            name=op.f("ck_rider_profiles_depreciation_per_km"),
        ),
        sa.CheckConstraint(
            "char_length(timezone) BETWEEN 1 AND 64", name=op.f("ck_rider_profiles_timezone_length")
        ),
        sa.CheckConstraint("currency ~ '^[A-Z]{3}$'", name=op.f("ck_rider_profiles_currency_format")),
        _user_fk("rider_profiles"),
        sa.PrimaryKeyConstraint("user_id", name=op.f("pk_rider_profiles")),
    )

    op.create_table(
        "work_sessions",
        sa.Column("id", postgresql.UUID(as_uuid=True), server_default=_UUID, nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("distance_km", sa.Numeric(8, 2), nullable=True),
        sa.Column("order_count", sa.Integer(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("is_demo", sa.Boolean(), server_default=_FALSE, nullable=False),
        *_timestamps(),
        sa.CheckConstraint("ended_at > started_at", name=op.f("ck_work_sessions_ended_after_started")),
        sa.CheckConstraint(
            "ended_at - started_at <= interval '24 hours'", name=op.f("ck_work_sessions_max_24_hours")
        ),
        sa.CheckConstraint(
            "distance_km IS NULL OR distance_km >= 0", name=op.f("ck_work_sessions_distance_km")
        ),
        sa.CheckConstraint(
            "order_count IS NULL OR order_count >= 0", name=op.f("ck_work_sessions_order_count")
        ),
        sa.CheckConstraint(
            "notes IS NULL OR char_length(notes) <= 500", name=op.f("ck_work_sessions_notes_length")
        ),
        postgresql.ExcludeConstraint(
            ("user_id", "="),
            (sa.func.tstzrange(sa.text("started_at"), sa.text("ended_at")), "&&"),
            name="ex_work_sessions_no_overlap",
            using="gist",
        ),
        _user_fk("work_sessions"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_work_sessions")),
    )
    op.create_index(
        "ix_work_sessions_user_id_started_at", "work_sessions", ["user_id", sa.text("started_at DESC")]
    )

    op.create_table(
        "income_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), server_default=_UUID, nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("work_session_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("occurred_on", sa.Date(), nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("order_count", sa.Integer(), nullable=True),
        sa.Column("distance_km", sa.Numeric(8, 2), nullable=True),
        sa.Column("working_hours", sa.Numeric(5, 2), nullable=True),
        sa.Column("source_label", sa.Text(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("is_demo", sa.Boolean(), server_default=_FALSE, nullable=False),
        *_timestamps(),
        sa.CheckConstraint("amount >= 0", name=op.f("ck_income_records_amount")),
        sa.CheckConstraint(
            "order_count IS NULL OR order_count >= 0", name=op.f("ck_income_records_order_count")
        ),
        sa.CheckConstraint(
            "distance_km IS NULL OR distance_km >= 0", name=op.f("ck_income_records_distance_km")
        ),
        sa.CheckConstraint(
            "working_hours IS NULL OR (working_hours > 0 AND working_hours <= 24)",
            name=op.f("ck_income_records_working_hours"),
        ),
        sa.CheckConstraint(
            "source_label IS NULL OR char_length(source_label) <= 50",
            name=op.f("ck_income_records_source_label_length"),
        ),
        sa.CheckConstraint(
            "notes IS NULL OR char_length(notes) <= 500", name=op.f("ck_income_records_notes_length")
        ),
        _user_fk("income_records"),
        _work_session_fk("income_records"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_income_records")),
    )
    op.create_index(
        "ix_income_records_user_id_occurred_on", "income_records", ["user_id", sa.text("occurred_on DESC")]
    )
    op.create_index("ix_income_records_work_session_id", "income_records", ["work_session_id"])

    op.create_table(
        "expense_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), server_default=_UUID, nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("work_session_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("occurred_on", sa.Date(), nullable=False),
        sa.Column("category", sa.Text(), nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("is_demo", sa.Boolean(), server_default=_FALSE, nullable=False),
        *_timestamps(),
        sa.CheckConstraint(
            "category IN ('fuel', 'maintenance', 'depreciation', 'other')",
            name=op.f("ck_expense_records_category"),
        ),
        sa.CheckConstraint("amount >= 0", name=op.f("ck_expense_records_amount")),
        sa.CheckConstraint(
            "description IS NULL OR char_length(description) <= 500",
            name=op.f("ck_expense_records_description_length"),
        ),
        _user_fk("expense_records"),
        _work_session_fk("expense_records"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_expense_records")),
    )
    op.create_index(
        "ix_expense_records_user_id_occurred_on", "expense_records", ["user_id", sa.text("occurred_on DESC")]
    )
    op.create_index("ix_expense_records_user_id_category", "expense_records", ["user_id", "category"])
    op.create_index("ix_expense_records_work_session_id", "expense_records", ["work_session_id"])


def downgrade() -> None:
    op.drop_table("expense_records")
    op.drop_table("income_records")
    op.drop_table("work_sessions")
    op.drop_table("rider_profiles")
    # btree_gist is left in place, like the extensions of 0001.
