"""CRUD, validation and pagination for /work-sessions, /income and /expenses."""

import httpx
import pytest

from app.core.pagination import encode_cursor
from app.modules.profit import repository as profit_repo
from tests.helpers import auth_headers


@pytest.fixture
async def h(client: httpx.AsyncClient) -> dict[str, str]:
    return await auth_headers(client, "rider@example.com")


def ws(start: str, end: str, **extra: object) -> dict:
    return {"started_at": f"2026-11-09T{start}:00+07:00", "ended_at": f"2026-11-09T{end}:00+07:00", **extra}


# ---- work sessions ----


async def test_work_session_crud(client: httpx.AsyncClient, h: dict) -> None:
    resp = await client.post(
        "/work-sessions", json=ws("10:00", "14:00", distance_km="52.3", order_count=9), headers=h
    )
    assert resp.status_code == 201
    created = resp.json()
    assert created["started_at"] == "2026-11-09T03:00:00Z"  # stored and returned in UTC
    assert created["distance_km"] == "52.30" and created["order_count"] == 9 and created["is_demo"] is False

    sid = created["id"]
    assert (await client.get(f"/work-sessions/{sid}", headers=h)).json() == created

    resp = await client.patch(f"/work-sessions/{sid}", json={"notes": "rain", "order_count": None}, headers=h)
    assert resp.status_code == 200
    assert resp.json()["notes"] == "rain" and resp.json()["order_count"] is None
    assert resp.json()["distance_km"] == "52.30"  # untouched

    assert (await client.delete(f"/work-sessions/{sid}", headers=h)).status_code == 204
    resp = await client.get(f"/work-sessions/{sid}", headers=h)
    assert resp.status_code == 404 and resp.json()["error"]["code"] == "work_session_not_found"
    assert (await client.delete(f"/work-sessions/{sid}", headers=h)).status_code == 404


@pytest.mark.parametrize(
    ("payload", "status", "code"),
    [
        (ws("14:00", "10:00"), 400, "invalid_time_range"),
        (ws("10:00", "10:00"), 400, "invalid_time_range"),
        (
            {"started_at": "2026-11-09T10:00:00+07:00", "ended_at": "2026-11-10T10:00:01+07:00"},
            400,
            "work_session_too_long",
        ),
        ({"started_at": "2026-11-09T10:00:00", "ended_at": "2026-11-09T12:00:00"}, 422, "validation_error"),
        (ws("10:00", "12:00", distance_km=-1), 422, "validation_error"),
        (ws("10:00", "12:00", order_count=-1), 422, "validation_error"),
        (ws("10:00", "12:00", notes="x" * 501), 422, "validation_error"),
        (ws("10:00", "12:00", is_demo=True), 422, "validation_error"),
    ],
    ids=[
        "reversed",
        "zero-length",
        "over-24h",
        "naive-datetime",
        "neg-distance",
        "neg-orders",
        "long-notes",
        "is_demo",
    ],
)
async def test_work_session_validation(
    client: httpx.AsyncClient, h: dict, payload: dict, status: int, code: str
) -> None:
    resp = await client.post("/work-sessions", json=payload, headers=h)
    assert resp.status_code == status and resp.json()["error"]["code"] == code


async def test_exactly_24_hours_is_allowed(client: httpx.AsyncClient, h: dict) -> None:
    payload = {"started_at": "2026-11-09T10:00:00+07:00", "ended_at": "2026-11-10T10:00:00+07:00"}
    assert (await client.post("/work-sessions", json=payload, headers=h)).status_code == 201


