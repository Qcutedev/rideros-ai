"""GET /profit/patterns: K-Means work patterns over the rider's own sessions of the last 180 days."""

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
                user_id=uid, work_session_id=ws.id, occurred_on=day, category="fuel", amount=Decimal(60)
            )
        )


async def add_two_habits(db: AsyncSession, uid: uuid.UUID) -> None:
    """25 weekday evenings (18:00-19:20, ~3 h, 300 income + 60 fuel each) and 12 weekend days
    (08:30-09:30, ~9 h, no income), all within the last 8 weeks."""
    base = week_start(8)
    for i in range(25):
        start = base + timedelta(days=(i // 5) * 7 + i % 5, hours=18, minutes=(i % 5) * 20)
        await add_session(db, uid, start, 3 + (i % 3) * 0.25, income="300")
    for i in range(12):
        start = base + timedelta(days=(i // 2) * 7 + 5 + i % 2, hours=8.5, minutes=(i % 4) * 20)
        await add_session(db, uid, start, 9 - (i % 3) * 0.5)
    await db.commit()


async def patterns(client: httpx.AsyncClient, h: dict) -> dict:
    resp = await client.get("/profit/patterns", headers=h)
    assert resp.status_code == 200, resp.text
    return resp.json()


async def test_requires_auth(client: httpx.AsyncClient) -> None:
    assert (await client.get("/profit/patterns")).status_code == 401


async def test_insufficient_data(client: httpx.AsyncClient) -> None:
    h = await auth_headers(client, "few@example.com")
    start = week_start(1) + timedelta(hours=18)
    for d in range(3):
        body = {
            "started_at": (start + timedelta(days=d)).isoformat(),
            "ended_at": (start + timedelta(days=d, hours=3)).isoformat(),
        }
        assert (await client.post("/work-sessions", json=body, headers=h)).status_code == 201
    body = await patterns(client, h)
    assert body["status"] == "insufficient_data"
    assert (body["session_count"], body["min_sessions"], body["window_days"]) == (3, 30, 180)
    assert body["groups"] == [] and body["k"] is None and body["silhouette"] is None
    assert (body["timezone"], body["currency"]) == ("Asia/Bangkok", "THB")


async def test_finds_groups_with_estimated_profit(client: httpx.AsyncClient, db: AsyncSession) -> None:
    h = await auth_headers(client, "habits@example.com")
    await add_two_habits(db, await user_id(client, h))
    body = await patterns(client, h)
    assert body["status"] == "ok" and body["k"] == 2 and body["session_count"] == 37
    assert body["silhouette"] > body["null_silhouette"] and body["stability"] >= 0.6
    evening, weekend = body["groups"]
    assert (evening["time_of_day"], evening["length"], evening["day_type"]) == ("evening", "short", "weekday")
    assert (weekend["time_of_day"], weekend["length"], weekend["day_type"]) == ("morning", "long", "weekend")
    assert (evening["session_count"], weekend["session_count"]) == (25, 12)
    # 25 × (300 − 60) over 25 × 3 h + 8 × 0.25 h + 8 × 0.5 h (i % 3 cycles: 9/8/8 sessions) = 81 h
    assert evening["profit_session_count"] == 25
    assert evening["net_profit_per_hour"] == str((Decimal(25 * 240) / 81).quantize(Decimal("0.01")))
    assert weekend["profit_session_count"] == 0 and weekend["net_profit_per_hour"] is None


async def test_only_own_recent_sessions_count(client: httpx.AsyncClient, db: AsyncSession) -> None:
    alice = await auth_headers(client, "alice.patterns@example.com")
    bob = await auth_headers(client, "bob.patterns@example.com")
    await add_two_habits(db, await user_id(client, alice))
    bob_id = await user_id(client, bob)
    old = week_start(0) - timedelta(days=200)
    for d in range(35):  # all older than the 180-day window
        await add_session(db, bob_id, old - timedelta(days=d, hours=-18), 3)
    await db.commit()
    body = await patterns(client, bob)
    assert body["status"] == "insufficient_data" and body["session_count"] == 0
    assert (await patterns(client, alice))["session_count"] == 37
