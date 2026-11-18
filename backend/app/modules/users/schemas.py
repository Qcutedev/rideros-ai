import uuid
from datetime import datetime
from decimal import Decimal
from typing import Annotated, ClassVar, Literal

from pydantic import BaseModel, ConfigDict, Field, StringConstraints

from app.core.schemas import PatchModel, StrictModel
from app.core.security import PASSWORD_MAX_LENGTH
from app.modules.users.models import DEFAULT_CURRENCY, DEFAULT_TIMEZONE

DisplayName = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=80)]
VehicleType = Literal["motorcycle", "ev_motorcycle", "bicycle", "car", "other"]
Currency = Literal["THB"]  # only THB until multi-currency is designed


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: str
    display_name: str
    role: str
    created_at: datetime


class UserUpdate(PatchModel):
    """E-mail changes need verification and are not supported yet; password changes use reset."""

    non_nullable: ClassVar[frozenset[str]] = frozenset({"display_name"})

    display_name: DisplayName | None = None


class DeleteAccountRequest(StrictModel):
    password: Annotated[str, Field(min_length=1, max_length=PASSWORD_MAX_LENGTH * 2)]


class RiderProfileIn(StrictModel):
    """PUT body: replaces the whole profile. Omitted optional fields become null / the default."""

    vehicle_type: VehicleType | None = None
    fuel_km_per_liter: Annotated[Decimal, Field(gt=0, max_digits=6, decimal_places=2)] | None = None
    fuel_price_per_liter: Annotated[Decimal, Field(ge=0, max_digits=8, decimal_places=2)] | None = None
    depreciation_per_km: Annotated[Decimal, Field(ge=0, max_digits=8, decimal_places=4)] | None = None
    daily_goal: Annotated[Decimal, Field(gt=0, max_digits=12, decimal_places=2)] | None = None
    timezone: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=64)] = (
        DEFAULT_TIMEZONE
    )
    currency: Currency = DEFAULT_CURRENCY


class RiderProfileOut(BaseModel):
    vehicle_type: VehicleType | None
    fuel_km_per_liter: Decimal | None
    fuel_price_per_liter: Decimal | None
    depreciation_per_km: Decimal | None
    daily_goal: Decimal | None = Field(description="Net-profit target for one day; null = no goal")
    timezone: str
    currency: str
    is_configured: bool = Field(description="False until the rider saves the profile once (defaults shown)")
    updated_at: datetime | None
