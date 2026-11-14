"""Phase 6 security audit checks (docs/SECURITY_AUDIT.md).

- Endpoint inventory (OWASP API9): every route is listed here as public or as needing a token, so a
  new endpoint fails this test until someone decides which it is.
- Authentication (API2): every non-public route answers 401 without a bearer token.
- Request size (API4): bodies over the cap answer 413 before the app reads them, also when the body
  is streamed without a Content-Length, and before authentication.
"""

from collections.abc import AsyncIterator

import httpx
import pytest
from fastapi import FastAPI

from app.core.config import MULTIPART_OVERHEAD_BYTES, Settings
from app.core.logging import configure_logging
from app.main import create_app
from tests.conftest import make_settings
from tests.helpers import bearer

PREFIX = "/api/v1"
ANY_ID = "6f1c0f0e-0000-4000-8000-000000000000"

PUBLIC = {
    ("GET", "/health"),
    ("GET", "/ready"),
    ("POST", "/auth/register"),
    ("POST", "/auth/login"),
    ("POST", "/auth/refresh"),
    ("POST", "/auth/logout"),
    ("POST", "/auth/forgot-password"),
    ("POST", "/auth/reset-password"),
}

AUTHENTICATED = {
    ("GET", "/me"),
    ("PATCH", "/me"),
    ("DELETE", "/me"),
    ("GET", "/me/rider-profile"),
    ("PUT", "/me/rider-profile"),
    ("GET", "/work-sessions"),
    ("POST", "/work-sessions"),
    ("GET", "/work-sessions/{session_id}"),
    ("PATCH", "/work-sessions/{session_id}"),
    ("DELETE", "/work-sessions/{session_id}"),
    ("GET", "/income"),
    ("POST", "/income"),
    ("GET", "/income/{income_id}"),
    ("PATCH", "/income/{income_id}"),
    ("DELETE", "/income/{income_id}"),
    ("GET", "/expenses"),
    ("POST", "/expenses"),
    ("GET", "/expenses/{expense_id}"),
    ("PATCH", "/expenses/{expense_id}"),
    ("DELETE", "/expenses/{expense_id}"),
    ("GET", "/profit/summary"),
    ("GET", "/profit/trends"),
    ("GET", "/profit/patterns"),
    ("GET", "/pickup/restaurants"),
    ("POST", "/pickup/restaurants"),
    ("GET", "/pickup/restaurants/{restaurant_id}/analytics"),
    ("GET", "/pickup/restaurants/{restaurant_id}/wait-stats"),
    ("POST", "/pickup/predictions"),
    ("GET", "/pickup/predictions"),
    ("GET", "/pickup/model"),
    ("GET", "/pickup/logs"),
    ("POST", "/pickup/logs"),
    ("DELETE", "/pickup/logs/{log_id}"),
    ("GET", "/shift-scenarios"),
    ("POST", "/shift-scenarios"),
    ("POST", "/shift-scenarios/compare"),
    ("GET", "/shift-scenarios/{scenario_id}"),
    ("PATCH", "/shift-scenarios/{scenario_id}"),
    ("DELETE", "/shift-scenarios/{scenario_id}"),
    ("POST", "/shift-scenarios/{scenario_id}/estimate"),
    ("POST", "/road/reports"),
    ("GET", "/road/reports"),
    ("GET", "/road/reports/{report_id}/image"),
    ("GET", "/road/incidents"),
    ("GET", "/road/incidents/nearby"),
    ("GET", "/road/incidents/{incident_id}"),
    ("POST", "/road/incidents/{incident_id}/confirmations"),
    ("PATCH", "/road/incidents/{incident_id}/status"),
}


def _routes(app: FastAPI) -> set[tuple[str, str]]:
    paths = app.openapi()["paths"]
    return {(method.upper(), path.removeprefix(PREFIX)) for path, ops in paths.items() for method in ops}


def _concrete(path: str) -> str:
    """Fill every {param} with a syntactically valid id."""
    parts = [ANY_ID if p.startswith("{") and p.endswith("}") else p for p in path.split("/")]
    return "/".join(parts)


def test_every_route_is_classified(app: FastAPI) -> None:
    assert not PUBLIC & AUTHENTICATED
    assert _routes(app) == PUBLIC | AUTHENTICATED


