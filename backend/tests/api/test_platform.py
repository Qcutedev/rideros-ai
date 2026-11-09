"""Health/readiness, the shared error envelope, request ids and docs exposure."""

from collections.abc import AsyncIterator

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import make_url

from app.core.errors import NotFoundError
from app.main import create_app
from tests.conftest import make_settings


async def test_health(client: httpx.AsyncClient) -> None:
    resp = await client.get("/health")
    assert resp.status_code == 200 and resp.json() == {"status": "ok"}


async def test_ready_when_database_answers(client: httpx.AsyncClient) -> None:
    resp = await client.get("/ready")
    assert resp.status_code == 200
    assert resp.json()["checks"]["database"] == "ok"
    assert resp.json()["checks"]["model"] == "ok (pickup_o2p/0.0.0-test)"


@pytest.fixture
async def broken_db_client(database_url: str) -> AsyncIterator[httpx.AsyncClient]:
    url = make_url(database_url).set(port=1, password="wrong")  # nothing listens on port 1
    app = create_app(make_settings(url.render_as_string(hide_password=False)))
    async with app.router.lifespan_context(app):
        transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
        async with httpx.AsyncClient(transport=transport, base_url="http://test/api/v1") as c:
            yield c


async def test_ready_reports_unavailable_database(broken_db_client: httpx.AsyncClient) -> None:
    resp = await broken_db_client.get("/ready")
    assert resp.status_code == 503
    # This app also has no MODEL_DIR, so the model check fails too.
    assert resp.json() == {
        "status": "unavailable",
        "checks": {"database": "unavailable", "model": "not_loaded"},
    }


async def test_unknown_route_uses_error_envelope(client: httpx.AsyncClient) -> None:
    resp = await client.get("/does-not-exist")
    assert resp.status_code == 404
    assert resp.json() == {"error": {"code": "not_found", "message": "Not Found", "details": []}}


async def test_wrong_method_uses_error_envelope(client: httpx.AsyncClient) -> None:
    resp = await client.get("/auth/login")
    assert resp.status_code == 405
    assert resp.json()["error"]["code"] == "method_not_allowed"


async def test_malformed_json_is_422(client: httpx.AsyncClient) -> None:
    resp = await client.post(
        "/auth/login", content=b"{not json", headers={"content-type": "application/json"}
    )
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "validation_error"


@pytest.fixture
async def app_with_test_routes(database_url: str) -> AsyncIterator[FastAPI]:
    app = create_app(make_settings(database_url))

    @app.get("/api/v1/_boom")
    async def boom() -> None:
        raise RuntimeError("secret internal detail")

    @app.get("/api/v1/_missing")
    async def missing() -> None:
        raise NotFoundError()

    async with app.router.lifespan_context(app):
        yield app


async def test_unhandled_error_is_500_without_leaking_details(app_with_test_routes: FastAPI) -> None:
    transport = httpx.ASGITransport(app=app_with_test_routes, raise_app_exceptions=False)
    async with httpx.AsyncClient(transport=transport, base_url="http://test/api/v1") as c:
        resp = await c.get("/_boom")
        assert resp.status_code == 500
        assert resp.json() == {
            "error": {"code": "internal_error", "message": "Internal server error", "details": []}
        }
        assert "secret internal detail" not in resp.text

        missing = await c.get("/_missing")
        assert missing.status_code == 404
        assert missing.json()["error"] == {
            "code": "not_found",
            "message": "Resource not found",
            "details": [],
        }


async def test_request_id_is_generated(client: httpx.AsyncClient) -> None:
    resp = await client.get("/health")
    assert len(resp.headers["x-request-id"]) == 32


async def test_valid_request_id_is_echoed_and_invalid_one_replaced(client: httpx.AsyncClient) -> None:
    echoed = await client.get("/health", headers={"X-Request-ID": "client-req-1234"})
    assert echoed.headers["x-request-id"] == "client-req-1234"
    replaced = await client.get("/health", headers={"X-Request-ID": "bad id <script>"})
    assert len(replaced.headers["x-request-id"]) == 32


async def test_openapi_lists_auth_routes_in_development(client: httpx.AsyncClient) -> None:
    resp = await client.get("http://test/openapi.json")
    assert resp.status_code == 200
    paths = resp.json()["paths"]
    for path in (
        "/api/v1/auth/register",
        "/api/v1/auth/login",
        "/api/v1/auth/refresh",
        "/api/v1/auth/logout",
        "/api/v1/auth/forgot-password",
        "/api/v1/auth/reset-password",
        "/api/v1/me",
    ):
        assert path in paths
