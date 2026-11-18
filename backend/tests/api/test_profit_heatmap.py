"""GET /profit/heatmap: net profit per hour by weekday × 2-hour slot over the last 90 days."""

import uuid
from datetime import datetime, timedelta
from decimal import Decimal
from zoneinfo import ZoneInfo

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.profit.models import ExpenseRecord, IncomeRecord, WorkSession
from tests.helpers import auth_headers

BKK = ZoneInfo("Asia/Bangkok")


def week_start(weeks_ago: int) -> datetime:
    today = datetime.now(BKK).replace(hour=0, minute=0, second=0, microsecond=0)
    return today - timedelta(days=today.weekday() + 7 * weeks_ago)


async def user_id(client: httpx.AsyncClient, h: dict) -> uuid.UUID:
    return uuid.UUID((await client.get("/me", headers=h)).json()["id"])


async def add_session(
    db: AsyncSession, uid: uuid.UUID, start: datetime, hours: float, income: str | None = None
) -> None:
    ws = WorkSession(user_id=uid, started_at=start, ended_at=start + timedelta(hours=hours))
    db.add(ws)
    await db.flush()
    if income is not None:
        day = start.date()
        db.add(IncomeRecord(user_id=uid, work_session_id=ws.id, occurred_on=day, amount=Decimal(income)))
        db.add(
            ExpenseRecord(
                user_id=uid, work_session_id=ws.id, occurred_on=day, category="fuel", amount=Decimal(40)
            )
        )


async def add_mondays(db: AsyncSession, uid: uuid.UUID) -> None:
    """10 Mondays 18:00-20:00 (slot 9) with 400 linked income and 40 linked fuel each."""
    for week in range(1, 11):
        await add_session(db, uid, week_start(week) + timedelta(hours=18), 2, income="400")
    await db.commit()


async def heatmap(client: httpx.AsyncClient, h: dict) -> dict:
    resp = await client.get("/profit/heatmap", headers=h)
    assert resp.status_code == 200, resp.text
    return resp.json()


def cell(body: dict, weekday: int, slot: int) -> dict:
    return next(c for c in body["cells"] if (c["weekday"], c["slot"]) == (weekday, slot))


async def test_requires_auth(client: httpx.AsyncClient) -> None:
    assert (await client.get("/profit/heatmap")).status_code == 401


async def test_insufficient_data(client: httpx.AsyncClient) -> None:
    h = await auth_headers(client, "heat.few@example.com")
    start = week_start(1) + timedelta(hours=18)
    for d in range(3):
        body = {
            "started_at": (start + timedelta(days=d)).isoformat(),
            "ended_at": (start + timedelta(days=d, hours=3)).isoformat(),
        }
        assert (await client.post("/work-sessions", json=body, headers=h)).status_code == 201
    body = await heatmap(client, h)
    assert body["status"] == "insufficient_data" and body["cells"] == []
    assert (body["session_count"], body["excluded_session_count"]) == (0, 3)  # no income recorded
    assert (body["min_sessions"], body["window_days"], body["slot_hours"]) == (10, 90, 2)
    assert (body["min_cell_sessions"], body["min_cell_hours"]) == (2, 1)
    assert body["net_profit_per_hour"] is None and body["hours"] == "0.0"
    assert (body["timezone"], body["currency"]) == ("Asia/Bangkok", "THB")


async def test_places_linked_and_same_day_money(client: httpx.AsyncClient, db: AsyncSession) -> None:
    h = await auth_headers(client, "heat.ok@example.com")
    uid = await user_id(client, h)
    await add_mondays(db, uid)
    tuesday = week_start(1) + timedelta(days=1)
    await add_session(db, uid, tuesday + timedelta(hours=10), 1)  # no linked income
    db.add(IncomeRecord(user_id=uid, occurred_on=tuesday.date(), amount=Decimal(250)))  # same day, unlinked
    db.add(IncomeRecord(user_id=uid, occurred_on=(tuesday + timedelta(days=1)).date(), amount=Decimal(99)))
    db.add(  # own working hours: untimed work, never placed
        IncomeRecord(user_id=uid, occurred_on=tuesday.date(), amount=Decimal(500), working_hours=Decimal(4))
    )
    await db.commit()

    body = await heatmap(client, h)
    assert body["status"] == "ok" and body["session_count"] == 11
    assert (body["excluded_session_count"], body["excluded_income_count"]) == (0, 2)
    monday = cell(body, 0, 9)
    assert (monday["hours"], monday["session_count"]) == ("20.0", 10)
    assert (monday["revenue_per_hour"], monday["net_profit_per_hour"]) == ("200.00", "180.00")
    single = cell(body, 1, 5)  # Tuesday 10:00-11:00, one session: below the cell minimum
    assert (single["hours"], single["session_count"], single["net_profit_per_hour"]) == ("1.0", 1, None)
    # 10 × 360 + 250 over 21 h
    assert body["net_profit_per_hour"] == str((Decimal(3850) / 21).quantize(Decimal("0.01")))
    assert body["hours"] == "21.0"


async def test_only_own_recent_sessions_count(client: httpx.AsyncClient, db: AsyncSession) -> None:
    alice = await auth_headers(client, "alice.heat@example.com")
    bob = await auth_headers(client, "bob.heat@example.com")
    await add_mondays(db, await user_id(client, alice))
    bob_id = await user_id(client, bob)
    for week in range(14, 26):  # all older than the 90-day window
        await add_session(db, bob_id, week_start(week) + timedelta(hours=18), 2, income="400")
    await db.commit()
    body = await heatmap(client, bob)
    assert body["status"] == "insufficient_data" and body["session_count"] == 0
    assert (await heatmap(client, alice))["session_count"] == 10
