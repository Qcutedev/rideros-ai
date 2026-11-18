import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, CheckConstraint, ForeignKey, Index, Numeric, Text, func, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, created_at_column, updated_at_column, uuid_pk

USER_ROLES = ("rider", "admin")
VEHICLE_TYPES = ("motorcycle", "ev_motorcycle", "bicycle", "car", "other")
DEFAULT_TIMEZONE = "Asia/Bangkok"
DEFAULT_CURRENCY = "THB"


class User(Base):
    __tablename__ = "users"
    __table_args__ = (
        CheckConstraint("role IN ('rider', 'admin')", name="role"),
        CheckConstraint("char_length(display_name) BETWEEN 1 AND 80", name="display_name_length"),
        CheckConstraint("email = lower(email)", name="email_lowercase"),
        Index("uq_users_email_lower", func.lower(text("email")), unique=True),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    email: Mapped[str] = mapped_column(Text, nullable=False)
    password_hash: Mapped[str] = mapped_column(Text, nullable=False)
    display_name: Mapped[str] = mapped_column(Text, nullable=False)
    role: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'rider'"))
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()


class RiderProfile(Base):
    """1:1 with users. A user without a row gets the defaults (see users.service.get_rider_profile)."""

    __tablename__ = "rider_profiles"
    __table_args__ = (
        CheckConstraint(
            "vehicle_type IN ('motorcycle', 'ev_motorcycle', 'bicycle', 'car', 'other')", name="vehicle_type"
        ),
        CheckConstraint("fuel_km_per_liter IS NULL OR fuel_km_per_liter > 0", name="fuel_km_per_liter"),
        CheckConstraint(
            "fuel_price_per_liter IS NULL OR fuel_price_per_liter >= 0", name="fuel_price_per_liter"
        ),
        CheckConstraint(
            "depreciation_per_km IS NULL OR depreciation_per_km >= 0", name="depreciation_per_km"
        ),
        CheckConstraint("daily_goal IS NULL OR daily_goal > 0", name="daily_goal"),
        CheckConstraint("char_length(timezone) BETWEEN 1 AND 64", name="timezone_length"),
        CheckConstraint("currency ~ '^[A-Z]{3}$'", name="currency_format"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    vehicle_type: Mapped[str | None] = mapped_column(Text)
    fuel_km_per_liter: Mapped[Decimal | None] = mapped_column(Numeric(6, 2))
    fuel_price_per_liter: Mapped[Decimal | None] = mapped_column(Numeric(8, 2))
    depreciation_per_km: Mapped[Decimal | None] = mapped_column(Numeric(8, 4))
    # Net-profit target for one day (Home progress ring); NULL = no goal.
    daily_goal: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    # IANA name, validated against tzdata in the service (the DB only bounds the length).
    timezone: Mapped[str] = mapped_column(Text, nullable=False, server_default=text(f"'{DEFAULT_TIMEZONE}'"))
    currency: Mapped[str] = mapped_column(Text, nullable=False, server_default=text(f"'{DEFAULT_CURRENCY}'"))
    created_at: Mapped[datetime] = created_at_column()
    updated_at: Mapped[datetime] = updated_at_column()
