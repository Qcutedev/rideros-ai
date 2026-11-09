"""Rate limits (docs/SYSTEM_ARCHITECTURE.md §5), on an app of their own with limits enabled."""

from collections.abc import AsyncIterator, Callable

import httpx
import pytest
from fastapi import FastAPI

from app.main import create_app
from tests.conftest import make_settings
from tests.helpers import PASSWORD, bearer

type ClientFactory = Callable[[str], httpx.AsyncClient]


@pytest.fixture
async def limited_app(database_url: str) -> AsyncIterator[FastAPI]:
    app = create_app(make_settings(database_url, rate_limit_enabled=True, rate_limit_default="4/minute"))
    async with app.router.lifespan_context(app):
        yield app


@pytest.fixture
def client_from(limited_app: FastAPI) -> ClientFactory:
    def make(ip: str) -> httpx.AsyncClient:
        transport = httpx.ASGITransport(app=limited_app, raise_app_exceptions=False, client=(ip, 50000))
        return httpx.AsyncClient(transport=transport, base_url="http://test/api/v1")

    return make


def assert_limited(resp: httpx.Response) -> None:
    assert resp.status_code == 429, resp.text
    assert resp.json()["error"]["code"] == "rate_limited"
    assert int(resp.headers["Retry-After"]) >= 1


async def test_register_is_limited_per_ip(client_from: ClientFactory) -> None:
    async with client_from("10.0.0.1") as a, client_from("10.0.0.2") as b:
        for i in range(3):
            body = {"email": f"r{i}@example.com", "password": PASSWORD, "display_name": "r"}
            assert (await a.post("/auth/register", json=body)).status_code == 201
        assert_limited(
            await a.post(
                "/auth/register", json={"email": "r9@example.com", "password": PASSWORD, "display_name": "r"}
            )
        )
        body = {"email": "other@example.com", "password": PASSWORD, "display_name": "o"}
        assert (await b.post("/auth/register", json=body)).status_code == 201  # another IP is unaffected


async def test_login_is_limited_per_ip_and_per_email(client_from: ClientFactory) -> None:
    async with client_from("10.1.0.1") as setup:
        await setup.post(
            "/auth/register", json={"email": "target@example.com", "password": PASSWORD, "display_name": "t"}
        )
    wrong = {"email": "target@example.com", "password": "wrong password 1"}

    async with client_from("10.1.0.2") as attacker:
        for _ in range(5):
            assert (await attacker.post("/auth/login", json=wrong)).status_code == 401
        assert_limited(await attacker.post("/auth/login", json=wrong))

    # The same e-mail from a fresh IP is still blocked (5 attempts per e-mail per minute).
    async with client_from("10.1.0.3") as other_ip:
        assert_limited(
            await other_ip.post("/auth/login", json={"email": "target@example.com", "password": PASSWORD})
        )
        assert (
            await other_ip.post("/auth/login", json={"email": "else@example.com", "password": "x" * 9})
        ).status_code == 401


async def test_forgot_password_is_limited(client_from: ClientFactory) -> None:
    async with client_from("10.2.0.1") as c:
        for _ in range(3):
            assert (
                await c.post("/auth/forgot-password", json={"email": "nobody@example.com"})
            ).status_code == 202
        assert_limited(await c.post("/auth/forgot-password", json={"email": "nobody@example.com"}))


async def test_default_limit_is_per_user(client_from: ClientFactory) -> None:
    async with client_from("10.3.0.1") as c:
        tokens = {}
        for name in ("u1", "u2"):
            await c.post(
                "/auth/register",
                json={"email": f"{name}@example.com", "password": PASSWORD, "display_name": name},
            )
            tokens[name] = (
                await c.post("/auth/login", json={"email": f"{name}@example.com", "password": PASSWORD})
            ).json()
        for _ in range(4):
            assert (await c.get("/me", headers=bearer(tokens["u1"]["access_token"]))).status_code == 200
        assert_limited(await c.get("/income", headers=bearer(tokens["u1"]["access_token"])))
        # Same IP, different user: separate budget.
        assert (await c.get("/me", headers=bearer(tokens["u2"]["access_token"]))).status_code == 200


async def test_invalid_tokens_are_limited_per_ip(client_from: ClientFactory) -> None:
    async with client_from("10.4.0.1") as c:
        for _ in range(4):
            assert (await c.get("/me", headers=bearer("not-a-jwt"))).status_code == 401
        assert_limited(await c.get("/me", headers=bearer("still-not-a-jwt")))


async def test_health_is_not_limited(client_from: ClientFactory) -> None:
    async with client_from("10.5.0.1") as c:
        for _ in range(10):
            assert (await c.get("/health")).status_code == 200
