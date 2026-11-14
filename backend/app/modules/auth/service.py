"""Auth use cases: register, login, refresh (rotation + reuse detection), logout, password reset (D5)."""

import uuid
from datetime import UTC, datetime, timedelta

import structlog
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.errors import AppError, ConflictError, ServiceUnavailableError, UnauthorizedError
from app.core.security import (
    create_access_token,
    generate_opaque_token,
    hash_password_async,
    hash_token,
    password_problem,
    verify_password_async,
)
from app.modules.auth import repository as tokens
from app.modules.auth.schemas import TokenPair
from app.modules.users import repository as users
from app.modules.users.models import User

log = structlog.get_logger(__name__)


class WeakPasswordError(AppError):
    code = "weak_password"


def _now() -> datetime:
    return datetime.now(UTC)


async def register(session: AsyncSession, *, email: str, password: str, display_name: str) -> User:
    if problem := password_problem(password, email):
        raise WeakPasswordError(problem, details=[{"loc": ["body", "password"], "msg": problem}])
    if await users.get_by_email(session, email) is not None:
        raise ConflictError("An account with this e-mail already exists", code="email_taken")
    try:
        user = await users.add(
            session, email=email, password_hash=await hash_password_async(password), display_name=display_name
        )
        await session.commit()
    except IntegrityError as exc:  # concurrent register with the same e-mail
        await session.rollback()
        raise ConflictError("An account with this e-mail already exists", code="email_taken") from exc
    log.info("user_registered", user_id=str(user.id))
    return user


async def _issue_pair(
    session: AsyncSession, user_id: uuid.UUID, family_id: uuid.UUID, settings: Settings, now: datetime
) -> TokenPair:
    refresh = generate_opaque_token()
    expires_at = now + timedelta(days=settings.refresh_token_ttl_days)
    await tokens.add_refresh_token(
        session, user_id=user_id, family_id=family_id, token_hash=hash_token(refresh), expires_at=expires_at
    )
    return TokenPair(
        access_token=create_access_token(user_id, settings, now),
        refresh_token=refresh,
        expires_in=settings.access_token_ttl_minutes * 60,
        refresh_expires_at=expires_at,
    )


async def login(session: AsyncSession, *, email: str, password: str, settings: Settings) -> TokenPair:
    user = await users.get_by_email(session, email)
    # verify_password_async(…, None) still runs Argon2 so unknown e-mails take the same time.
    valid = await verify_password_async(password, user.password_hash if user else None)
    if not valid or user is None or not user.is_active:
        raise UnauthorizedError("E-mail or password is incorrect", code="invalid_credentials")
    pair = await _issue_pair(session, user.id, uuid.uuid4(), settings, _now())
    await session.commit()
    log.info("user_logged_in", user_id=str(user.id))
    return pair


async def refresh(session: AsyncSession, *, refresh_token: str, settings: Settings) -> TokenPair:
    now = _now()
    row = await tokens.get_refresh_token_for_update(session, hash_token(refresh_token))
    if row is None:
        raise UnauthorizedError("Invalid refresh token", code="invalid_refresh_token")

    if row.revoked_at is not None:
        # A revoked token (already rotated, or logged out) was presented again. Assume it was
        # stolen and revoke the whole session family, including the newest token issued from it.
        await tokens.revoke_family(session, row.family_id, now)
        await session.commit()
        log.warning("refresh_token_reuse_detected", user_id=str(row.user_id), family_id=str(row.family_id))
        raise UnauthorizedError("Refresh token has been revoked", code="refresh_token_revoked")

    if row.expires_at <= now:
        raise UnauthorizedError("Refresh token expired", code="refresh_token_expired")

    user = await users.get_by_id(session, row.user_id)
    if user is None or not user.is_active:
        raise UnauthorizedError("Invalid refresh token", code="invalid_refresh_token")

    row.revoked_at = now
    pair = await _issue_pair(session, row.user_id, row.family_id, settings, now)
    await session.commit()
    return pair


async def logout(session: AsyncSession, *, refresh_token: str) -> None:
    """Ends the session the token belongs to. Unknown or already revoked tokens are a no-op."""
    row = await tokens.get_refresh_token(session, hash_token(refresh_token))
    if row is None:
        return
    await tokens.revoke_family(session, row.family_id, _now())
    await session.commit()
    log.info("user_logged_out", user_id=str(row.user_id))


def _require_reset_enabled(settings: Settings) -> None:
    if not settings.password_reset_enabled:
        raise ServiceUnavailableError("Password reset is not available", code="password_reset_unavailable")


async def forgot_password(session: AsyncSession, *, email: str, settings: Settings) -> None:
    """Always succeeds from the caller's view, so it never reveals whether an account exists."""
    _require_reset_enabled(settings)
    user = await users.get_by_email(session, email)
    if user is None or not user.is_active:
        return

    now = _now()
    token = generate_opaque_token()
    await tokens.delete_unused_reset_tokens(session, user.id)
    await tokens.add_reset_token(
        session,
        user_id=user.id,
        token_hash=hash_token(token),
        expires_at=now + timedelta(minutes=settings.password_reset_ttl_minutes),
    )
    await session.commit()

    # D5 development mode: the only delivery channel is the dev log. password_reset_enabled is
    # False in production with no provider, so this line cannot run there.
    if settings.email_provider == "none" and not settings.is_production:
        log.warning(
            "DEV ONLY password reset link (no e-mail provider configured)",
            user_id=str(user.id),
            reset_link=f"{settings.password_reset_url_base}?token={token}",
        )


async def reset_password(session: AsyncSession, *, token: str, new_password: str, settings: Settings) -> None:
    _require_reset_enabled(settings)
    now = _now()
    row = await tokens.get_reset_token_for_update(session, hash_token(token))
    if row is None or row.used_at is not None or row.expires_at <= now:
        raise AppError("Reset link is invalid or has expired", code="invalid_reset_token")

    user = await users.get_by_id(session, row.user_id)
    if user is None or not user.is_active:
        raise AppError("Reset link is invalid or has expired", code="invalid_reset_token")
    if problem := password_problem(new_password, user.email):
        raise WeakPasswordError(problem, details=[{"loc": ["body", "new_password"], "msg": problem}])

    user.password_hash = await hash_password_async(new_password)
    row.used_at = now
    await tokens.revoke_all_for_user(session, user.id, now)  # sign out every device
    await session.commit()
    log.info("password_reset_completed", user_id=str(user.id))
