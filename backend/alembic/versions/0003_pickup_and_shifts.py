"""Pickup Intelligence + Shift Simulator: restaurants, restaurant_time_stats, pickup_logs,
model_versions, pickup_predictions, shift_scenarios.

Revision ID: 0003
Revises: 0002
Create Date: 2026-11-09
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from geoalchemy2 import Geography
from sqlalchemy.dialects import postgresql

revision: str = "0003"
down_revision: str | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_NOW = sa.text("now()")
_UUID = sa.text("gen_random_uuid()")
_STAT = sa.Numeric(7, 3)


def _id() -> sa.Column:
    return sa.Column("id", postgresql.UUID(as_uuid=True), server_default=_UUID, nullable=False)


def _created() -> sa.Column:
    return sa.Column("created_at", sa.DateTime(timezone=True), server_default=_NOW, nullable=False)


def _updated() -> sa.Column:
    return sa.Column("updated_at", sa.DateTime(timezone=True), server_default=_NOW, nullable=False)


def _fk(table: str, column: str, target: str, ondelete: str) -> sa.ForeignKeyConstraint:
    return sa.ForeignKeyConstraint(
        [column], [f"{target}.id"], name=op.f(f"fk_{table}_{column}_{target}"), ondelete=ondelete
    )


def upgrade() -> None:
    op.create_table(
        "restaurants",
        _id(),
        sa.Column("source", sa.Text(), nullable=False),
        sa.Column("external_ref", sa.Text(), nullable=True),
        sa.Column("owner_user_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column(
            "location", Geography(geometry_type="POINT", srid=4326, spatial_index=False), nullable=True
        ),
        sa.Column("reference_da_id", sa.Text(), nullable=True),
        sa.Column("n_orders", sa.Integer(), nullable=True),
        sa.Column("median_min", _STAT, nullable=True),
        sa.Column("p25_min", _STAT, nullable=True),
        sa.Column("p75_min", _STAT, nullable=True),
        sa.Column("p90_min", _STAT, nullable=True),
        sa.Column("peak_hour", sa.SmallInteger(), nullable=True),
        sa.Column("data_availability", sa.Text(), nullable=True),
        sa.Column("dataset_version", sa.Text(), nullable=True),
        _created(),
        _updated(),
        sa.CheckConstraint(
            "source IN ('dataset_meituan', 'dataset_skip', 'user')", name=op.f("ck_restaurants_source")
        ),
        sa.CheckConstraint(
            "(source = 'user') = (owner_user_id IS NOT NULL)",
            name=op.f("ck_restaurants_owner_matches_source"),
        ),
        sa.CheckConstraint("char_length(name) BETWEEN 1 AND 120", name=op.f("ck_restaurants_name_length")),
        sa.CheckConstraint(
            "data_availability IN ('sufficient', 'limited', 'insufficient')",
            name=op.f("ck_restaurants_data_availability"),
        ),
        sa.CheckConstraint("n_orders IS NULL OR n_orders >= 0", name=op.f("ck_restaurants_n_orders")),
        sa.CheckConstraint(
            "peak_hour IS NULL OR peak_hour BETWEEN 0 AND 23", name=op.f("ck_restaurants_peak_hour")
        ),
        _fk("restaurants", "owner_user_id", "users", "CASCADE"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_restaurants")),
    )
    op.create_index(
        "uq_restaurants_source_external_ref",
        "restaurants",
        ["source", "external_ref"],
        unique=True,
        postgresql_where=sa.text("external_ref IS NOT NULL"),
    )
    op.create_index("ix_restaurants_owner_user_id", "restaurants", ["owner_user_id"])
    op.create_index("ix_restaurants_location", "restaurants", ["location"], postgresql_using="gist")
    op.create_index(
        "ix_restaurants_name_trgm",
        "restaurants",
        ["name"],
        postgresql_using="gin",
        postgresql_ops={"name": "gin_trgm_ops"},
    )

    op.create_table(
        "restaurant_time_stats",
        sa.Column("restaurant_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("day_type", sa.Text(), nullable=False),
        sa.Column("hour", sa.SmallInteger(), nullable=False),
        sa.Column("n_orders", sa.Integer(), nullable=False),
        sa.Column("median_min", _STAT, nullable=True),
        sa.Column("p25_min", _STAT, nullable=True),
        sa.Column("p75_min", _STAT, nullable=True),
        sa.Column("p90_min", _STAT, nullable=True),
        sa.Column("dataset_version", sa.Text(), nullable=False),
        sa.CheckConstraint(
            "day_type IN ('weekday', 'weekend')", name=op.f("ck_restaurant_time_stats_day_type")
        ),
        sa.CheckConstraint("hour BETWEEN 0 AND 23", name=op.f("ck_restaurant_time_stats_hour")),
        sa.CheckConstraint("n_orders >= 0", name=op.f("ck_restaurant_time_stats_n_orders")),
        _fk("restaurant_time_stats", "restaurant_id", "restaurants", "CASCADE"),
        sa.PrimaryKeyConstraint("restaurant_id", "day_type", "hour", name=op.f("pk_restaurant_time_stats")),
    )

    op.create_table(
        "pickup_logs",
        _id(),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("restaurant_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("arrived_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("picked_up_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        _created(),
        sa.CheckConstraint("picked_up_at >= arrived_at", name=op.f("ck_pickup_logs_picked_up_after_arrival")),
        sa.CheckConstraint(
            "picked_up_at - arrived_at <= interval '3 hours'", name=op.f("ck_pickup_logs_max_3_hours")
        ),
        sa.CheckConstraint(
            "notes IS NULL OR char_length(notes) <= 300", name=op.f("ck_pickup_logs_notes_length")
        ),
        _fk("pickup_logs", "user_id", "users", "CASCADE"),
        _fk("pickup_logs", "restaurant_id", "restaurants", "CASCADE"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_pickup_logs")),
    )
    op.create_index(
        "ix_pickup_logs_user_id_restaurant_id_arrived_at",
        "pickup_logs",
        ["user_id", "restaurant_id", sa.text("arrived_at DESC")],
    )

    op.create_table(
        "model_versions",
        _id(),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("version", sa.Text(), nullable=False),
        sa.Column("task", sa.Text(), nullable=False),
        sa.Column("dataset", sa.Text(), nullable=False),
        sa.Column("metrics", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("feature_schema", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("artifact_uri", sa.Text(), nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("trained_at", sa.DateTime(timezone=True), nullable=True),
        _created(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_model_versions")),
    )
    op.create_index("uq_model_versions_name_version", "model_versions", ["name", "version"], unique=True)
    op.create_index(
        "uq_model_versions_active_name",
        "model_versions",
        ["name"],
        unique=True,
        postgresql_where=sa.text("is_active"),
    )

    op.create_table(
        "pickup_predictions",
        _id(),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("restaurant_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("model_version_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("requested_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("input_features", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("predicted_minutes", sa.Numeric(6, 2), nullable=False),
        sa.Column("interval_low", sa.Numeric(6, 2), nullable=False),
        sa.Column("interval_high", sa.Numeric(6, 2), nullable=False),
        sa.Column("data_availability", sa.Text(), nullable=False),
        _created(),
        sa.CheckConstraint(
            "data_availability IN ('sufficient', 'limited', 'insufficient')",
            name=op.f("ck_pickup_predictions_data_availability"),
        ),
        sa.CheckConstraint(
            "interval_low <= predicted_minutes AND predicted_minutes <= interval_high",
            name=op.f("ck_pickup_predictions_interval"),
        ),
        _fk("pickup_predictions", "user_id", "users", "CASCADE"),
        _fk("pickup_predictions", "restaurant_id", "restaurants", "SET NULL"),
        _fk("pickup_predictions", "model_version_id", "model_versions", "RESTRICT"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_pickup_predictions")),
    )
    op.create_index(
        "ix_pickup_predictions_user_id_created_at",
        "pickup_predictions",
        ["user_id", sa.text("created_at DESC")],
    )
    op.create_index("ix_pickup_predictions_model_version_id", "pickup_predictions", ["model_version_id"])

    op.create_table(
        "shift_scenarios",
        _id(),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("start_time", sa.Time(), nullable=False),
        sa.Column("end_time", sa.Time(), nullable=False),
        sa.Column("duration_minutes", sa.Integer(), nullable=False),
        sa.Column("planned_weekday", sa.SmallInteger(), nullable=True),
        sa.Column("assumptions", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("estimation_method", sa.Text(), nullable=False),
        sa.Column("estimated_revenue", sa.Numeric(12, 2), nullable=False),
        sa.Column("estimated_expenses", sa.Numeric(12, 2), nullable=False),
        sa.Column("estimated_net_profit", sa.Numeric(12, 2), nullable=False),
        sa.Column("estimate_low", sa.Numeric(12, 2), nullable=True),
        sa.Column("estimate_high", sa.Numeric(12, 2), nullable=True),
        sa.Column("estimate_details", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("model_version_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("actual_work_session_id", postgresql.UUID(as_uuid=True), nullable=True),
        _created(),
        _updated(),
        sa.CheckConstraint("char_length(name) BETWEEN 1 AND 60", name=op.f("ck_shift_scenarios_name_length")),
        sa.CheckConstraint(
            "duration_minutes BETWEEN 30 AND 960", name=op.f("ck_shift_scenarios_duration_minutes")
        ),
        sa.CheckConstraint(
            "planned_weekday IS NULL OR planned_weekday BETWEEN 0 AND 6",
            name=op.f("ck_shift_scenarios_planned_weekday"),
        ),
        sa.CheckConstraint(
            "estimation_method IN ('assumption', 'historical', 'ml')",
            name=op.f("ck_shift_scenarios_estimation_method"),
        ),
        sa.CheckConstraint(
            "estimation_method = 'ml' OR model_version_id IS NULL",
            name=op.f("ck_shift_scenarios_model_only_for_ml"),
        ),
        sa.CheckConstraint(
            "estimate_low IS NULL OR estimate_high IS NULL OR estimate_low <= estimate_high",
            name=op.f("ck_shift_scenarios_estimate_range"),
        ),
        _fk("shift_scenarios", "user_id", "users", "CASCADE"),
        _fk("shift_scenarios", "model_version_id", "model_versions", "RESTRICT"),
        _fk("shift_scenarios", "actual_work_session_id", "work_sessions", "SET NULL"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_shift_scenarios")),
    )
    op.create_index(
        "ix_shift_scenarios_user_id_created_at", "shift_scenarios", ["user_id", sa.text("created_at DESC")]
    )


def downgrade() -> None:
    op.drop_table("shift_scenarios")
    op.drop_table("pickup_predictions")
    op.drop_table("model_versions")
    op.drop_table("pickup_logs")
    op.drop_table("restaurant_time_stats")
    op.drop_table("restaurants")