async def test_work_sessions_cannot_overlap(client: httpx.AsyncClient, h: dict) -> None:
    assert (await client.post("/work-sessions", json=ws("10:00", "14:00"), headers=h)).status_code == 201
    resp = await client.post("/work-sessions", json=ws("13:59", "16:00"), headers=h)
    assert resp.status_code == 409 and resp.json()["error"]["code"] == "work_session_overlap"
    resp = await client.post("/work-sessions", json=ws("11:00", "12:00"), headers=h)  # inside
    assert resp.status_code == 409
    # Touching end-to-start is fine.
    later = await client.post("/work-sessions", json=ws("14:00", "16:00"), headers=h)
    assert later.status_code == 201

    # Moving a session onto another one is rejected; moving it within its own slot is fine.
    sid = later.json()["id"]
    resp = await client.patch(
        f"/work-sessions/{sid}", json={"started_at": "2026-11-09T13:00:00+07:00"}, headers=h
    )
    assert resp.status_code == 409
    resp = await client.patch(
        f"/work-sessions/{sid}", json={"ended_at": "2026-11-09T17:00:00+07:00"}, headers=h
    )
    assert resp.status_code == 200


async def test_overlap_race_is_caught_by_the_database(
    client: httpx.AsyncClient, h: dict, monkeypatch: pytest.MonkeyPatch
) -> None:
    """If two writes pass the service check at once, the exclusion constraint still refuses one."""
    assert (await client.post("/work-sessions", json=ws("10:00", "14:00"), headers=h)).status_code == 201

    async def _no_overlap(*_args: object, **_kwargs: object) -> bool:
        return False

    monkeypatch.setattr(profit_repo, "has_overlapping_session", _no_overlap)
    resp = await client.post("/work-sessions", json=ws("12:00", "15:00"), headers=h)
    assert resp.status_code == 409 and resp.json()["error"]["code"] == "work_session_overlap"


@pytest.mark.parametrize(
    ("payload", "status", "code"),
    [
        ({"started_at": None}, 422, "validation_error"),
        ({"ended_at": "2026-11-09T09:00:00+07:00"}, 400, "invalid_time_range"),
        ({"ended_at": "2026-11-11T09:00:00+07:00"}, 400, "work_session_too_long"),
    ],
    ids=["null-start", "end-before-start", "too-long"],
)
async def test_work_session_patch_validation(
    client: httpx.AsyncClient, h: dict, payload: dict, status: int, code: str
) -> None:
    sid = (await client.post("/work-sessions", json=ws("10:00", "14:00"), headers=h)).json()["id"]
    resp = await client.patch(f"/work-sessions/{sid}", json=payload, headers=h)
    assert resp.status_code == status and resp.json()["error"]["code"] == code
    assert (await client.get(f"/work-sessions/{sid}", headers=h)).json()["ended_at"] == "2026-11-09T07:00:00Z"


async def test_deleting_a_session_keeps_linked_records(client: httpx.AsyncClient, h: dict) -> None:
    sid = (await client.post("/work-sessions", json=ws("10:00", "14:00"), headers=h)).json()["id"]
    inc = await client.post(
        "/income", json={"occurred_on": "2026-11-09", "amount": 300, "work_session_id": sid}, headers=h
    )
    exp = await client.post(
        "/expenses",
        json={"occurred_on": "2026-11-09", "category": "fuel", "amount": 80, "work_session_id": sid},
        headers=h,
    )
    assert (await client.delete(f"/work-sessions/{sid}", headers=h)).status_code == 204
    assert (await client.get(f"/income/{inc.json()['id']}", headers=h)).json()["work_session_id"] is None
    assert (await client.get(f"/expenses/{exp.json()['id']}", headers=h)).json()["work_session_id"] is None


async def test_work_session_list_filters_by_local_date(client: httpx.AsyncClient, h: dict) -> None:
    # 00:30 local on the 10th is still the 9th in UTC; the filter uses the rider's time zone.
    await client.post(
        "/work-sessions",
        json={"started_at": "2026-11-10T00:30:00+07:00", "ended_at": "2026-11-10T03:00:00+07:00"},
        headers=h,
    )
    await client.post("/work-sessions", json=ws("10:00", "12:00"), headers=h)
    on_10th = (await client.get("/work-sessions?from=2026-11-10&to=2026-11-10", headers=h)).json()
    assert [i["started_at"] for i in on_10th["items"]] == ["2026-11-09T17:30:00Z"]
    assert len((await client.get("/work-sessions?to=2026-11-09", headers=h)).json()["items"]) == 1
    assert len((await client.get("/work-sessions?from=2026-11-09", headers=h)).json()["items"]) == 2


