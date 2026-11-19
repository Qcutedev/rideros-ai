"""Client-generated ids on create (the app's offline queue resends a create it never got an answer for)."""

import uuid

import httpx
import pytest

from app.modules.profit import repository as profit_repo
from tests.helpers import auth_headers


@pytest.fixture
async def h(client: httpx.AsyncClient) -> dict[str, str]:
    return await auth_headers(client, "rider@example.com")


def ws(start: str, end: str, **extra: object) -> dict:
    return {"started_at": f"2026-11-09T{start}:00+07:00", "ended_at": f"2026-11-09T{end}:00+07:00", **extra}


def income(**extra: object) -> dict:
    return {"occurred_on": "2026-11-09", "amount": "420.50", **extra}


def expense(**extra: object) -> dict:
    return {"occurred_on": "2026-11-09", "category": "fuel", "amount": "80", **extra}


PAYLOADS = {"/work-sessions": ws("10:00", "14:00"), "/income": income(), "/expenses": expense()}


@pytest.mark.parametrize("path", list(PAYLOADS))
async def test_the_record_keeps_the_client_id(client: httpx.AsyncClient, h: dict, path: str) -> None:
    rid = str(uuid.uuid4())
    resp = await client.post(path, json={**PAYLOADS[path], "id": rid}, headers=h)
    assert resp.status_code == 201 and resp.json()["id"] == rid
    assert (await client.get(f"{path}/{rid}", headers=h)).json() == resp.json()


@pytest.mark.parametrize("path", list(PAYLOADS))
async def test_a_resent_id_returns_the_stored_record(client: httpx.AsyncClient, h: dict, path: str) -> None:
    rid = str(uuid.uuid4())
    first = await client.post(path, json={**PAYLOADS[path], "id": rid}, headers=h)
    assert first.status_code == 201

    again = await client.post(path, json={**PAYLOADS[path], "id": rid}, headers=h)
    assert again.status_code == 200 and again.json() == first.json()

    # A different body under the same id changes nothing: the first create wins.
    changed = {
        "/work-sessions": ws("15:00", "16:00", id=rid),
        "/income": income(id=rid, amount="1"),
        "/expenses": expense(id=rid, amount="1", category="other"),
    }[path]
    resp = await client.post(path, json=changed, headers=h)
    assert resp.status_code == 200 and resp.json() == first.json()
    assert len((await client.get(path, headers=h)).json()["items"]) == 1


async def test_a_resent_session_does_not_overlap_itself(client: httpx.AsyncClient, h: dict) -> None:
    rid = str(uuid.uuid4())
    resp = await client.post("/work-sessions", json=ws("10:00", "14:00", id=rid), headers=h)
    assert resp.status_code == 201
    resp = await client.post("/work-sessions", json=ws("10:00", "14:00", id=rid), headers=h)
    assert resp.status_code == 200
    # A new id over the same hours is still an overlap.
    resp = await client.post("/work-sessions", json=ws("10:00", "14:00", id=str(uuid.uuid4())), headers=h)
    assert resp.status_code == 409 and resp.json()["error"]["code"] == "work_session_overlap"


async def test_income_links_to_a_session_by_its_client_id(client: httpx.AsyncClient, h: dict) -> None:
    """The queue sends the session first, then the income that already points at its id."""
    sid = str(uuid.uuid4())
    resp = await client.post("/work-sessions", json=ws("10:00", "14:00", id=sid), headers=h)
    assert resp.status_code == 201
    resp = await client.post("/income", json=income(id=str(uuid.uuid4()), work_session_id=sid), headers=h)
    assert resp.status_code == 201 and resp.json()["work_session_id"] == sid


@pytest.mark.parametrize("path", list(PAYLOADS))
async def test_another_users_id_is_a_conflict(client: httpx.AsyncClient, h: dict, path: str) -> None:
    rid = str(uuid.uuid4())
    assert (await client.post(path, json={**PAYLOADS[path], "id": rid}, headers=h)).status_code == 201

    other = await auth_headers(client, "other@example.com")
    resp = await client.post(path, json={**PAYLOADS[path], "id": rid}, headers=other)
    assert resp.status_code == 409 and resp.json()["error"]["code"] == "duplicate_id"
    assert "420" not in resp.text and "fuel" not in resp.text  # nothing of the owner's row leaks
    assert (await client.get(f"{path}/{rid}", headers=other)).status_code == 404


async def test_the_same_id_may_be_used_in_another_table(client: httpx.AsyncClient, h: dict) -> None:
    rid = str(uuid.uuid4())
    assert (await client.post("/income", json=income(id=rid), headers=h)).status_code == 201
    assert (await client.post("/expenses", json=expense(id=rid), headers=h)).status_code == 201


@pytest.mark.parametrize("bad", ["not-a-uuid", 12, ""])
async def test_a_malformed_id_is_422(client: httpx.AsyncClient, h: dict, bad: object) -> None:
    resp = await client.post("/income", json=income(id=bad), headers=h)
    assert resp.status_code == 422 and resp.json()["error"]["code"] == "validation_error"


@pytest.mark.parametrize("path", list(PAYLOADS))
async def test_two_creates_with_one_id_at_once(
    client: httpx.AsyncClient, h: dict, path: str, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Both pass the id check before either commits: the database refuses the second insert,
    and the service answers it with the row of the first."""
    rid = str(uuid.uuid4())
    first = await client.post(path, json={**PAYLOADS[path], "id": rid}, headers=h)
    assert first.status_code == 201

    real_get = profit_repo.get_by_id
    calls = 0

    async def _missed_once(*args: object, **kwargs: object) -> object:
        nonlocal calls
        calls += 1
        return None if calls == 1 else await real_get(*args, **kwargs)  # type: ignore[arg-type]

    async def _no_overlap(*_args: object, **_kwargs: object) -> bool:
        return False

    monkeypatch.setattr(profit_repo, "get_by_id", _missed_once)
    monkeypatch.setattr(profit_repo, "has_overlapping_session", _no_overlap)
    resp = await client.post(path, json={**PAYLOADS[path], "id": rid}, headers=h)
    assert resp.status_code == 200 and resp.json() == first.json()
    assert calls == 2


async def test_an_overlap_race_with_a_new_id_is_still_409(
    client: httpx.AsyncClient, h: dict, monkeypatch: pytest.MonkeyPatch
) -> None:
    assert (await client.post("/work-sessions", json=ws("10:00", "14:00"), headers=h)).status_code == 201

    async def _no_overlap(*_args: object, **_kwargs: object) -> bool:
        return False

    monkeypatch.setattr(profit_repo, "has_overlapping_session", _no_overlap)
    resp = await client.post("/work-sessions", json=ws("12:00", "15:00", id=str(uuid.uuid4())), headers=h)
    assert resp.status_code == 409 and resp.json()["error"]["code"] == "work_session_overlap"


async def test_other_insert_errors_are_not_taken_for_a_resend(
    client: httpx.AsyncClient, h: dict, monkeypatch: pytest.MonkeyPatch
) -> None:
    """A foreign-key failure (session deleted between the link check and the insert) stays a 500."""

    async def _owns(*_args: object, **_kwargs: object) -> bool:
        return True

    monkeypatch.setattr(profit_repo, "owns_work_session", _owns)
    resp = await client.post(
        "/income", json=income(id=str(uuid.uuid4()), work_session_id=str(uuid.uuid4())), headers=h
    )
    assert resp.status_code == 500
    assert (await client.get("/income", headers=h)).json()["items"] == []
