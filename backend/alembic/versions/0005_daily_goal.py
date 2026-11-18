"""Rider profile: daily net-profit goal (rider_profiles.daily_goal).

Revision ID: 0005
Revises: 0004
Create Date: 2026-11-17
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0005"
down_revision: str | None = "0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("rider_profiles", sa.Column("daily_goal", sa.Numeric(12, 2), nullable=True))
    op.create_check_constraint(
        op.f("ck_rider_profiles_daily_goal"), "rider_profiles", "daily_goal IS NULL OR daily_goal > 0"
    )


def downgrade() -> None:
    op.drop_constraint(op.f("ck_rider_profiles_daily_goal"), "rider_profiles", type_="check")
    op.drop_column("rider_profiles", "daily_goal")
