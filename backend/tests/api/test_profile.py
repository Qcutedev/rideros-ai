"""PATCH/DELETE /me and GET/PUT /me/rider-profile."""

import uuid

import httpx
import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import IncomeRecord, RefreshToken, RiderProfile, User, WorkSession
from tests.helpers import PASSWORD, auth_headers, bearer, login, register

# ---- PATCH /me ----


async def test_patch_me_updates_display_name(client: httpx.AsyncClient) -> None:
    h = await auth_headers(client, "patch@example.com")
    resp = await client.patch("/me", json={"display_name": "  New Name "}, headers=h)
    assert resp.status_code == 200 and resp.json()["display_name"] == "New Name"
    assert (await client.get("/me", headers=h)).json()["display_name"] == "New Name"


async def test_patch_me_empty_body_is_a_no_op(client: httpx.AsyncClient) -> None:
    h = await auth_headers(client, "noop@example.com")
    resp = await client.patch("/me", json={}, headers=h)
    assert resp.status_code == 200 and resp.json()["display_name"] == "noop"


@pytest.mark.parametrize(
    "payload",
    [{"display_name": None}, {"display_name": ""}, {"email": "x@example.com"}, {"role": "admin"}],
    ids=["null", "blank", "email-not-editable", "role-not-editable"],
)
async def test_patch_me_rejects(client: httpx.AsyncClient, payload: dict) -> None:
    h = await auth_headers(client, "patchbad@example.com")
    resp = await client.patch("/me", json=payload, headers=h)
    assert resp.status_code == 422
    me = (await client.get("/me", headers=h)).json()
    assert me["role"] == "rider" and me["email"] == "patchbad@example.com"


# ---- DELETE /me ----


async def test_delete_me_requires_correct_password(client: httpx.AsyncClient) -> None:
    h = await auth_headers(client, "keep@example.com")
    resp = await client.request("DELETE", "/me", json={"password": "wrong password!"}, headers=h)
    assert resp.status_code == 403 and resp.json()["error"]["code"] == "invalid_password"
    assert (await client.get("/me", headers=h)).status_code == 200


async def test_delete_me_requires_auth_and_body(client: httpx.AsyncClient) -> None:
    assert (await client.request("DELETE", "/me", json={"password": PASSWORD})).status_code == 401
    h = await auth_headers(client, "nobody@example.com")
    assert (await client.request("DELETE", "/me", headers=h)).status_code == 422


async def test_delete_me_removes_account_and_all_data(client: httpx.AsyncClient, db: AsyncSession) -> None:
    user = await register(client, "gone@example.com")
    tokens = await login(client, "gone@example.com")
    h = bearer(tokens["access_token"])
    ws = await client.post(
        "/work-sessions",
        json={"started_at": "2026-11-09T10:00:00+07:00", "ended_at": "2026-11-09T12:00:00+07:00"},
        headers=h,
    )
    await client.post(
        "/income",
        json={"occurred_on": "2026-11-09", "amount": "100", "work_session_id": ws.json()["id"]},
        headers=h,
    )
    await client.put("/me/rider-profile", json={"vehicle_type": "motorcycle"}, headers=h)
    other = await auth_headers(client, "stays@example.com")
    await client.post("/income", json={"occurred_on": "2026-11-09", "amount": "5"}, headers=other)

    resp = await client.request("DELETE", "/me", json={"password": PASSWORD}, headers=h)
    assert resp.status_code == 204

    uid = uuid.UUID(user["id"])
    for model in (User, RiderProfile, WorkSession, IncomeRecord, RefreshToken):
        column = model.id if model is User else model.user_id
        count = await db.scalar(select(func.count()).select_from(model).where(column == uid))
        assert count == 0, model.__tablename__
    assert await db.scalar(select(func.count()).select_from(IncomeRecord)) == 1  # other user's row stays

    assert (await client.get("/me", headers=h)).json()["error"]["code"] == "invalid_token"
    resp = await client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert resp.status_code == 401
    resp = await client.post("/auth/login", json={"email": "gone@example.com", "password": PASSWORD})
    assert resp.status_code == 401
    await register(client, "gone@example.com")  # the e-mail can be used again


# ---- rider profile ----


async def test_rider_profile_defaults_before_first_save(client: httpx.AsyncClient) -> None:
    h = await auth_headers(client, "fresh@example.com")
    body = (await client.get("/me/rider-profile", headers=h)).json()
    assert body == {
        "vehicle_type": None,
        "fuel_km_per_liter": None,
        "fuel_price_per_liter": None,
        "depreciation_per_km": None,
        "timezone": "Asia/Bangkok",
        "currency": "THB",
        "is_configured": False,
        "updated_at": None,
    }


async def test_put_rider_profile_creates_then_replaces(client: httpx.AsyncClient) -> None:
    h = await auth_headers(client, "profile@example.com")
    full = {
        "vehicle_type": "ev_motorcycle",
        "fuel_km_per_liter": "45.5",
        "fuel_price_per_liter": 38.9,
        "depreciation_per_km": "0.3500",
        "timezone": "Asia/Tokyo",
        "currency": "THB",
    }
    resp = await client.put("/me/rider-profile", json=full, headers=h)
    assert resp.status_code == 200
    body = resp.json()
    assert body["is_configured"] is True and body["updated_at"] is not None
    assert body["fuel_km_per_liter"] == "45.50" and body["fuel_price_per_liter"] == "38.90"
    assert body["depreciation_per_km"] == "0.3500" and body["timezone"] == "Asia/Tokyo"

    # PUT replaces: omitted fields go back to null / defaults.
    resp = await client.put("/me/rider-profile", json={"vehicle_type": "bicycle"}, headers=h)
    body = resp.json()
    assert body["vehicle_type"] == "bicycle" and body["fuel_km_per_liter"] is None
    assert body["timezone"] == "Asia/Bangkok"
    assert (await client.get("/me/rider-profile", headers=h)).json() == body


async def test_put_rider_profile_unknown_timezone(client: httpx.AsyncClient) -> None:
    h = await auth_headers(client, "tz@example.com")
    resp = await client.put("/me/rider-profile", json={"timezone": "Mars/Olympus"}, headers=h)
    assert resp.status_code == 400 and resp.json()["error"]["code"] == "invalid_timezone"
    assert (await client.get("/me/rider-profile", headers=h)).json()["is_configured"] is False


@pytest.mark.parametrize(
    "payload",
    [
        {"vehicle_type": "rocket"},
        {"fuel_km_per_liter": 0},
        {"fuel_km_per_liter": "10000.00"},  # numeric(6,2)
        {"fuel_price_per_liter": -1},
        {"depreciation_per_km": "0.12345"},  # numeric(8,4)
        {"currency": "USD"},
        {"timezone": ""},
        {"user_id": str(uuid.uuid4())},
    ],
    ids=[
        "vehicle",
        "km-zero",
        "km-too-big",
        "price-negative",
        "dep-precision",
        "currency",
        "tz-blank",
        "extra",
    ],
)
async def test_put_rider_profile_validation(client: httpx.AsyncClient, payload: dict) -> None:
    h = await auth_headers(client, "pv@example.com")
    assert (await client.put("/me/rider-profile", json=payload, headers=h)).status_code == 422


async def test_profile_endpoints_require_auth(client: httpx.AsyncClient) -> None:
    assert (await client.get("/me/rider-profile")).status_code == 401
    assert (await client.put("/me/rider-profile", json={})).status_code == 401
    assert (await client.patch("/me", json={})).status_code == 401
