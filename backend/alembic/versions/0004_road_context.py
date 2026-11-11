"""RoadContext: road_incidents, incident_reports.

Revision ID: 0004
Revises: 0003
Create Date: 2026-11-12
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from geoalchemy2 import Geography
from sqlalchemy.dialects import postgresql

revision: str = "0004"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_NOW = sa.text("now()")
_CATEGORIES = "'flooding', 'road_damage', 'road_closure', 'road_obstacle', 'traffic_incident'"


def _point() -> Geography:
    return Geography(geometry_type="POINT", srid=4326, spatial_index=False)


def _fk(table: str, column: str, target: str, ondelete: str) -> sa.ForeignKeyConstraint:
    return sa.ForeignKeyConstraint(
        [column], [f"{target}.id"], name=op.f(f"fk_{table}_{column}_{target}"), ondelete=ondelete
    )


def upgrade() -> None:
    op.create_table(
        "road_incidents",
        sa.Column(
            "id", postgresql.UUID(as_uuid=True), server_default=sa.text("gen_random_uuid()"), nullable=False
        ),
        sa.Column("category", sa.Text(), nullable=False),
        sa.Column("status", sa.Text(), server_default=sa.text("'unverified'"), nullable=False),
        sa.Column("location", _point(), nullable=False),
        sa.Column("first_reported_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_reported_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("report_count", sa.Integer(), server_default=sa.text("0"), nullable=False),
        sa.Column("distinct_reporters", sa.Integer(), server_default=sa.text("0"), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("status_changed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=_NOW, nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=_NOW, nullable=False),
        sa.CheckConstraint(f"category IN ({_CATEGORIES})", name=op.f("ck_road_incidents_category")),
        sa.CheckConstraint(
            "status IN ('unverified', 'corroborated', 'resolved', 'expired', 'rejected')",
            name=op.f("ck_road_incidents_status"),
        ),
        sa.CheckConstraint("report_count >= 0", name=op.f("ck_road_incidents_report_count")),
        sa.CheckConstraint("distinct_reporters >= 0", name=op.f("ck_road_incidents_distinct_reporters")),
        sa.CheckConstraint(
            "last_reported_at >= first_reported_at", name=op.f("ck_road_incidents_report_order")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_road_incidents")),
    )
    op.create_index("ix_road_incidents_location", "road_incidents", ["location"], postgresql_using="gist")
    op.create_index("ix_road_incidents_status_expires_at", "road_incidents", ["status", "expires_at"])
    op.create_index(
        "ix_road_incidents_category_last_reported_at",
        "road_incidents",
        ["category", sa.text("last_reported_at DESC")],
    )

    op.create_table(
        "incident_reports",
        sa.Column(
            "id", postgresql.UUID(as_uuid=True), server_default=sa.text("gen_random_uuid()"), nullable=False
        ),
        sa.Column("incident_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("report_type", sa.Text(), nullable=False),
        sa.Column("category", sa.Text(), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("location", _point(), nullable=True),
        sa.Column("image_key", sa.Text(), nullable=True),
        sa.Column("ai_status", sa.Text(), server_default=sa.text("'none'"), nullable=False),
        sa.Column("ai_label", sa.Text(), nullable=True),
        sa.Column("ai_confidence", sa.Numeric(4, 3), nullable=True),
        sa.Column("ai_model_version_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=_NOW, nullable=False),
        sa.CheckConstraint(f"category IN ({_CATEGORIES})", name=op.f("ck_incident_reports_category")),
        sa.CheckConstraint(
            "report_type IN ('report', 'still_present', 'cleared')",
            name=op.f("ck_incident_reports_report_type"),
        ),
        sa.CheckConstraint(
            "ai_status IN ('none', 'pending', 'done', 'failed')", name=op.f("ck_incident_reports_ai_status")
        ),
        sa.CheckConstraint(
            "ai_confidence IS NULL OR ai_confidence BETWEEN 0 AND 1",
            name=op.f("ck_incident_reports_ai_confidence"),
        ),
        sa.CheckConstraint(
            "description IS NULL OR char_length(description) <= 500",
            name=op.f("ck_incident_reports_description_length"),
        ),
        sa.CheckConstraint(
            "(report_type = 'report') = (location IS NOT NULL)",
            name=op.f("ck_incident_reports_location_on_reports"),
        ),
        sa.CheckConstraint(
            "report_type = 'report' OR (image_key IS NULL AND description IS NULL)",
            name=op.f("ck_incident_reports_confirmation_has_no_content"),
        ),
        _fk("incident_reports", "incident_id", "road_incidents", "CASCADE"),
        _fk("incident_reports", "user_id", "users", "CASCADE"),
        _fk("incident_reports", "ai_model_version_id", "model_versions", "SET NULL"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_incident_reports")),
    )
    op.create_index(
        "uq_incident_reports_report_per_user",
        "incident_reports",
        ["incident_id", "user_id"],
        unique=True,
        postgresql_where=sa.text("report_type = 'report'"),
    )
    op.create_index(
        "uq_incident_reports_confirmation_per_user",
        "incident_reports",
        ["incident_id", "user_id"],
        unique=True,
        postgresql_where=sa.text("report_type IN ('still_present', 'cleared')"),
    )
    op.create_index(
        "ix_incident_reports_incident_id_created_at", "incident_reports", ["incident_id", "created_at"]
    )
    op.create_index(
        "ix_incident_reports_user_id_created_at", "incident_reports", ["user_id", sa.text("created_at DESC")]
    )


def downgrade() -> None:
    op.drop_table("incident_reports")
    op.drop_table("road_incidents")