# ---- income ----


async def test_income_crud(client: httpx.AsyncClient, h: dict) -> None:
    payload = {
        "occurred_on": "2026-11-09",
        "amount": "1250.50",
        "order_count": 14,
        "distance_km": 61.2,
        "working_hours": "7.5",
        "source_label": "  Grab ",
        "notes": "evening",
    }
    resp = await client.post("/income", json=payload, headers=h)
    assert resp.status_code == 201
    body = resp.json()
    assert body["amount"] == "1250.50" and body["source_label"] == "Grab" and body["working_hours"] == "7.50"

    iid = body["id"]
    resp = await client.patch(f"/income/{iid}", json={"amount": 1300, "notes": None}, headers=h)
    assert resp.status_code == 200 and resp.json()["amount"] == "1300.00" and resp.json()["notes"] is None
    assert resp.json()["order_count"] == 14

    assert (await client.delete(f"/income/{iid}", headers=h)).status_code == 204
    resp = await client.get(f"/income/{iid}", headers=h)
    assert resp.status_code == 404 and resp.json()["error"]["code"] == "income_not_found"
    assert (await client.patch(f"/income/{iid}", json={"amount": 1}, headers=h)).status_code == 404
    assert (await client.delete(f"/income/{iid}", headers=h)).status_code == 404


@pytest.mark.parametrize(
    "payload",
    [
        {"occurred_on": "2026-11-09", "amount": -1},
        {"occurred_on": "2026-11-09", "amount": "10.555"},
        {"occurred_on": "2026-11-09", "amount": "10000000000.00"},
        {"occurred_on": "2026-11-09", "amount": 10, "working_hours": 0},
        {"occurred_on": "2026-11-09", "amount": 10, "working_hours": 24.01},
        {"occurred_on": "2026-11-09", "amount": 10, "source_label": "x" * 51},
        {"occurred_on": "1999-12-31", "amount": 10},
        {"occurred_on": "not-a-date", "amount": 10},
        {"amount": 10},
        {"occurred_on": "2026-11-09", "amount": "abc"},
        {"occurred_on": "2026-11-09", "amount": 10, "user_id": "00000000-0000-0000-0000-000000000000"},
    ],
    ids=[
        "negative",
        "3-decimals",
        "too-big",
        "zero-hours",
        "over-24-hours",
        "long-label",
        "too-old",
        "bad-date",
        "missing-date",
        "not-a-number",
        "extra-user_id",
    ],
)
async def test_income_validation(client: httpx.AsyncClient, h: dict, payload: dict) -> None:
    resp = await client.post("/income", json=payload, headers=h)
    assert resp.status_code == 422 and resp.json()["error"]["code"] == "validation_error"


async def test_income_patch_cannot_null_required_fields(client: httpx.AsyncClient, h: dict) -> None:
    iid = (await client.post("/income", json={"occurred_on": "2026-11-09", "amount": 5}, headers=h)).json()[
        "id"
    ]
    for field in ("amount", "occurred_on"):
        assert (await client.patch(f"/income/{iid}", json={field: None}, headers=h)).status_code == 422


async def test_income_link_to_unknown_session(client: httpx.AsyncClient, h: dict) -> None:
    payload = {
        "occurred_on": "2026-11-09",
        "amount": 5,
        "work_session_id": "6f1c0f0e-0000-4000-8000-000000000000",
    }
    resp = await client.post("/income", json=payload, headers=h)
    assert resp.status_code == 400 and resp.json()["error"]["code"] == "invalid_work_session"


