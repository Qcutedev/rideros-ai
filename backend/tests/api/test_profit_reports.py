"""GET /profit/summary and /profit/trends: the TrueProfit rules of docs/DATABASE_DESIGN.md §3.7."""

from datetime import UTC, datetime, timedelta

import httpx
import pytest

from app.modules.profit import service as profit_service
from tests.helpers import auth_headers


@pytest.fixture
async def h(client: httpx.AsyncClient) -> dict[str, str]:
    """A rider with one known week of data (time zone: the default Asia/Bangkok).

    Mon 2026-11-09: session 18:00–22:30 (4.5 h) with linked income 600 (its working_hours 4 is
                    ignored), unlinked income 200 with working_hours 1.5, fuel 100.
    Tue 2026-11-10: session 22:00–02:00 next day (4 h, counts on the 10th), income 400.
    Wed 2026-11-11: maintenance 50 only (no hours).
    Sat 2026-10-31: income 999 (previous month, previous week).
    """
    headers = await auth_headers(client, "reports@example.com")

    async def post(path: str, body: dict) -> dict:
        resp = await client.post(path, json=body, headers=headers)
        assert resp.status_code == 201, resp.text
        return resp.json()

    s1 = await post(
        "/work-sessions", {"started_at": "2026-11-09T18:00:00+07:00", "ended_at": "2026-11-09T22:30:00+07:00"}
    )
    await post(
        "/income",
        {"occurred_on": "2026-11-09", "amount": "600", "working_hours": 4, "work_session_id": s1["id"]},
    )
    await post("/income", {"occurred_on": "2026-11-09", "amount": "200", "working_hours": "1.5"})
    await post("/expenses", {"occurred_on": "2026-11-09", "category": "fuel", "amount": "100"})
    await post(
        "/work-sessions", {"started_at": "2026-11-10T22:00:00+07:00", "ended_at": "2026-11-11T02:00:00+07:00"}
    )
    await post("/income", {"occurred_on": "2026-11-10", "amount": "400"})
    await post("/expenses", {"occurred_on": "2026-11-11", "category": "maintenance", "amount": "50"})
    await post("/income", {"occurred_on": "2026-10-31", "amount": "999"})
    return headers


async def summary(client: httpx.AsyncClient, h: dict, period: str, day: str) -> dict:
    resp = await client.get(f"/profit/summary?period={period}&date={day}", headers=h)
    assert resp.status_code == 200, resp.text
    return resp.json()


async def test_day_summary(client: httpx.AsyncClient, h: dict) -> None:
    body = await summary(client, h, "day", "2026-11-09")
    assert body == {
        "period": "day",
        "start_date": "2026-11-09",
        "end_date": "2026-11-09",
        "timezone": "Asia/Bangkok",
        "currency": "THB",
        "total_revenue": "800.00",
        "total_expenses": "100.00",
        "net_profit": "700.00",
        "working_hours": "6.00",  # 4.5 h session + 1.5 h unlinked income; the linked 4 h is not added
        "revenue_per_hour": "133.33",
        "net_profit_per_hour": "116.67",
        "reason": None,
        "income_count": 2,
        "expense_count": 1,
        "work_session_count": 1,
    }


async def test_session_past_midnight_counts_on_its_start_day(client: httpx.AsyncClient, h: dict) -> None:
    tue = await summary(client, h, "day", "2026-11-10")
    assert tue["working_hours"] == "4.00" and tue["work_session_count"] == 1
    assert tue["revenue_per_hour"] == "100.00"
    wed = await summary(client, h, "day", "2026-11-11")
    assert wed["work_session_count"] == 0


async def test_no_working_hours_gives_null_and_reason(client: httpx.AsyncClient, h: dict) -> None:
    wed = await summary(client, h, "day", "2026-11-11")
    assert wed["working_hours"] == "0.00"
    assert wed["revenue_per_hour"] is None and wed["net_profit_per_hour"] is None
    assert wed["reason"] == "no_working_hours"
    assert wed["net_profit"] == "-50.00"


