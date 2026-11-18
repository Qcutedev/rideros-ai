"""Remove Pickup Intelligence: drop pickup_predictions, pickup_logs, restaurant_time_stats, restaurants.

The feature was removed from the app (docs/HANDOFF.md §4.20). `model_versions` stays: RoadContext
records its photo classifier there. The pickup model's own rows go, unless something still points at
them. Downgrade brings the empty tables back (schema as in 0003); the dropped rows are not restored.

Revision ID: 0006
Revises: 0005
Create Date: 2026-11-18
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from geoalchemy2 import Geography
from sqlalchemy.dialects import postgresql

revision: str = "0006"
down_revision: str | None = "0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_NOW = sa.text("now()")
_UUID = sa.text("gen_random_uuid()")
_STAT = sa.Numeric(7, 3)
PICKUP_MODEL_NAME = "pickup_o2p"


def upgrade() -> None:
    op.drop_table("pickup_predictions")
    op.drop_table("pickup_logs")
    op.drop_table("restaurant_time_stats")
    op.drop_table("restaurants")
    op.execute(
        sa.text(
            "DELETE FROM model_versions WHERE name = :name AND id NOT IN "
            "(SELECT model_version_id FROM shift_scenarios WHERE model_version_id IS NOT NULL)"
        ).bindparams(name=PICKUP_MODEL_NAME)
    )


def _id() -> sa.Column:
    return sa.Column("id", postgresql.UUID(as_uuid=True), server_default=_UUID, nullable=False)


def _created() -> sa.Column:
    return sa.Column("created_at", sa.DateTime(timezone=True), server_default=_NOW, nullable=False)


def _fk(table: str, column: str, target: str, ondelete: str) -> sa.ForeignKeyConstraint:
    return sa.ForeignKeyConstraint(
        [column], [f"{target}.id"], name=op.f(f"fk_{table}_{column}_{target}"), ondelete=ondelete
    )


def downgrade() -> None:
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
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=_NOW, nullable=False),
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
