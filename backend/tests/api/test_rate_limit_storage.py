"""Phase 7: shared rate-limit store (Valkey/Redis), fail-closed behaviour and the proxy-header trust.

Needs the compose "valkey" service (`docker compose up -d --wait db valkey`), like the database.
"""

import os
import uuid
from collections.abc import AsyncIterator

import httpx
import pytest
from fastapi import FastAPI
from pydantic import ValidationError
from uvicorn.middleware.proxy_headers import ProxyHeadersMiddleware

from app.core.rate_limit import create_storage
from app.main import create_app
from tests.conftest import make_settings
from tests.helpers import PASSWORD

REDIS_URL = os.environ.get("TEST_REDIS_URL", "redis://127.0.0.1:6379/15")
UNREACHABLE_REDIS_URL = "redis://127.0.0.1:1/0"  # nothing listens on port 1


def _client(app: FastAPI, ip: str) -> httpx.AsyncClient:
    transport = httpx.ASGITransport(app=app, raise_app_exceptions=False, client=(ip, 50000))
    return httpx.AsyncClient(transport=transport, base_url="http://test/api/v1")


@pytest.fixture
async def two_workers(database_url: str) -> AsyncIterator[tuple[FastAPI, FastAPI]]:
    """Two app instances on one Valkey store: what 2 uvicorn workers look like."""
    apps = [
        create_app(make_settings(database_url, rate_limit_enabled=True, rate_limit_storage_url=REDIS_URL))
        for _ in range(2)
    ]
    async with apps[0].router.lifespan_context(apps[0]), apps[1].router.lifespan_context(apps[1]):
        yield apps[0], apps[1]


async def test_workers_share_the_login_budget(two_workers: tuple[FastAPI, FastAPI]) -> None:
    first, second = two_workers
    email = f"shared-{uuid.uuid4().hex[:12]}@example.com"  # fresh key: the store outlives a test run
    wrong = {"email": email, "password": "wrong password 1"}
    async with _client(first, "10.9.0.1") as a, _client(second, "10.9.0.2") as b:
        for i in range(5):  # 5/minute per e-mail, spread over both workers and two IPs
            assert (await (a if i % 2 else b).post("/auth/login", json=wrong)).status_code == 401
        resp = await a.post("/auth/login", json=wrong)
        assert resp.status_code == 429, resp.text
        assert int(resp.headers["Retry-After"]) >= 1
        # The other worker sees the same count.
        assert (await b.post("/auth/login", json=wrong)).status_code == 429


async def test_ready_reports_the_shared_store(two_workers: tuple[FastAPI, FastAPI]) -> None:
    async with _client(two_workers[0], "10.9.1.1") as c:
        body = (await c.get("/ready")).json()
    assert body["checks"]["rate_limit"] == "ok"


async def test_unreachable_store_fails_closed(database_url: str) -> None:
    app = create_app(
        make_settings(database_url, rate_limit_enabled=True, rate_limit_storage_url=UNREACHABLE_REDIS_URL)
    )
    async with app.router.lifespan_context(app), _client(app, "10.9.2.1") as c:
        resp = await c.post("/auth/login", json={"email": "x@example.com", "password": PASSWORD})
        assert resp.status_code == 503, resp.text
        assert resp.json()["error"]["code"] == "rate_limit_unavailable"
        # /health is not limited; /ready says why the instance should get no traffic.
        assert (await c.get("/health")).status_code == 200
        ready = await c.get("/ready")
        assert ready.status_code == 503
        assert ready.json()["checks"]["rate_limit"] == "unavailable"


def test_memory_store_needs_no_server() -> None:
    assert type(create_storage("memory://")).__name__ == "MemoryStorage"


def test_unknown_store_scheme_is_rejected() -> None:
    with pytest.raises(ValueError, match="memory:// or redis://"):
        create_storage("memcached://127.0.0.1:11211")


def test_production_refuses_several_workers_on_the_memory_store(database_url: str) -> None:
    with pytest.raises(ValidationError, match="WEB_CONCURRENCY"):
        make_settings(database_url, env="production", web_concurrency=2)
    settings = make_settings(
        database_url, env="production", web_concurrency=2, rate_limit_storage_url="redis://valkey:6379/0"
    )
    assert settings.web_concurrency == 2


# ---- X-Forwarded-For trust (uvicorn's proxy headers, configured by FORWARDED_ALLOW_IPS) ----------


async def _seen_ip(app: FastAPI, peer: str, forwarded_for: str, trusted: str) -> str:
    """Client address the app sees after uvicorn's middleware, as configured in compose.prod.yml."""
    seen: list[str] = []

    async def capture(scope, receive, send):  # type: ignore[no-untyped-def]
        if scope["type"] == "http":
            seen.append(scope["client"][0])
        await app(scope, receive, send)

    wrapped = ProxyHeadersMiddleware(capture, trusted_hosts=trusted)
    transport = httpx.ASGITransport(app=wrapped, client=(peer, 50000))
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        await c.get("/api/v1/health", headers={"X-Forwarded-For": forwarded_for})
    return seen[0]


async def test_forwarded_for_is_used_only_from_the_proxy(app: FastAPI) -> None:
    caddy = "172.30.0.10"
    # From Caddy: the client Caddy appended (right-most entry) is used.
    assert await _seen_ip(app, caddy, "203.0.113.7", trusted=caddy) == "203.0.113.7"
    # A client that forges the header before Caddy appends the real address cannot pick its key.
    assert await _seen_ip(app, caddy, "1.2.3.4, 203.0.113.7", trusted=caddy) == "203.0.113.7"
    # Any other peer (e.g. straight to the backend port): the header is ignored.
    assert await _seen_ip(app, "198.51.100.9", "1.2.3.4", trusted=caddy) == "198.51.100.9"
