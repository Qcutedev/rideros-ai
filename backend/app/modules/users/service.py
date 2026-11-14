"""Account (/me) and rider profile use cases."""

import uuid
from dataclasses import dataclass
from zoneinfo import ZoneInfo

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.errors import AppError, ForbiddenError
from app.core.security import verify_password_async
from app.core.timezones import get_zone, is_valid_timezone
from app.modules.road import service as road_service
from app.modules.users import repository as users
from app.modules.users.models import DEFAULT_CURRENCY, DEFAULT_TIMEZONE, User
from app.modules.users.schemas import RiderProfileIn, RiderProfileOut, UserUpdate

log = structlog.get_logger(__name__)


class InvalidTimezoneError(AppError):
    code = "invalid_timezone"
    message = "Unknown time zone; use an IANA name such as Asia/Bangkok"


async def update_me(session: AsyncSession, user: User, body: UserUpdate) -> User:
    for field, value in body.changes().items():
        setattr(user, field, value)
    await session.commit()
    await session.refresh(user)
    return user


async def delete_me(session: AsyncSession, settings: Settings, user: User, password: str) -> None:
    """PDPA account deletion. Re-checks the password so a leaked access token alone cannot do it.

    Road reports cascade with the user; the shared incidents they belonged to get their counters
    recomputed (and are removed when no report is left), and the report photos are deleted.
    """
    if not await verify_password_async(password, user.password_hash):
        raise ForbiddenError("Password is incorrect", code="invalid_password")
    user_id = user.id
    cleanup = await road_service.prepare_user_deletion(session, user_id)
    await users.delete_user(session, user_id)
    await road_service.finish_user_deletion(session, settings, cleanup)
    await session.commit()
    road_service.delete_images(settings, cleanup.image_keys)
    log.info("user_deleted", user_id=str(user_id))


def _default_profile() -> RiderProfileOut:
    return RiderProfileOut(
        vehicle_type=None,
        fuel_km_per_liter=None,
        fuel_price_per_liter=None,
        depreciation_per_km=None,
        timezone=DEFAULT_TIMEZONE,
        currency=DEFAULT_CURRENCY,
        is_configured=False,
        updated_at=None,
    )


async def get_rider_profile(session: AsyncSession, user_id: uuid.UUID) -> RiderProfileOut:
    row = await users.get_profile(session, user_id)
    if row is None:
        return _default_profile()
    return RiderProfileOut(
        vehicle_type=row.vehicle_type,  # type: ignore[arg-type]  # DB CHECK keeps it in the Literal
        fuel_km_per_liter=row.fuel_km_per_liter,
        fuel_price_per_liter=row.fuel_price_per_liter,
        depreciation_per_km=row.depreciation_per_km,
        timezone=row.timezone,
        currency=row.currency,
        is_configured=True,
        updated_at=row.updated_at,
    )


async def put_rider_profile(
    session: AsyncSession, user_id: uuid.UUID, body: RiderProfileIn
) -> RiderProfileOut:
    if not is_valid_timezone(body.timezone):
        raise InvalidTimezoneError(details=[{"loc": ["body", "timezone"], "msg": "unknown IANA time zone"}])
    await users.upsert_profile(session, user_id, body.model_dump())
    await session.commit()
    return await get_rider_profile(session, user_id)


@dataclass(frozen=True, slots=True)
class Locale:
    zone: ZoneInfo
    currency: str

    @property
    def timezone(self) -> str:
        return self.zone.key


async def get_locale(session: AsyncSession, user_id: uuid.UUID) -> Locale:
    """Time zone + currency for date-based reports: the saved profile, or the defaults."""
    row = await users.get_locale(session, user_id)
    name, currency = row if row is not None else (DEFAULT_TIMEZONE, DEFAULT_CURRENCY)
    return Locale(get_zone(name if is_valid_timezone(name) else DEFAULT_TIMEZONE), currency)
