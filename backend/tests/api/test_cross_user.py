"""Data isolation (docs/DATABASE_DESIGN.md §5): user B can never read, change or delete A's data.

Every user-owned endpoint answers 404 for another user's id, and the row stays unchanged.
"""

from pathlib import Path

import httpx
import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import PickupLog, Restaurant, ShiftScenario
from app.modules.pickup.importer import import_restaurant_stats
from tests.helpers import PASSWORD, auth_headers
from tests.pickup_data import write_stats

SESSION = {"started_at": "2026-11-09T10:00:00+07:00", "ended_at": "2026-11-09T14:00:00+07:00"}
RESOURCES = {
    "work-sessions": (SESSION, {"notes": "hacked"}),
    "income": ({"occurred_on": "2026-11-09", "amount": "500"}, {"amount": "1"}),
    "expenses": ({"occurred_on": "2026-11-09", "category": "fuel", "amount": "80"}, {"amount": "1"}),
}


@pytest.fixture
async def users(client: httpx.AsyncClient) -> tuple[dict, dict]:
    return await auth_headers(client, "alice@example.com"), await auth_headers(client, "bob@example.com")


@pytest.mark.parametrize("resource", list(RESOURCES))
async def test_other_users_resource_is_404_and_unchanged(
    client: httpx.AsyncClient, users: tuple[dict, dict], resource: str
) -> None:
    alice, bob = users
    create, patch = RESOURCES[resource]
    created = (await client.post(f"/{resource}", json=create, headers=alice)).json()
    url = f"/{resource}/{created['id']}"

    for method, body in (("GET", None), ("PATCH", patch), ("DELETE", None)):
        resp = await client.request(method, url, json=body, headers=bob)
        assert resp.status_code == 404, (method, resp.text)
        assert resp.json()["error"]["code"].endswith("_not_found")

    # Bob's 404 looks exactly like an id that does not exist at all.
    missing = await client.get(f"/{resource}/6f1c0f0e-0000-4000-8000-000000000000", headers=bob)
    assert missing.json() == (await client.get(url, headers=bob)).json()

    resp = await client.get(url, headers=alice)
    assert resp.status_code == 200 and resp.json() == created


@pytest.mark.parametrize("resource", list(RESOURCES))
async def test_lists_only_show_own_rows(
    client: httpx.AsyncClient, users: tuple[dict, dict], resource: str
) -> None:
    alice, bob = users
    create, _ = RESOURCES[resource]
    await client.post(f"/{resource}", json=create, headers=alice)
    assert (await client.get(f"/{resource}", headers=bob)).json() == {"items": [], "next_cursor": None}
    assert len((await client.get(f"/{resource}", headers=alice)).json()["items"]) == 1


async def test_cannot_link_records_to_another_users_session(
    client: httpx.AsyncClient, users: tuple[dict, dict]
) -> None:
    alice, bob = users
    sid = (await client.post("/work-sessions", json=SESSION, headers=alice)).json()["id"]
    for path, body in (
        ("/income", {"occurred_on": "2026-11-09", "amount": 1, "work_session_id": sid}),
        ("/expenses", {"occurred_on": "2026-11-09", "category": "fuel", "amount": 1, "work_session_id": sid}),
    ):
        resp = await client.post(path, json=body, headers=bob)
        assert resp.status_code == 400 and resp.json()["error"]["code"] == "invalid_work_session"

    own = (await client.post("/income", json={"occurred_on": "2026-11-09", "amount": 1}, headers=bob)).json()
    resp = await client.patch(f"/income/{own['id']}", json={"work_session_id": sid}, headers=bob)
    assert resp.status_code == 400
    # Filtering by someone else's session id simply finds nothing.
    assert (await client.get(f"/income?work_session_id={sid}", headers=bob)).json()["items"] == []


async def test_sessions_of_different_users_may_overlap(
    client: httpx.AsyncClient, users: tuple[dict, dict]
) -> None:
    alice, bob = users
    assert (await client.post("/work-sessions", json=SESSION, headers=alice)).status_code == 201
    assert (await client.post("/work-sessions", json=SESSION, headers=bob)).status_code == 201


async def test_summaries_and_trends_only_count_own_data(
    client: httpx.AsyncClient, users: tuple[dict, dict]
) -> None:
    alice, bob = users
    await client.post("/work-sessions", json=SESSION, headers=alice)
    await client.post("/income", json={"occurred_on": "2026-11-09", "amount": "500"}, headers=alice)
    await client.post(
        "/expenses", json={"occurred_on": "2026-11-09", "category": "fuel", "amount": 9}, headers=alice
    )

    bob_day = (await client.get("/profit/summary?period=day&date=2026-11-09", headers=bob)).json()
    assert bob_day["total_revenue"] == "0.00" and bob_day["total_expenses"] == "0.00"
    assert bob_day["work_session_count"] == 0
    bob_trend = (await client.get("/profit/trends?from=2026-11-09&to=2026-11-09", headers=bob)).json()
    assert bob_trend["points"][0]["income_count"] == 0

    alice_day = (await client.get("/profit/summary?period=day&date=2026-11-09", headers=alice)).json()
    assert alice_day["total_revenue"] == "500.00" and alice_day["work_session_count"] == 1


async def test_rider_profiles_are_separate(client: httpx.AsyncClient, users: tuple[dict, dict]) -> None:
    alice, bob = users
    await client.put("/me/rider-profile", json={"vehicle_type": "car", "timezone": "UTC"}, headers=alice)
    bob_profile = (await client.get("/me/rider-profile", headers=bob)).json()
    assert bob_profile["is_configured"] is False and bob_profile["timezone"] == "Asia/Bangkok"