async def test_income_link_and_unlink_session(client: httpx.AsyncClient, h: dict) -> None:
    sid = (await client.post("/work-sessions", json=ws("10:00", "14:00"), headers=h)).json()["id"]
    iid = (await client.post("/income", json={"occurred_on": "2026-11-09", "amount": 5}, headers=h)).json()[
        "id"
    ]
    resp = await client.patch(f"/income/{iid}", json={"work_session_id": sid}, headers=h)
    assert resp.json()["work_session_id"] == sid
    listed = (await client.get(f"/income?work_session_id={sid}", headers=h)).json()["items"]
    assert [i["id"] for i in listed] == [iid]
    resp = await client.patch(f"/income/{iid}", json={"work_session_id": None}, headers=h)
    assert resp.json()["work_session_id"] is None


async def test_income_pagination_and_filters(client: httpx.AsyncClient, h: dict) -> None:
    ids_by_day = {}
    for day in range(1, 8):
        resp = await client.post("/income", json={"occurred_on": f"2026-11-0{day}", "amount": day}, headers=h)
        ids_by_day[day] = resp.json()["id"]
    same_day = (
        await client.post("/income", json={"occurred_on": "2026-11-07", "amount": 99}, headers=h)
    ).json()

    seen: list[str] = []
    cursor = None
    while True:
        url = "/income?limit=3" + (f"&cursor={cursor}" if cursor else "")
        page = (await client.get(url, headers=h)).json()
        seen += [i["id"] for i in page["items"]]
        cursor = page["next_cursor"]
        if cursor is None:
            break
    # Newest date first; within a date the record created last comes first; no duplicates or gaps.
    assert seen == [same_day["id"]] + [ids_by_day[d] for d in range(7, 0, -1)]

    page = (await client.get("/income?from=2026-11-03&to=2026-11-04", headers=h)).json()
    assert [i["amount"] for i in page["items"]] == ["4.00", "3.00"] and page["next_cursor"] is None


@pytest.mark.parametrize(
    ("query", "status", "code"),
    [
        ("cursor=garbage", 400, "invalid_cursor"),
        (f"cursor={encode_cursor(['x', 'y', 'z'])}", 400, "invalid_cursor"),  # right size, bad values
        ("limit=0", 422, "validation_error"),
        ("limit=101", 422, "validation_error"),
        ("from=2026-11-10&to=2026-11-01", 400, "invalid_date_range"),
    ],
)
async def test_list_query_errors(
    client: httpx.AsyncClient, h: dict, query: str, status: int, code: str
) -> None:
    for path in ("/income", "/expenses"):
        resp = await client.get(f"{path}?{query}", headers=h)
        assert resp.status_code == status and resp.json()["error"]["code"] == code, path


@pytest.mark.parametrize(
    ("query", "status", "code"),
    [
        ("cursor=garbage", 400, "invalid_cursor"),
        (f"cursor={encode_cursor(['x', 'y'])}", 400, "invalid_cursor"),
        ("from=2026-11-10&to=2026-11-01", 400, "invalid_date_range"),
    ],
)
async def test_session_list_query_errors(
    client: httpx.AsyncClient, h: dict, query: str, status: int, code: str
) -> None:
    resp = await client.get(f"/work-sessions?{query}", headers=h)
    assert resp.status_code == status and resp.json()["error"]["code"] == code


async def test_work_session_pagination(client: httpx.AsyncClient, h: dict) -> None:
    for hour in range(10, 15):
        await client.post("/work-sessions", json=ws(f"{hour}:00", f"{hour}:30"), headers=h)
    first = (await client.get("/work-sessions?limit=2", headers=h)).json()
    second = (await client.get(f"/work-sessions?limit=2&cursor={first['next_cursor']}", headers=h)).json()
    third = (await client.get(f"/work-sessions?limit=2&cursor={second['next_cursor']}", headers=h)).json()
    starts = [i["started_at"][11:16] for p in (first, second, third) for i in p["items"]]
    assert starts == ["07:00", "06:00", "05:00", "04:00", "03:00"] and third["next_cursor"] is None