async def test_week_and_month_summary(client: httpx.AsyncClient, h: dict) -> None:
    week = await summary(client, h, "week", "2026-11-12")  # any day of the week works
    assert (week["start_date"], week["end_date"]) == ("2026-11-09", "2026-11-15")
    assert week["total_revenue"] == "1200.00" and week["total_expenses"] == "150.00"
    assert week["working_hours"] == "10.00" and week["net_profit_per_hour"] == "105.00"
    assert (week["income_count"], week["expense_count"], week["work_session_count"]) == (3, 2, 2)

    month = await summary(client, h, "month", "2026-11-30")
    assert (month["start_date"], month["end_date"]) == ("2026-11-01", "2026-11-30")
    assert month["total_revenue"] == "1200.00"
    october = await summary(client, h, "month", "2026-10-01")
    assert october["total_revenue"] == "999.00" and october["reason"] == "no_working_hours"


async def test_summary_uses_the_rider_time_zone(client: httpx.AsyncClient, h: dict) -> None:
    # 05:00+07:00 on the 12th is 22:00Z on the 11th: the local date depends on the profile zone.
    resp = await client.post(
        "/work-sessions",
        json={"started_at": "2026-11-12T05:00:00+07:00", "ended_at": "2026-11-12T07:00:00+07:00"},
        headers=h,
    )
    assert resp.status_code == 201
    assert (await summary(client, h, "day", "2026-11-12"))["work_session_count"] == 1
    assert (await summary(client, h, "day", "2026-11-11"))["work_session_count"] == 0

    assert (await client.put("/me/rider-profile", json={"timezone": "UTC"}, headers=h)).status_code == 200
    utc_11 = await summary(client, h, "day", "2026-11-11")
    assert utc_11["timezone"] == "UTC" and utc_11["work_session_count"] == 1
    assert (await summary(client, h, "day", "2026-11-12"))["work_session_count"] == 0


async def test_summary_defaults_to_today_in_rider_zone(
    client: httpx.AsyncClient, h: dict, monkeypatch: pytest.MonkeyPatch
) -> None:
    fixed = datetime(2026, 11, 9, 18, 0, tzinfo=UTC)  # 01:00 on the 10th in Bangkok
    monkeypatch.setattr(profit_service, "today_in", lambda zone: fixed.astimezone(zone).date())
    body = (await client.get("/profit/summary", headers=h)).json()
    assert body["period"] == "day" and body["start_date"] == "2026-11-10"


async def test_summary_validation(client: httpx.AsyncClient, h: dict) -> None:
    assert (await client.get("/profit/summary?period=year", headers=h)).status_code == 422
    assert (await client.get("/profit/summary?date=2026-13-01", headers=h)).status_code == 422


async def test_empty_account_summary(client: httpx.AsyncClient) -> None:
    other = await auth_headers(client, "empty@example.com")
    body = await summary(client, other, "month", "2026-11-09")
    assert body["total_revenue"] == "0.00" and body["reason"] == "no_working_hours"


async def test_daily_trend_includes_empty_days(client: httpx.AsyncClient, h: dict) -> None:
    resp = await client.get("/profit/trends?granularity=day&from=2026-11-08&to=2026-11-11", headers=h)
    assert resp.status_code == 200
    body = resp.json()
    assert (body["start_date"], body["end_date"], body["timezone"]) == (
        "2026-11-08",
        "2026-11-11",
        "Asia/Bangkok",
    )
    points = {p["start_date"]: p for p in body["points"]}
    assert list(points) == ["2026-11-08", "2026-11-09", "2026-11-10", "2026-11-11"]
    assert (
        points["2026-11-08"]["total_revenue"] == "0.00"
        and points["2026-11-08"]["reason"] == "no_working_hours"
    )
    assert points["2026-11-09"]["net_profit_per_hour"] == "116.67"
    assert points["2026-11-10"]["working_hours"] == "4.00"


async def test_weekly_and_monthly_trends_align_to_buckets(client: httpx.AsyncClient, h: dict) -> None:
    weeks = (
        await client.get("/profit/trends?granularity=week&from=2026-11-04&to=2026-11-11", headers=h)
    ).json()
    assert [(p["start_date"], p["end_date"]) for p in weeks["points"]] == [
        ("2026-11-02", "2026-11-08"),
        ("2026-11-09", "2026-11-15"),
    ]
    assert [p["total_revenue"] for p in weeks["points"]] == ["0.00", "1200.00"]
    assert weeks["start_date"] == "2026-11-02" and weeks["end_date"] == "2026-11-15"

    months = (
        await client.get("/profit/trends?granularity=month&from=2026-10-15&to=2026-11-15", headers=h)
    ).json()
    assert [p["total_revenue"] for p in months["points"]] == ["999.00", "1200.00"]

    # The 2026-10-31 income sits in the week of Mon 2026-10-26.
    weeks = (
        await client.get("/profit/trends?granularity=week&from=2026-10-26&to=2026-11-01", headers=h)
    ).json()
    assert [p["total_revenue"] for p in weeks["points"]] == ["999.00"]