async def test_patch_me_only_changes_the_caller(client: httpx.AsyncClient, users: tuple[dict, dict]) -> None:
    alice, bob = users
    await client.patch("/me", json={"display_name": "Bobby"}, headers=bob)
    assert (await client.get("/me", headers=alice)).json()["display_name"] == "alice"


# ---- P2c: pickup + shift simulator ----

DINNER = {
    "name": "Dinner",
    "start_time": "17:00",
    "end_time": "21:00",
    "assumptions": {"orders_per_hour": 2, "income_per_order": 40},
}


def pickup_log(restaurant_id: str, day: int = 9, wait: int = 5) -> dict:
    return {
        "restaurant_id": restaurant_id,
        "arrived_at": f"2026-11-{day:02d}T12:00:00+07:00",
        "picked_up_at": f"2026-11-{day:02d}T12:{wait:02d}:00+07:00",
    }


async def test_private_restaurants_and_their_data(
    client: httpx.AsyncClient, users: tuple[dict, dict]
) -> None:
    alice, bob = users
    shop = (await client.post("/pickup/restaurants", json={"name": "Alice's shop"}, headers=alice)).json()
    alice_log = (await client.post("/pickup/logs", json=pickup_log(shop["id"]), headers=alice)).json()

    assert (await client.get("/pickup/restaurants", headers=bob)).json()["items"] == []
    assert (await client.get("/pickup/restaurants?q=Alice", headers=bob)).json()["items"] == []
    for path in ("analytics", "wait-stats"):
        resp = await client.get(f"/pickup/restaurants/{shop['id']}/{path}", headers=bob)
        assert resp.status_code == 404 and resp.json()["error"]["code"] == "restaurant_not_found"
    assert (await client.post("/pickup/logs", json=pickup_log(shop["id"]), headers=bob)).status_code == 404
    resp = await client.post("/pickup/predictions", json={"restaurant_id": shop["id"]}, headers=bob)
    assert resp.status_code == 404

    assert (await client.get("/pickup/logs", headers=bob)).json()["items"] == []
    assert (await client.delete(f"/pickup/logs/{alice_log['id']}", headers=bob)).status_code == 404
    assert len((await client.get("/pickup/logs", headers=alice)).json()["items"]) == 1


async def test_dataset_restaurants_are_shared_but_logs_and_predictions_are_not(
    client: httpx.AsyncClient, users: tuple[dict, dict], db: AsyncSession, tmp_path: Path
) -> None:
    alice, bob = users
    await import_restaurant_stats(db, write_stats(tmp_path / "1.0.0"))
    poi = (await client.get("/pickup/restaurants?q=POI-0", headers=alice)).json()["items"][0]
    assert (await client.get("/pickup/restaurants?q=POI-0", headers=bob)).json()["items"][0]["id"] == poi[
        "id"
    ]

    await client.post("/pickup/predictions", json={"restaurant_id": poi["id"]}, headers=alice)
    for day in range(1, 6):
        await client.post("/pickup/logs", json=pickup_log(poi["id"], day=day, wait=day), headers=alice)
    assert (await client.get("/pickup/predictions", headers=bob)).json()["items"] == []
    bob_wait = (await client.get(f"/pickup/restaurants/{poi['id']}/wait-stats", headers=bob)).json()
    assert bob_wait["n"] == 0 and bob_wait["confidence"] == "insufficient"
    alice_wait = (await client.get(f"/pickup/restaurants/{poi['id']}/wait-stats", headers=alice)).json()
    assert alice_wait["n"] == 5


async def test_shift_scenarios_are_private(client: httpx.AsyncClient, users: tuple[dict, dict]) -> None:
    alice, bob = users
    mine = (await client.post("/shift-scenarios", json=DINNER, headers=alice)).json()
    url = f"/shift-scenarios/{mine['id']}"
    for method, path, body in (
        ("GET", url, None),
        ("PATCH", url, {"name": "hacked"}),
        ("DELETE", url, None),
        ("POST", f"{url}/estimate", None),
    ):
        resp = await client.request(method, path, json=body, headers=bob)
        assert resp.status_code == 404 and resp.json()["error"]["code"] == "shift_scenario_not_found", path
    assert (await client.get("/shift-scenarios", headers=bob)).json()["items"] == []

    bobs = (await client.post("/shift-scenarios", json=DINNER, headers=bob)).json()
    resp = await client.post("/shift-scenarios/compare", json={"ids": [bobs["id"], mine["id"]]}, headers=bob)
    assert resp.status_code == 404

    alice_session = (await client.post("/work-sessions", json=SESSION, headers=alice)).json()
    resp = await client.patch(
        f"/shift-scenarios/{bobs['id']}", json={"actual_work_session_id": alice_session["id"]}, headers=bob
    )
    assert resp.status_code == 400 and resp.json()["error"]["code"] == "invalid_work_session"
    assert (await client.get(url, headers=alice)).json() == mine


async def test_delete_me_removes_pickup_and_shift_data(client: httpx.AsyncClient, db: AsyncSession) -> None:
    h = await auth_headers(client, "leaver@example.com")
    shop = (await client.post("/pickup/restaurants", json={"name": "Mine"}, headers=h)).json()
    await client.post("/pickup/logs", json=pickup_log(shop["id"]), headers=h)
    await client.post("/shift-scenarios", json=DINNER, headers=h)
    assert (await client.request("DELETE", "/me", json={"password": PASSWORD}, headers=h)).status_code == 204
    for model in (Restaurant, PickupLog, ShiftScenario):
        assert await db.scalar(select(func.count()).select_from(model)) == 0, model.__tablename__
