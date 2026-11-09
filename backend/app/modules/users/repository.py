import uuid
from typing import Any

from sqlalchemy import delete, func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.users.models import RiderProfile, User


async def get_by_id(session: AsyncSession, user_id: uuid.UUID) -> User | None:
    return await session.get(User, user_id)


async def get_by_email(session: AsyncSession, email: str) -> User | None:
    stmt = select(User).where(func.lower(User.email) == email.lower())
    return (await session.execute(stmt)).scalar_one_or_none()


async def add(session: AsyncSession, *, email: str, password_hash: str, display_name: str) -> User:
    user = User(email=email.lower(), password_hash=password_hash, display_name=display_name)
    session.add(user)
    await session.flush()
    await session.refresh(user)
    return user


async def delete_user(session: AsyncSession, user_id: uuid.UUID) -> None:
    """Every table that holds the user's data references users ON DELETE CASCADE."""
    await session.execute(delete(User).where(User.id == user_id))


# ---- rider profile ----


async def get_profile(session: AsyncSession, user_id: uuid.UUID) -> RiderProfile | None:
    return await session.get(RiderProfile, user_id)


async def get_locale(session: AsyncSession, user_id: uuid.UUID) -> tuple[str, str] | None:
    """(timezone, currency) of the profile, or None when the rider has not saved one."""
    stmt = select(RiderProfile.timezone, RiderProfile.currency).where(RiderProfile.user_id == user_id)
    row = (await session.execute(stmt)).one_or_none()
    return None if row is None else (row[0], row[1])


async def upsert_profile(session: AsyncSession, user_id: uuid.UUID, values: dict[str, Any]) -> RiderProfile:
    stmt = (
        insert(RiderProfile)
        .values(user_id=user_id, **values)
        .on_conflict_do_update(
            index_elements=[RiderProfile.user_id], set_={**values, "updated_at": func.now()}
        )
        .returning(RiderProfile)
        .execution_options(populate_existing=True)
    )
    return (await session.execute(stmt)).scalar_one()
