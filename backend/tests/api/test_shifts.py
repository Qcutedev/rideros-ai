"""Shift Simulator API: create = estimate, update, re-estimate, compare, historical method."""

from datetime import date, timedelta

import httpx
import pytest

from app.modules.shifts import service as shifts_service
from tests.helpers import auth_headers

DINNER = {
    "name": "Dinner rush",
    "start_time": "17:00",
    "end_time": "21:30",
    "assumptions": {"orders_per_hour": 2.5, "income_per_order": "45", "km_per_order": 4},
}


@pytest.fixture
async def h(client: httpx.AsyncClient) -> dict[str, str]:
    return await auth_headers(client, "planner@example.com")


async def create(client: httpx.AsyncClient, h: dict, body: dict, status: int = 201) -> dict:
    resp = await client.post("/shift-scenarios", json=body, headers=h)
    assert resp.status_code == status, resp.text
    return resp.json()


async def test_create_estimates_immediately_with_profile_costs(client: httpx.AsyncClient, h: dict) -> None:
    await client.put(
        "/me/rider-profile",
        json={"fuel_km_per_liter": 40, "fuel_price_per_liter": "38", "depreciation_per_km": "0.5"},
        headers=h,
    )
    body = await create(client, h, DINNER)
    assert body["duration_minutes"] == 270 and body["is_estimate"] is True
    assert body["estimated_revenue"] == "506.25"  # 4.5 h x 2.5 x 45
    assert body["estimated_expenses"] == "65.25"  # 45 km: fuel 42.75 + depreciation 22.50
    assert body["estimated_net_profit"] == "441.00" and body["estimated_net_profit_per_hour"] == "98.00"
    assert body["estimate_low"] is None and body["model_version_id"] is None
    assert body["estimate_details"]["sources"]["fuel_km_per_liter"] == "rider_profile"
    assert body["assumptions"] == {"orders_per_hour": "2.5", "income_per_order": "45", "km_per_order": "4"}
    assert body["start_time"] == "17:00:00"


async def test_overnight_shift(client: httpx.AsyncClient, h: dict) -> None:
    body = await create(
        client, h, {**DINNER, "start_time": "22:00", "end_time": "02:00", "planned_weekday": 4}
    )
    assert body["duration_minutes"] == 240 and body["planned_weekday"] == 4


@pytest.mark.parametrize(
    ("patch", "status", "code"),
    [
        ({"end_time": "17:00"}, 400, "invalid_shift_length"),
        ({"end_time": "17:20"}, 400, "invalid_shift_length"),
        ({"estimation_method": "ml"}, 400, "estimation_method_unavailable"),
        ({"assumptions": {"orders_per_hour": 2}}, 400, "missing_assumption"),
        ({"name": ""}, 422, "validation_error"),
        ({"start_time": "17:00+07:00"}, 422, "validation_error"),
        ({"planned_weekday": 7}, 422, "validation_error"),
        ({"assumptions": {"orders_per_hour": -1, "income_per_order": 1}}, 422, "validation_error"),
        ({"assumptions": {"orders_per_hour": 1, "income_per_order": 1, "tips": 5}}, 422, "validation_error"),
        ({"estimation_method": "magic"}, 422, "validation_error"),
        ({"estimated_revenue": 1000000}, 422, "validation_error"),
    ],
)
async def test_create_errors(client: httpx.AsyncClient, h: dict, patch: dict, status: int, code: str) -> None:
    body = await create(client, h, {**DINNER, **patch}, status=status)
    assert body["error"]["code"] == code


