"""Rate limiting (docs/SYSTEM_ARCHITECTURE.md §5).

Built on `limits` (the library slowapi wraps) and used through FastAPI dependencies, so a limit can
also be keyed by a value from the request body (login per e-mail). The storage comes from
`RATE_LIMIT_STORAGE_URL`: `memory://` (default) counts per process; `redis://host:6379/0` (Redis or
Valkey) shares the counts between workers and instances (Phase 7 production runs 2 workers).

If the shared store cannot be reached, limited endpoints answer 503 instead of skipping the limit
(fail closed: an outage must not switch off the login brute-force protection).
"""

import contextlib
import math
import time
from collections.abc import Callable, Coroutine
from typing import Any

import structlog
from fastapi import Request
from limits import RateLimitItem, parse
from limits.aio.storage import Storage
from limits.aio.strategies import MovingWindowRateLimiter
from limits.storage import storage_from_string

from app.core.config import Settings
from app.core.errors import AppError, ServiceUnavailableError, UnauthorizedError
from app.core.security import decode_access_token

log = structlog.get_logger("rate_limit")


class RateLimitedError(AppError):
    status_code = 429
    code = "rate_limited"
    message = "Too many requests, try again later"


class RateLimitUnavailableError(ServiceUnavailableError):
    code = "rate_limit_unavailable"
    message = "Service temporarily unavailable, try again later"


def create_storage(url: str) -> Storage:
    """`memory://` or `redis://…` (also `rediss://`) -> the matching async `limits` storage."""
    scheme = url.split("://", 1)[0].lower()
    if scheme == "memory":
        storage = storage_from_string("async+memory://")
    elif scheme in ("redis", "rediss"):
        # redis-py's asyncio client (MIT); it also talks to Valkey, which production runs.
        storage = storage_from_string(f"async+{url}", implementation="redispy")
    else:
        raise ValueError(f"RATE_LIMIT_STORAGE_URL must be memory:// or redis://…, not {scheme}://")
    assert isinstance(storage, Storage)
    return storage


class RateLimiter:
    def __init__(self, enabled: bool, storage_url: str = "memory://") -> None:
        self.enabled = enabled
        self.storage = create_storage(storage_url)
        self._limiter = MovingWindowRateLimiter(self.storage)

    async def hit(self, limit: str, scope: str, key: str) -> None:
        """Count one request for (scope, key); raise 429 with Retry-After once over the limit."""
        if not self.enabled:
            return
        item = parse(limit)
        try:
            allowed = await self._limiter.hit(item, scope, key)
            if allowed:
                return
            retry_after = await self._retry_after(item, scope, key)
        except Exception as exc:
            log.error("rate_limit_storage_error", error=type(exc).__name__, scope=scope)
            raise RateLimitUnavailableError() from exc
        raise RateLimitedError(headers={"Retry-After": str(retry_after)})

    async def _retry_after(self, item: RateLimitItem, scope: str, key: str) -> int:
        reset_at = (await self._limiter.get_window_stats(item, scope, key)).reset_time
        return max(1, math.ceil(reset_at - time.time()))

    async def check(self) -> bool:
        """True when the storage answers (startup log and readiness)."""
        try:
            return bool(await self.storage.check())
        except Exception:
            return False


def client_ip(request: Request) -> str:
    # Behind Caddy (Phase 7), uvicorn's proxy-headers middleware has already replaced the peer with
    # the X-Forwarded-For client, but only for peers listed in FORWARDED_ALLOW_IPS (Caddy's fixed
    # address in compose.prod.yml). Any other peer's X-Forwarded-For is ignored, so it cannot be
    # spoofed to dodge the per-IP limits.
    return request.client.host if request.client else "unknown"


def get_limiter(request: Request) -> RateLimiter:
    return request.app.state.rate_limiter


def per_ip(scope: str, setting: str) -> Callable[[Request], Coroutine[Any, Any, None]]:
    """Dependency: `setting` names the Settings attribute that holds the limit string."""

    async def _dependency(request: Request) -> None:
        settings: Settings = request.app.state.settings
        await get_limiter(request).hit(getattr(settings, setting), scope, client_ip(request))

    return _dependency


async def default_limit(request: Request) -> None:
    """General limit: per user when the bearer token is valid, otherwise per client IP."""
    settings: Settings = request.app.state.settings
    key = f"ip:{client_ip(request)}"
    auth = request.headers.get("authorization", "")
    if auth[:7].lower() == "bearer ":
        with contextlib.suppress(UnauthorizedError):  # an invalid token: the endpoint answers 401
            key = f"user:{decode_access_token(auth[7:], settings).user_id}"
    await get_limiter(request).hit(settings.rate_limit_default, "default", key)