# ---- expenses ----


async def test_expense_crud_and_category_filter(client: httpx.AsyncClient, h: dict) -> None:
    fuel = await client.post(
        "/expenses", json={"occurred_on": "2026-11-09", "category": "fuel", "amount": "120.00"}, headers=h
    )
    assert fuel.status_code == 201 and fuel.json()["category"] == "fuel"
    await client.post(
        "/expenses",
        json={"occurred_on": "2026-11-08", "category": "maintenance", "amount": 450, "description": "chain"},
        headers=h,
    )
    only_fuel = (await client.get("/expenses?category=fuel", headers=h)).json()["items"]
    assert [e["id"] for e in only_fuel] == [fuel.json()["id"]]
    assert (await client.get("/expenses?category=food", headers=h)).status_code == 422

    eid = fuel.json()["id"]
    resp = await client.patch(
        f"/expenses/{eid}", json={"category": "other", "description": "toll"}, headers=h
    )
    assert resp.status_code == 200 and resp.json()["category"] == "other"
    assert (await client.patch(f"/expenses/{eid}", json={"category": None}, headers=h)).status_code == 422
    assert (await client.patch(f"/expenses/{eid}", json={"category": "food"}, headers=h)).status_code == 422
    resp = await client.patch(
        f"/expenses/{eid}", json={"work_session_id": "6f1c0f0e-0000-4000-8000-000000000000"}, headers=h
    )
    assert resp.status_code == 400 and resp.json()["error"]["code"] == "invalid_work_session"

    assert (await client.delete(f"/expenses/{eid}", headers=h)).status_code == 204
    resp = await client.get(f"/expenses/{eid}", headers=h)
    assert resp.status_code == 404 and resp.json()["error"]["code"] == "expense_not_found"
    assert (await client.delete(f"/expenses/{eid}", headers=h)).status_code == 404


@pytest.mark.parametrize(
    "payload",
    [
        {"occurred_on": "2026-11-09", "category": "food", "amount": 1},
        {"occurred_on": "2026-11-09", "amount": 1},
        {"occurred_on": "2026-11-09", "category": "fuel", "amount": -0.01},
        {"occurred_on": "2026-11-09", "category": "fuel", "amount": 1, "description": "x" * 501},
    ],
    ids=["bad-category", "missing-category", "negative", "long-description"],
)
async def test_expense_validation(client: httpx.AsyncClient, h: dict, payload: dict) -> None:
    assert (await client.post("/expenses", json=payload, headers=h)).status_code == 422


# ---- auth ----


@pytest.mark.parametrize(
    ("method", "path"),
    [
        ("GET", "/work-sessions"),
        ("POST", "/work-sessions"),
        ("GET", "/income"),
        ("POST", "/income"),
        ("GET", "/expenses"),
        ("POST", "/expenses"),
        ("GET", "/profit/summary"),
        ("GET", "/profit/trends"),
        ("GET", "/income/6f1c0f0e-0000-4000-8000-000000000000"),
        ("PATCH", "/expenses/6f1c0f0e-0000-4000-8000-000000000000"),
        ("DELETE", "/work-sessions/6f1c0f0e-0000-4000-8000-000000000000"),
    ],
)
async def test_trueprofit_requires_auth(client: httpx.AsyncClient, method: str, path: str) -> None:
    resp = await client.request(method, path, json={})
    assert resp.status_code == 401 and resp.json()["error"]["code"] == "not_authenticated"


async def test_bad_resource_id_is_422(client: httpx.AsyncClient, h: dict) -> None:
    assert (await client.get("/income/not-a-uuid", headers=h)).status_code == 422