async def test_get_update_delete(client: httpx.AsyncClient, h: dict) -> None:
    sid = (await create(client, h, DINNER))["id"]
    assert (await client.get(f"/shift-scenarios/{sid}", headers=h)).json()["name"] == "Dinner rush"

    renamed = (await client.patch(f"/shift-scenarios/{sid}", json={"name": "Late dinner"}, headers=h)).json()
    assert renamed["name"] == "Late dinner" and renamed["estimated_revenue"] == "506.25"

    longer = (await client.patch(f"/shift-scenarios/{sid}", json={"end_time": "22:30"}, headers=h)).json()
    assert longer["duration_minutes"] == 330 and longer["estimated_revenue"] == "618.75"  # re-estimated

    new = {"orders_per_hour": 3, "income_per_order": 40, "other_costs": 30}
    replaced = (await client.patch(f"/shift-scenarios/{sid}", json={"assumptions": new}, headers=h)).json()
    assert replaced["assumptions"] == {"orders_per_hour": "3", "income_per_order": "40", "other_costs": "30"}
    assert replaced["estimated_revenue"] == "660.00" and replaced["estimated_expenses"] == "30.00"
    assert replaced["estimate_details"]["warnings"] == ["distance_costs_not_included"]

    for bad in ({"name": None}, {"assumptions": None}):
        assert (await client.patch(f"/shift-scenarios/{sid}", json=bad, headers=h)).status_code == 422
    resp = await client.patch(f"/shift-scenarios/{sid}", json={"estimation_method": "historical"}, headers=h)
    assert resp.status_code == 400 and resp.json()["error"]["code"] == "insufficient_history"

    assert (await client.delete(f"/shift-scenarios/{sid}", headers=h)).status_code == 204
    resp = await client.get(f"/shift-scenarios/{sid}", headers=h)
    assert resp.status_code == 404 and resp.json()["error"]["code"] == "shift_scenario_not_found"
    assert (await client.delete(f"/shift-scenarios/{sid}", headers=h)).status_code == 404


async def test_re_estimate_uses_latest_profile(client: httpx.AsyncClient, h: dict) -> None:
    sid = (await create(client, h, DINNER))["id"]
    before = (await client.get(f"/shift-scenarios/{sid}", headers=h)).json()
    assert before["estimated_expenses"] == "0.00"
    await client.put(
        "/me/rider-profile", json={"fuel_km_per_liter": 45, "fuel_price_per_liter": 40}, headers=h
    )
    after = (await client.post(f"/shift-scenarios/{sid}/estimate", headers=h)).json()
    assert after["estimated_expenses"] == "40.00"  # 45 km / 45 km/l x 40


async def test_list_pagination(client: httpx.AsyncClient, h: dict) -> None:
    ids = [(await create(client, h, {**DINNER, "name": f"S{i}"}))["id"] for i in range(3)]
    first = (await client.get("/shift-scenarios?limit=2", headers=h)).json()
    second = (await client.get(f"/shift-scenarios?limit=2&cursor={first['next_cursor']}", headers=h)).json()
    assert [s["id"] for s in first["items"] + second["items"]] == ids[::-1]
    assert (await client.get("/shift-scenarios?cursor=bad", headers=h)).status_code == 400


async def test_compare(client: httpx.AsyncClient, h: dict) -> None:
    long_shift = await create(
        client, h, {**DINNER, "name": "Long", "start_time": "10:00", "end_time": "22:00"}
    )
    short_rush = await create(
        client,
        h,
        {
            **DINNER,
            "name": "Rush",
            "start_time": "18:00",
            "end_time": "20:00",
            "assumptions": {"orders_per_hour": 4, "income_per_order": 50},
        },
    )
    resp = await client.post(
        "/shift-scenarios/compare", json={"ids": [long_shift["id"], short_rush["id"]]}, headers=h
    )
    assert resp.status_code == 200
    body = resp.json()
    assert [s["name"] for s in body["scenarios"]] == ["Long", "Rush"]
    assert body["best_net_profit_id"] == long_shift["id"]  # 1350 vs 400
    assert body["best_net_profit_per_hour_id"] == short_rush["id"]  # 200/h vs 112.50/h

    for ids, status in (
        ([long_shift["id"]], 422),
        ([long_shift["id"]] * 2, 422),
        ([long_shift["id"]] * 6, 422),
    ):
        assert (
            await client.post("/shift-scenarios/compare", json={"ids": ids}, headers=h)
        ).status_code == status
    missing = {"ids": [long_shift["id"], "6f1c0f0e-0000-4000-8000-000000000000"]}
    assert (await client.post("/shift-scenarios/compare", json=missing, headers=h)).status_code == 404