@pytest.mark.parametrize(("method", "path"), sorted(AUTHENTICATED))
async def test_route_requires_a_token(client: httpx.AsyncClient, method: str, path: str) -> None:
    resp = await client.request(method, _concrete(path))
    assert resp.status_code == 401, resp.text
    assert resp.json()["error"]["code"] == "not_authenticated"
    assert resp.headers["www-authenticate"] == "Bearer"


# ---- request body size (app/core/body_limit.py) ----


async def _chunks(total: int, chunk: int = 64 * 1024, head: bytes = b"") -> AsyncIterator[bytes]:
    if head:
        yield head
    sent = len(head)
    while sent < total:
        size = min(chunk, total - sent)
        sent += size
        yield b"x" * size


async def test_declared_json_body_over_cap_is_413(client: httpx.AsyncClient, settings: Settings) -> None:
    body = b'{"email": "' + b"a" * settings.max_json_body_bytes + b'@example.com", "password": "x"}'
    resp = await client.post("/auth/login", content=body, headers={"Content-Type": "application/json"})
    assert resp.status_code == 413
    assert resp.json()["error"]["code"] == "payload_too_large"


async def test_streamed_json_body_over_cap_is_413(client: httpx.AsyncClient, settings: Settings) -> None:
    resp = await client.post(
        "/auth/login",
        content=_chunks(settings.max_json_body_bytes + 1),
        headers={"Content-Type": "application/json"},
    )
    assert "content-length" not in resp.request.headers
    assert resp.status_code == 413
    assert resp.json()["error"]["code"] == "payload_too_large"


async def test_streamed_upload_over_cap_is_413_before_authentication(
    client: httpx.AsyncClient, settings: Settings
) -> None:
    # FastAPI reads a form before it runs the auth dependency, so without the cap an anonymous
    # client could make the server spool any amount of data to disk.
    cap = settings.road_image_max_bytes + MULTIPART_OVERHEAD_BYTES
    part = (
        b"--x\r\n"
        b'Content-Disposition: form-data; name="image"; filename="a.jpg"\r\n'
        b"Content-Type: image/jpeg\r\n\r\n"
    )
    resp = await client.post(
        "/road/reports",
        content=_chunks(cap + 1, head=part),
        headers={"Content-Type": "multipart/form-data; boundary=x"},
    )
    assert resp.status_code == 413
    assert resp.json()["error"]["code"] == "payload_too_large"


async def test_invalid_content_length_is_413(client: httpx.AsyncClient) -> None:
    resp = await client.post(
        "/auth/login", content=b"{}", headers={"Content-Type": "application/json", "Content-Length": "abc"}
    )
    assert resp.status_code == 413


async def test_normal_bodies_pass(client: httpx.AsyncClient) -> None:
    resp = await client.post("/auth/login", json={"email": "nobody@example.com", "password": "whatever 123"})
    assert resp.status_code == 401


# ---- logs (SYSTEM_ARCHITECTURE §5 "Privacy"): no password, token or precise position ----


@pytest.fixture
async def info_log_client(database_url: str) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(make_settings(database_url, log_level="INFO", log_json=True))
    try:
        async with app.router.lifespan_context(app):
            transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
            async with httpx.AsyncClient(transport=transport, base_url="http://test/api/v1") as c:
                yield c
    finally:
        configure_logging("WARNING", True)  # back to the level the other tests use


async def test_logs_hold_no_password_token_or_position(
    info_log_client: httpx.AsyncClient, capfd: pytest.CaptureFixture[str]
) -> None:
    secret_password = "Unusual Passphrase 4417"
    await info_log_client.post(
        "/auth/register",
        json={"email": "logcheck@example.com", "password": secret_password, "display_name": "l"},
    )
    pair = (
        await info_log_client.post(
            "/auth/login", json={"email": "logcheck@example.com", "password": secret_password}
        )
    ).json()
    headers = bearer(pair["access_token"])
    nearby = await info_log_client.get(
        "/road/incidents/nearby", params={"lat": "13.7563309", "lng": "100.5017651"}, headers=headers
    )
    assert nearby.status_code == 200, nearby.text
    await info_log_client.post("/auth/refresh", json={"refresh_token": pair["refresh_token"]})

    out = capfd.readouterr().out
    assert '"event": "request"' in out and "/road/incidents/nearby" in out  # the access log ran
    for leaked in (secret_password, pair["access_token"], pair["refresh_token"], "13.7563309", "100.5017651"):
        assert leaked not in out
