import uuid
from datetime import datetime

from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.auth.models import PasswordResetToken, RefreshToken

# ---- refresh tokens ----


async def add_refresh_token(
    session: AsyncSession,
    *,
    user_id: uuid.UUID,
    family_id: uuid.UUID,
    token_hash: str,
    expires_at: datetime,
) -> RefreshToken:
    row = RefreshToken(user_id=user_id, family_id=family_id, token_hash=token_hash, expires_at=expires_at)
    session.add(row)
    await session.flush()
    return row


async def get_refresh_token_for_update(session: AsyncSession, token_hash: str) -> RefreshToken | None:
    """Row-locks the token so two concurrent refreshes with the same token cannot both rotate it."""
    stmt = select(RefreshToken).where(RefreshToken.token_hash == token_hash).with_for_update()
    return (await session.execute(stmt)).scalar_one_or_none()


async def get_refresh_token(session: AsyncSession, token_hash: str) -> RefreshToken | None:
    stmt = select(RefreshToken).where(RefreshToken.token_hash == token_hash)
    return (await session.execute(stmt)).scalar_one_or_none()


async def revoke_family(session: AsyncSession, family_id: uuid.UUID, now: datetime) -> None:
    stmt = (
        update(RefreshToken)
        .where(RefreshToken.family_id == family_id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=now)
    )
    await session.execute(stmt)


async def revoke_all_for_user(session: AsyncSession, user_id: uuid.UUID, now: datetime) -> None:
    stmt = (
        update(RefreshToken)
        .where(RefreshToken.user_id == user_id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=now)
    )
    await session.execute(stmt)


# ---- password reset tokens ----


async def delete_unused_reset_tokens(session: AsyncSession, user_id: uuid.UUID) -> None:
    """A new request invalidates every earlier, still-unused reset token of the user."""
    stmt = delete(PasswordResetToken).where(
        PasswordResetToken.user_id == user_id, PasswordResetToken.used_at.is_(None)
    )
    await session.execute(stmt)


async def add_reset_token(
    session: AsyncSession, *, user_id: uuid.UUID, token_hash: str, expires_at: datetime
) -> PasswordResetToken:
    row = PasswordResetToken(user_id=user_id, token_hash=token_hash, expires_at=expires_at)
    session.add(row)
    await session.flush()
    return row


async def get_reset_token_for_update(session: AsyncSession, token_hash: str) -> PasswordResetToken | None:
    stmt = select(PasswordResetToken).where(PasswordResetToken.token_hash == token_hash).with_for_update()
    return (await session.execute(stmt)).scalar_one_or_none()
