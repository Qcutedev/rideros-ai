"""Password hashing (Argon2id), access JWTs and opaque tokens.

- Access token: HS256 JWT with `sub`, `type="access"`, `iat`, `exp`, `jti`. All are required on decode.
- Refresh / password-reset tokens: 256-bit random, URL-safe. Only their SHA-256 hash is stored.
"""

import hashlib
import secrets
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from functools import lru_cache
from pathlib import Path

import jwt
from pwdlib import PasswordHash
from pwdlib.hashers.argon2 import Argon2Hasher

from app.core.config import Settings
from app.core.errors import UnauthorizedError

ACCESS_TOKEN_TYPE = "access"
PASSWORD_MIN_LENGTH = 8
PASSWORD_MAX_LENGTH = 128  # bounds Argon2 work per request

_password_hash = PasswordHash((Argon2Hasher(),))
# Verified against when the e-mail is unknown, so login takes the same time either way.
_DUMMY_HASH = _password_hash.hash(secrets.token_urlsafe(16))


def hash_password(password: str) -> str:
    return _password_hash.hash(password)


def verify_password(password: str, password_hash: str | None) -> bool:
    if password_hash is None:
        _password_hash.verify(password, _DUMMY_HASH)
        return False
    return _password_hash.verify(password, password_hash)


@lru_cache
def _common_passwords() -> frozenset[str]:
    path = Path(__file__).with_name("common_passwords.txt")
    lines = path.read_text(encoding="utf-8").splitlines()
    return frozenset(line.strip().lower() for line in lines if line.strip() and not line.startswith("#"))


def password_problem(password: str, email: str | None = None) -> str | None:
    """Return a human-readable reason the password is rejected, or None if it is acceptable."""
    if len(password) < PASSWORD_MIN_LENGTH:
        return f"Password must be at least {PASSWORD_MIN_LENGTH} characters"
    if len(password) > PASSWORD_MAX_LENGTH:
        return f"Password must be at most {PASSWORD_MAX_LENGTH} characters"
    lowered = password.lower()
    if lowered in _common_passwords():
        return "Password is too common"
    if email and lowered == email.split("@", 1)[0].lower():
        return "Password must not be the same as your e-mail name"
    return None


def generate_opaque_token() -> str:
    return secrets.token_urlsafe(32)  # 256 bits


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


@dataclass(frozen=True, slots=True)
class AccessClaims:
    user_id: uuid.UUID
    issued_at: datetime
    expires_at: datetime


def create_access_token(user_id: uuid.UUID, settings: Settings, now: datetime | None = None) -> str:
    now = now or datetime.now(UTC)
    payload = {
        "sub": str(user_id),
        "type": ACCESS_TOKEN_TYPE,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=settings.access_token_ttl_minutes)).timestamp()),
        "jti": uuid.uuid4().hex,
    }
    return jwt.encode(payload, settings.jwt_secret.get_secret_value(), algorithm=settings.jwt_algorithm)


def decode_access_token(token: str, settings: Settings) -> AccessClaims:
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret.get_secret_value(),
            algorithms=[settings.jwt_algorithm],
            options={"require": ["sub", "type", "iat", "exp", "jti"]},
        )
    except jwt.ExpiredSignatureError as exc:
        raise UnauthorizedError("Access token expired", code="token_expired") from exc
    except jwt.PyJWTError as exc:
        raise UnauthorizedError("Invalid access token", code="invalid_token") from exc

    if payload.get("type") != ACCESS_TOKEN_TYPE:
        raise UnauthorizedError("Invalid access token", code="invalid_token")
    try:
        user_id = uuid.UUID(str(payload["sub"]))
    except ValueError as exc:
        raise UnauthorizedError("Invalid access token", code="invalid_token") from exc
    return AccessClaims(
        user_id=user_id,
        issued_at=datetime.fromtimestamp(payload["iat"], UTC),
        expires_at=datetime.fromtimestamp(payload["exp"], UTC),
    )