async def test_actual_work_session_link(client: httpx.AsyncClient, h: dict) -> None:
    ws = await client.post(
        "/work-sessions",
        json={"started_at": "2026-11-09T17:00:00+07:00", "ended_at": "2026-11-09T21:30:00+07:00"},
        headers=h,
    )
    sid = (await create(client, h, {**DINNER, "actual_work_session_id": ws.json()["id"]}))["id"]
    bad = {"actual_work_session_id": "6f1c0f0e-0000-4000-8000-000000000000"}
    resp = await client.patch(f"/shift-scenarios/{sid}", json=bad, headers=h)
    assert resp.status_code == 400 and resp.json()["error"]["code"] == "invalid_work_session"
    await client.delete(f"/work-sessions/{ws.json()['id']}", headers=h)
    assert (await client.get(f"/shift-scenarios/{sid}", headers=h)).json()["actual_work_session_id"] is None


async def test_estimates_are_not_counted_as_actuals(client: httpx.AsyncClient, h: dict) -> None:
    await create(client, h, DINNER)
    summary = (await client.get("/profit/summary?period=month", headers=h)).json()
    assert summary["total_revenue"] == "0.00" and summary["work_session_count"] == 0


async def test_historical_method(client: httpx.AsyncClient, h: dict, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(shifts_service, "today_in", lambda zone: date(2026, 11, 22))
    # Five Mondays, 2 h each: revenue 300, expenses 20 -> 150/h revenue, 10/h expenses, 140/h net.
    monday = date(2026, 11, 16)
    for week in range(5):
        day = monday - timedelta(weeks=week)
        await client.post(
            "/work-sessions",
            json={"started_at": f"{day}T18:00:00+07:00", "ended_at": f"{day}T20:00:00+07:00"},
            headers=h,
        )
        await client.post("/income", json={"occurred_on": str(day), "amount": 300}, headers=h)
        await client.post(
            "/expenses", json={"occurred_on": str(day), "category": "fuel", "amount": 20}, headers=h
        )

    body = await create(
        client,
        h,
        {
            "name": "Monday evening",
            "start_time": "18:00",
            "end_time": "21:00",
            "planned_weekday": 0,
            "estimation_method": "historical",
            "assumptions": {"other_costs": 10},
        },
    )
    assert body["estimated_revenue"] == "450.00" and body["estimated_expenses"] == "40.00"
    assert body["estimated_net_profit"] == "410.00"
    assert (body["estimate_low"], body["estimate_high"]) == ("410.00", "410.00")  # identical days
    details = body["estimate_details"]
    assert (
        details["basis"] == "same_weekday"
        and details["n_days"] == 5
        and details["timezone"] == "Asia/Bangkok"
    )
    assert (details["window_start"], details["window_end"]) == ("2026-08-31", "2026-11-22")

    tuesday = await create(
        client,
        h,
        {
            "name": "Tuesday",
            "start_time": "18:00",
            "end_time": "21:00",
            "planned_weekday": 1,
            "estimation_method": "historical",
        },
    )
    assert tuesday["estimate_details"]["basis"] == "all_days"


async def test_historical_needs_enough_days(client: httpx.AsyncClient, h: dict) -> None:
    body = await create(client, h, {**DINNER, "estimation_method": "historical"}, status=400)
    assert body["error"]["code"] == "insufficient_history"
    assert body["error"]["details"] == [{"n_days": 0, "required": 5}]
