"""D5: dev-log reset links, hashed single-use 30-minute tokens, disabled in production."""

from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta
from urllib.parse import parse_qs, urlparse

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from structlog.testing import capture_logs

from app.core.security import hash_token
from app.main import create_app
from app.modules.auth.models import PasswordResetToken
from tests.conftest import make_settings
from tests.helpers import PASSWORD, login, register

NEW_PASSWORD = "an entirely new passphrase"


def _links(logs: list[dict]) -> list[str]:
    return [entry["reset_link"] for entry in logs if "reset_link" in entry]


async def _request_reset(client: httpx.AsyncClient, email: str) -> str:
    with capture_logs() as logs:
        resp = await client.post("/auth/forgot-password", json={"email": email})
    assert resp.status_code == 202
    links = _links(logs)
    assert len(links) == 1
    entry = next(e for e in logs if "reset_link" in e)
    assert entry["log_level"] == "warning" and "DEV ONLY" in entry["event"]
    return parse_qs(urlparse(links[0]).query)["token"][0]


async def test_forgot_password_logs_dev_link_and_stores_only_hash(
    client: httpx.AsyncClient, db: AsyncSession
) -> None:
    await register(client, "forgot@example.com")
    token = await _request_reset(client, "forgot@example.com")
    row = (await db.execute(select(PasswordResetToken))).scalar_one()
    assert row.token_hash == hash_token(token) and row.token_hash != token
    lifetime = row.expires_at - row.created_at
    assert timedelta(minutes=29) < lifetime <= timedelta(minutes=30, seconds=5)


async def test_forgot_password_does_not_reveal_unknown_email(client: httpx.AsyncClient) -> None:
    await register(client, "exists@example.com")
    with capture_logs() as logs:
        unknown = await client.post("/auth/forgot-password", json={"email": "missing@example.com"})
    known = await client.post("/auth/forgot-password", json={"email": "exists@example.com"})
    assert unknown.status_code == known.status_code == 202
    assert unknown.json() == known.json()
    assert _links(logs) == []


async def test_reset_password_changes_password_and_signs_out_everywhere(client: httpx.AsyncClient) -> None:
    await register(client, "reset@example.com")
    session = await login(client, "reset@example.com")
    token = await _request_reset(client, "reset@example.com")

    resp = await client.post("/auth/reset-password", json={"token": token, "new_password": NEW_PASSWORD})
    assert resp.status_code == 204

    old = await client.post("/auth/login", json={"email": "reset@example.com", "password": PASSWORD})
    assert old.status_code == 401
    await login(client, "reset@example.com", NEW_PASSWORD)
    refresh = await client.post("/auth/refresh", json={"refresh_token": session["refresh_token"]})
    assert refresh.status_code == 401


async def test_reset_token_is_single_use(client: httpx.AsyncClient) -> None:
    await register(client, "once@example.com")
    token = await _request_reset(client, "once@example.com")
    first = await client.post("/auth/reset-password", json={"token": token, "new_password": NEW_PASSWORD})
    second = await client.post(
        "/auth/reset-password", json={"token": token, "new_password": "yet another passphrase"}
    )
    assert first.status_code == 204
    assert second.status_code == 400
    assert second.json()["error"]["code"] == "invalid_reset_token"


async def test_new_request_invalidates_previous_token(client: httpx.AsyncClient) -> None:
    await register(client, "twice@example.com")
    first = await _request_reset(client, "twice@example.com")
    second = await _request_reset(client, "twice@example.com")
    stale = await client.post("/auth/reset-password", json={"token": first, "new_password": NEW_PASSWORD})
    assert stale.status_code == 400
    fresh = await client.post("/auth/reset-password", json={"token": second, "new_password": NEW_PASSWORD})
    assert fresh.status_code == 204


async def test_expired_reset_token_is_rejected(client: httpx.AsyncClient, db: AsyncSession) -> None:
    await register(client, "late@example.com")
    token = await _request_reset(client, "late@example.com")
    await db.execute(update(PasswordResetToken).values(expires_at=datetime.now(UTC) - timedelta(seconds=1)))
    await db.commit()
    resp = await client.post("/auth/reset-password", json={"token": token, "new_password": NEW_PASSWORD})
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "invalid_reset_token"


async def test_unknown_reset_token_is_rejected(client: httpx.AsyncClient) -> None:
    resp = await client.post("/auth/reset-password", json={"token": "z" * 43, "new_password": NEW_PASSWORD})
    assert resp.status_code == 400


async def test_weak_new_password_does_not_consume_token(client: httpx.AsyncClient) -> None:
    await register(client, "weaknew@example.com")
    token = await _request_reset(client, "weaknew@example.com")
    weak = await client.post("/auth/reset-password", json={"token": token, "new_password": "password1"})
    assert weak.status_code == 400 and weak.json()["error"]["code"] == "weak_password"
    ok = await client.post("/auth/reset-password", json={"token": token, "new_password": NEW_PASSWORD})
    assert ok.status_code == 204


# ---- production without an e-mail provider: endpoints off, nothing logged ----


@pytest.fixture
async def prod_client(database_url: str) -> AsyncIterator[httpx.AsyncClient]:
    settings = make_settings(database_url, env="production")
    app: FastAPI = create_app(settings)
    async with app.router.lifespan_context(app):
        transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
        async with httpx.AsyncClient(transport=transport, base_url="http://test/api/v1") as c:
            yield c


async def test_production_disables_forgot_password_and_never_logs_link(
    client: httpx.AsyncClient, prod_client: httpx.AsyncClient, db: AsyncSession
) -> None:
    await register(client, "prod@example.com")
    with capture_logs() as logs:
        resp = await prod_client.post("/auth/forgot-password", json={"email": "prod@example.com"})
    assert resp.status_code == 503
    assert resp.json()["error"]["code"] == "password_reset_unavailable"
    assert _links(logs) == []
    assert not any("token" in str(entry.get("reset_link", "")) for entry in logs)
    assert (await db.execute(select(PasswordResetToken))).first() is None


async def test_production_disables_reset_password(prod_client: httpx.AsyncClient) -> None:
    resp = await prod_client.post(
        "/auth/reset-password", json={"token": "z" * 43, "new_password": NEW_PASSWORD}
    )
    assert resp.status_code == 503


async def test_production_hides_openapi_docs(prod_client: httpx.AsyncClient) -> None:
    resp = await prod_client.get("http://test/docs")
    assert resp.status_code == 404