@pytest.mark.parametrize(("granularity", "points"), [("day", 30), ("week", 12), ("month", 12)])
async def test_trend_default_window(
    client: httpx.AsyncClient, h: dict, granularity: str, points: int
) -> None:
    body = (await client.get(f"/profit/trends?granularity={granularity}&to=2026-11-11", headers=h)).json()
    assert len(body["points"]) == points and body["points"][-1]["start_date"] <= "2026-11-11"
    assert body["points"][-1]["end_date"] >= "2026-11-11"


async def test_trend_default_to_is_today(
    client: httpx.AsyncClient, h: dict, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(profit_service, "today_in", lambda zone: datetime(2026, 11, 11).date())
    body = (await client.get("/profit/trends", headers=h)).json()
    assert body["granularity"] == "day" and body["end_date"] == "2026-11-11" and len(body["points"]) == 30


@pytest.mark.parametrize(
    ("query", "status", "code"),
    [
        ("granularity=day&from=2026-11-10&to=2026-11-01", 400, "invalid_date_range"),
        ("granularity=day&from=2025-01-01&to=2026-12-31", 400, "range_too_large"),
        ("granularity=hour", 422, "validation_error"),
    ],
)
async def test_trend_errors(client: httpx.AsyncClient, h: dict, query: str, status: int, code: str) -> None:
    resp = await client.get(f"/profit/trends?{query}", headers=h)
    assert resp.status_code == status and resp.json()["error"]["code"] == code


async def test_trend_analysis_needs_four_buckets_with_records(client: httpx.AsyncClient, h: dict) -> None:
    body = (
        await client.get("/profit/trends?granularity=day&from=2026-11-08&to=2026-11-11", headers=h)
    ).json()
    assert body["analysis"] == {
        "status": "insufficient_data",
        "moving_average_window": 7,
        "active_buckets": 3,
        "min_active_buckets": 4,
        "direction": None,
        "slope_per_bucket": None,
        "p_value": None,
    }
    assert all(
        p["net_profit_moving_average"] is None and p["net_profit_trend"] is None for p in body["points"]
    )


async def test_trend_analysis_finds_a_weekly_rise(client: httpx.AsyncClient) -> None:
    """Six weeks of income rising 100 a week: up, slope 100, a line on every week, MA from week 4."""
    headers = await auth_headers(client, "trend.up@example.com")
    for week in range(6):
        day = datetime(2026, 9, 7).date() + timedelta(weeks=week)  # Mondays
        resp = await client.post(
            "/income", json={"occurred_on": str(day), "amount": str(500 + 100 * week)}, headers=headers
        )
        assert resp.status_code == 201
    body = (
        await client.get("/profit/trends?granularity=week&from=2026-08-31&to=2026-10-18", headers=headers)
    ).json()
    assert body["analysis"]["status"] == "ok" and body["analysis"]["direction"] == "up"
    assert body["analysis"]["slope_per_bucket"] == "100.00" and body["analysis"]["active_buckets"] == 6
    points = body["points"]  # week of 08-31 (empty) + the six weeks
    assert points[0]["net_profit_trend"] is None and points[0]["net_profit_moving_average"] is None
    assert [p["net_profit_trend"] for p in points[1:]] == [
        "500.00",
        "600.00",
        "700.00",
        "800.00",
        "900.00",
        "1000.00",
    ]
    assert [p["net_profit_moving_average"] for p in points[1:]] == [
        None,
        None,
        None,
        "650.00",
        "750.00",
        "850.00",
    ]


async def test_trend_max_range_is_allowed(client: httpx.AsyncClient, h: dict) -> None:
    first = datetime(2026, 1, 1).date()
    last = first + timedelta(days=365)  # 366 points
    resp = await client.get(f"/profit/trends?granularity=day&from={first}&to={last}", headers=h)
    assert resp.status_code == 200 and len(resp.json()["points"]) == 366
