import httpx
import pytest
from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.users.models import User
from tests.helpers import PASSWORD, bearer, login, register

# ---- register ----


async def test_register_creates_user_and_normalizes_email(client: httpx.AsyncClient) -> None:
    resp = await client.post(
        "/auth/register",
        json={"email": "  Rider.One@Example.COM ", "password": PASSWORD, "display_name": "  Rider One "},
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["email"] == "rider.one@example.com"
    assert body["display_name"] == "Rider One"
    assert body["role"] == "rider"
    assert "password" not in resp.text and "password_hash" not in body


async def test_register_duplicate_email_is_case_insensitive(client: httpx.AsyncClient) -> None:
    await register(client, "dup@example.com")
    resp = await client.post(
        "/auth/register", json={"email": "DUP@example.com", "password": PASSWORD, "display_name": "x"}
    )
    assert resp.status_code == 409
    assert resp.json()["error"]["code"] == "email_taken"


@pytest.mark.parametrize(
    ("password", "reason"),
    [("short1", "at least 8"), ("password123", "too common"), ("weakuser", "e-mail name")],
)
async def test_register_rejects_weak_passwords(client: httpx.AsyncClient, password: str, reason: str) -> None:
    resp = await client.post(
        "/auth/register", json={"email": "weakuser@example.com", "password": password, "display_name": "w"}
    )
    assert resp.status_code == 400
    err = resp.json()["error"]
    assert err["code"] == "weak_password" and reason in err["message"]


@pytest.mark.parametrize(
    "payload",
    [
        {"email": "not-an-email", "password": PASSWORD, "display_name": "x"},
        {"email": "a@example.com", "password": PASSWORD, "display_name": "   "},
        {"email": "a@example.com", "password": PASSWORD, "display_name": "x" * 81},
        {"email": "a@example.com", "password": PASSWORD},
        {"email": "a@example.com", "password": PASSWORD, "display_name": "x", "role": "admin"},
    ],
    ids=["bad-email", "blank-name", "long-name", "missing-name", "extra-field-role"],
)
async def test_register_validation_errors(client: httpx.AsyncClient, payload: dict) -> None:
    resp = await client.post("/auth/register", json=payload)
    assert resp.status_code == 422
    err = resp.json()["error"]
    assert err["code"] == "validation_error" and err["details"]


# ---- login ----


async def test_login_returns_token_pair(client: httpx.AsyncClient) -> None:
    await register(client, "login@example.com")
    pair = await login(client, "LOGIN@example.com")
    assert pair["token_type"] == "bearer"
    assert pair["expires_in"] == 15 * 60
    assert pair["access_token"] and pair["refresh_token"]


async def test_login_wrong_password_and_unknown_email_look_the_same(client: httpx.AsyncClient) -> None:
    await register(client, "known@example.com")
    wrong = await client.post(
        "/auth/login", json={"email": "known@example.com", "password": "wrong password!"}
    )
    unknown = await client.post("/auth/login", json={"email": "nobody@example.com", "password": PASSWORD})
    assert wrong.status_code == unknown.status_code == 401
    assert wrong.json() == unknown.json()
    assert wrong.json()["error"]["code"] == "invalid_credentials"
    assert wrong.headers["www-authenticate"] == "Bearer"


async def test_login_inactive_user_is_rejected(client: httpx.AsyncClient, db: AsyncSession) -> None:
    await register(client, "inactive@example.com")
    await db.execute(update(User).where(User.email == "inactive@example.com").values(is_active=False))
    await db.commit()
    resp = await client.post("/auth/login", json={"email": "inactive@example.com", "password": PASSWORD})
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "invalid_credentials"


# ---- access token on a protected endpoint ----


async def test_me_with_valid_token(client: httpx.AsyncClient) -> None:
    user = await register(client, "me@example.com")
    pair = await login(client, "me@example.com")
    resp = await client.get("/me", headers=bearer(pair["access_token"]))
    assert resp.status_code == 200
    assert resp.json()["id"] == user["id"]


async def test_each_token_only_sees_its_own_user(client: httpx.AsyncClient) -> None:
    a = await register(client, "alice@example.com")
    b = await register(client, "bob@example.com")
    token_a = (await login(client, "alice@example.com"))["access_token"]
    token_b = (await login(client, "bob@example.com"))["access_token"]
    assert (await client.get("/me", headers=bearer(token_a))).json()["id"] == a["id"]
    assert (await client.get("/me", headers=bearer(token_b))).json()["id"] == b["id"]


@pytest.mark.parametrize(
    ("headers", "code"),
    [
        ({}, "not_authenticated"),
        ({"Authorization": "Basic abc"}, "not_authenticated"),
        ({"Authorization": "Bearer not.a.jwt"}, "invalid_token"),
    ],
    ids=["missing", "wrong-scheme", "garbage"],
)
async def test_me_rejects_missing_or_bad_tokens(client: httpx.AsyncClient, headers: dict, code: str) -> None:
    resp = await client.get("/me", headers=headers)
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == code


async def test_refresh_token_is_not_an_access_token(client: httpx.AsyncClient) -> None:
    await register(client, "swap@example.com")
    pair = await login(client, "swap@example.com")
    resp = await client.get("/me", headers=bearer(pair["refresh_token"]))
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "invalid_token"


async def test_token_of_deactivated_user_is_rejected(client: httpx.AsyncClient, db: AsyncSession) -> None:
    await register(client, "gone@example.com")
    pair = await login(client, "gone@example.com")
    await db.execute(update(User).where(User.email == "gone@example.com").values(is_active=False))
    await db.commit()
    resp = await client.get("/me", headers=bearer(pair["access_token"]))
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "invalid_token"
