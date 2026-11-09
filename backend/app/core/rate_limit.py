"""Rate limiting (docs/SYSTEM_ARCHITECTURE.md §5).

Built on `limits` (the library slowapi wraps) and used through FastAPI dependencies, so a limit can
also be keyed by a value from the request body (login per e-mail). Storage is in memory, i.e. per
process; a shared store (Redis) is needed before running more than one instance.
"""

import contextlib
import math
import time
from collections.abc import Callable, Coroutine
from typing import Any

from fastapi import Request
from limits import parse
from limits.storage import MemoryStorage
from limits.strategies import MovingWindowRateLimiter

from app.core.config import Settings
from app.core.errors import AppError, UnauthorizedError
from app.core.security import decode_access_token


class RateLimitedError(AppError):
    status_code = 429
    code = "rate_limited"
    message = "Too many requests, try again later"


class RateLimiter:
    def __init__(self, enabled: bool) -> None:
        self.enabled = enabled
        self._limiter = MovingWindowRateLimiter(MemoryStorage())

    def hit(self, limit: str, scope: str, key: str) -> None:
        """Count one request for (scope, key); raise 429 with Retry-After once over the limit."""
        if not self.enabled:
            return
        item = parse(limit)
        if self._limiter.hit(item, scope, key):
            return
        reset_at = self._limiter.get_window_stats(item, scope, key).reset_time
        retry_after = max(1, math.ceil(reset_at - time.time()))
        raise RateLimitedError(headers={"Retry-After": str(retry_after)})


def client_ip(request: Request) -> str:
    # X-Forwarded-For is deliberately not trusted: there is no reverse proxy in front yet (Phase 7).
    return request.client.host if request.client else "unknown"


def get_limiter(request: Request) -> RateLimiter:
    return request.app.state.rate_limiter


def per_ip(scope: str, setting: str) -> Callable[[Request], Coroutine[Any, Any, None]]:
    """Dependency: `setting` names the Settings attribute that holds the limit string."""

    async def _dependency(request: Request) -> None:
        settings: Settings = request.app.state.settings
        get_limiter(request).hit(getattr(settings, setting), scope, client_ip(request))

    return _dependency


async def default_limit(request: Request) -> None:
    """General limit: per user when the bearer token is valid, otherwise per client IP."""
    settings: Settings = request.app.state.settings
    key = f"ip:{client_ip(request)}"
    auth = request.headers.get("authorization", "")
    if auth[:7].lower() == "bearer ":
        with contextlib.suppress(UnauthorizedError):  # an invalid token: the endpoint answers 401
            key = f"user:{decode_access_token(auth[7:], settings).user_id}"
    get_limiter(request).hit(settings.rate_limit_default, "default", key)
