"""Pickup Intelligence API: restaurants, analytics, predictions, model info, Pickup Log, importer."""

from collections.abc import AsyncIterator
from datetime import datetime, timedelta
from pathlib import Path

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.main import create_app
from app.modules.pickup.importer import ImportFormatError, import_restaurant_stats
from app.modules.pickup.models import PickupPrediction, Restaurant, RestaurantTimeStat
from tests import fake_artifact
from tests.conftest import make_settings
from tests.helpers import auth_headers
from tests.pickup_data import write_stats


@pytest.fixture
async def dataset(db: AsyncSession, tmp_path: Path) -> dict[str, str]:
    """Imports 3 dataset POIs; returns poi_id -> restaurant id."""
    await import_restaurant_stats(db, write_stats(tmp_path / "1.0.0"))
    rows = await db.execute(select(Restaurant.external_ref, Restaurant.id))
    return {ref: str(rid) for ref, rid in rows}


@pytest.fixture
async def h(client: httpx.AsyncClient) -> dict[str, str]:
    return await auth_headers(client, "picker@example.com")


async def own_restaurant(client: httpx.AsyncClient, h: dict, name: str = "Som Tam Corner", **extra) -> dict:
    resp = await client.post("/pickup/restaurants", json={"name": name, **extra}, headers=h)
    assert resp.status_code == 201, resp.text
    return resp.json()


# ---- importer ----


async def test_import_is_idempotent(db: AsyncSession, tmp_path: Path) -> None:
    folder = write_stats(tmp_path / "1.0.0")
    first = await import_restaurant_stats(db, folder)
    assert (first.restaurants, first.time_cells) == (3, 4)
    assert first.dataset_version == "restaurant_stats/1.0.0 (orders abababababab)"
    again = await import_restaurant_stats(db, folder)
    assert again.restaurants == 3
    assert await db.scalar(select(func.count()).select_from(Restaurant)) == 3
    assert await db.scalar(select(func.count()).select_from(RestaurantTimeStat)) == 4
    skipped = await import_restaurant_stats(db, folder, if_empty=True)
    assert skipped.skipped and skipped.restaurants == 0

    poi0 = (await db.execute(select(Restaurant).where(Restaurant.external_ref == "0"))).scalar_one()
    assert poi0.name == "POI-0" and poi0.location is None and poi0.reference_da_id == "0"
    assert str(poi0.median_min) == "15.408" and poi0.data_availability == "sufficient"


REF_HEADER = (
    "poi_id,n_orders,median_min,p25_min,p75_min,p90_min,reference_da_id,peak_hour,data_availability\n"
)
TIME_HEADER = "poi_id,day_type,hour,n_orders,median_min,p25_min,p75_min,p90_min\n"


@pytest.mark.parametrize(
    ("kwargs", "message"),
    [
        ({"reference": "poi_id,n_orders\n0,1\n"}, "missing columns"),
        (
            {"reference": REF_HEADER + "0,x,1,1,1,1,0,1,sufficient\n", "time_stats": TIME_HEADER},
            "not an integer",
        ),
        (
            {"reference": REF_HEADER + "0,1,1,1,1,1,0,1,plenty\n", "time_stats": TIME_HEADER},
            "data_availability",
        ),
        ({"time_stats": TIME_HEADER + "9,weekday,1,1,1,1,1,1\n"}, "unknown poi"),
        ({"time_stats": TIME_HEADER + "0,holiday,1,1,1,1,1,1\n"}, "day_type"),
        ({"time_stats": TIME_HEADER + "0,weekday,1,1,abc,1,1,1\n"}, "not a number"),
    ],
    ids=["missing-columns", "bad-int", "bad-availability", "unknown-poi", "bad-day-type", "bad-number"],
)
async def test_import_rejects_bad_files(db: AsyncSession, tmp_path: Path, kwargs: dict, message: str) -> None:
    with pytest.raises(ImportFormatError, match=message):
        await import_restaurant_stats(db, write_stats(tmp_path / "1.0.0", **kwargs))
    await db.rollback()


async def test_import_checks_summary_counts(db: AsyncSession, tmp_path: Path) -> None:
    folder = write_stats(tmp_path / "1.0.0")
    (folder / "summary.json").write_text('{"n_restaurants": 99}', encoding="utf-8")
    with pytest.raises(ImportFormatError, match="row counts"):
        await import_restaurant_stats(db, folder)


# ---- restaurants ----


async def test_list_and_search_restaurants(client: httpx.AsyncClient, h: dict, dataset: dict) -> None:
    own = await own_restaurant(client, h, "Zebra Noodles", location={"lat": 13.7563, "lng": 100.5018})
    body = (await client.get("/pickup/restaurants", headers=h)).json()
    names = [r["name"] for r in body["items"]]
    assert names == ["Zebra Noodles", "POI-0", "POI-1", "POI-5"]  # own restaurants first
    first = body["items"][0]
    assert first["is_own"] and not first["supports_prediction"] and first["source"] == "user"
    assert first["location"] == {"lat": pytest.approx(13.7563), "lng": pytest.approx(100.5018)}
    poi0 = body["items"][1]
    assert poi0["supports_prediction"] and poi0["location"] is None and poi0["n_orders"] == 566

    dataset_only = (await client.get("/pickup/restaurants?source=dataset", headers=h)).json()["items"]
    assert [r["name"] for r in dataset_only] == ["POI-0", "POI-1", "POI-5"]
    user_only = (await client.get("/pickup/restaurants?source=user", headers=h)).json()["items"]
    assert [r["id"] for r in user_only] == [own["id"]]
    found = (await client.get("/pickup/restaurants?q=poi-1", headers=h)).json()["items"]
    assert [r["name"] for r in found] == ["POI-1"]
    # LIKE wildcards in q are literal.
    assert (await client.get("/pickup/restaurants?q=%25", headers=h)).json()["items"] == []
    assert (await client.get("/pickup/restaurants?source=all", headers=h)).status_code == 422


async def test_restaurant_pagination(client: httpx.AsyncClient, h: dict, dataset: dict) -> None:
    await own_restaurant(client, h, "A Own")
    seen, cursor = [], None
    while True:
        page = (
            await client.get(
                "/pickup/restaurants?limit=2" + (f"&cursor={cursor}" if cursor else ""), headers=h
            )
        ).json()
        seen += [r["name"] for r in page["items"]]
        if not (cursor := page["next_cursor"]):
            break
    assert seen == ["A Own", "POI-0", "POI-1", "POI-5"]
    assert (await client.get("/pickup/restaurants?cursor=abc", headers=h)).json()["error"][
        "code"
    ] == "invalid_cursor"


@pytest.mark.parametrize(
    "payload",
    [
        {"name": ""},
        {"name": "x" * 121},
        {"name": "a", "location": {"lat": 91, "lng": 0}},
        {"name": "a", "source": "dataset_meituan"},
    ],
    ids=["blank", "long", "bad-lat", "extra-field"],
)
async def test_create_restaurant_validation(client: httpx.AsyncClient, h: dict, payload: dict) -> None:
    assert (await client.post("/pickup/restaurants", json=payload, headers=h)).status_code == 422


# ---- analytics ----


async def test_dataset_analytics(client: httpx.AsyncClient, h: dict, dataset: dict) -> None:
    resp = await client.get(f"/pickup/restaurants/{dataset['0']}/analytics", headers=h)
    assert resp.status_code == 200
    body = resp.json()
    assert body["metric"] == "order_to_pickup_minutes" and body["data_availability"] == "sufficient"
    assert body["overall"] == {
        "n_orders": 566,
        "median_min": "15.408",
        "p25_min": "12.025",
        "p75_min": "19.588",
        "p90_min": "25.108",
        "peak_hour": 11,
    }
    weekday, weekend = body["by_hour"]["weekday"], body["by_hour"]["weekend"]
    assert len(weekday) == len(weekend) == 24 and [c["hour"] for c in weekday] == list(range(24))
    assert weekday[11]["n_orders"] == 40 and weekday[11]["median_min"] == "13.908"
    assert weekday[0] == {
        "hour": 0,
        "n_orders": 0,
        "median_min": None,
        "p25_min": None,
        "p75_min": None,
        "p90_min": None,
    }
    assert weekend[18]["n_orders"] == 2
    assert body["acknowledgement"] == "This research was supported by data provided by Meituan."
    assert body["dataset_version"].startswith("restaurant_stats/1.0.0")


async def test_own_restaurant_analytics_has_no_dataset_stats(client: httpx.AsyncClient, h: dict) -> None:
    own = await own_restaurant(client, h)
    body = (await client.get(f"/pickup/restaurants/{own['id']}/analytics", headers=h)).json()
    assert body["overall"] is None and body["data_availability"] == "insufficient"
    assert body["acknowledgement"] is None and all(c["n_orders"] == 0 for c in body["by_hour"]["weekday"])


async def test_unknown_restaurant_is_404(client: httpx.AsyncClient, h: dict) -> None:
    for path in ("analytics", "wait-stats"):
        resp = await client.get(f"/pickup/restaurants/6f1c0f0e-0000-4000-8000-000000000000/{path}", headers=h)
        assert resp.status_code == 404 and resp.json()["error"]["code"] == "restaurant_not_found"


# ---- predictions ----


async def test_prediction(client: httpx.AsyncClient, h: dict, dataset: dict, db: AsyncSession) -> None:
    resp = await client.post(
        "/pickup/predictions",
        json={"restaurant_id": dataset["0"], "requested_at": "2026-11-09T11:30:00Z"},  # 18:30 in Bangkok
        headers=h,
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()
    point, low, high = (
        float(body["predicted_minutes"]),
        float(body["interval"]["low"]),
        float(body["interval"]["high"]),
    )
    assert low <= point <= high
    assert high == pytest.approx(point + fake_artifact.Q_HIGH, abs=0.011)
    assert low == pytest.approx(max(point + fake_artifact.Q_LOW, 0), abs=0.011)
    assert body["interval"]["nominal_coverage"] == pytest.approx(0.8)
    assert body["metric"] == "order_to_pickup_minutes" and body["model_version"] == fake_artifact.VERSION
    assert body["warnings"] == ["foreign_dataset"] and body["data_availability"] == "sufficient"
    features = body["input_features"]
    assert features["poi_id"] == "0" and features["da_id"] == "0" and features["hour"] == 18
    assert features["local_time"] == "2026-11-09T18:30:00" and features["timezone"] == "Asia/Bangkok"
    assert "waiting time" in body["disclaimer"]
    assert await db.scalar(select(func.count()).select_from(PickupPrediction)) == 1


async def test_prediction_uses_rider_time_zone(client: httpx.AsyncClient, h: dict, dataset: dict) -> None:
    await client.put("/me/rider-profile", json={"timezone": "UTC"}, headers=h)
    body = (
        await client.post(
            "/pickup/predictions",
            json={"restaurant_id": dataset["1"], "requested_at": "2026-11-14T11:30:00Z"},
            headers=h,
        )
    ).json()
    assert body["input_features"]["hour"] == 11 and body["input_features"]["is_weekend"] == 1  # Saturday
    assert body["warnings"] == ["foreign_dataset", "limited_restaurant_data"]


async def test_prediction_defaults_to_now(client: httpx.AsyncClient, h: dict, dataset: dict) -> None:
    before = datetime.now().astimezone()
    body = (await client.post("/pickup/predictions", json={"restaurant_id": dataset["5"]}, headers=h)).json()
    assert datetime.fromisoformat(body["requested_at"]) >= before - timedelta(seconds=1)
    assert body["data_availability"] == "insufficient" and "insufficient_restaurant_data" in body["warnings"]


async def test_prediction_errors(client: httpx.AsyncClient, h: dict, dataset: dict) -> None:
    own = await own_restaurant(client, h)
    resp = await client.post("/pickup/predictions", json={"restaurant_id": own["id"]}, headers=h)
    assert resp.status_code == 400 and resp.json()["error"]["code"] == "restaurant_not_supported"
    resp = await client.post(
        "/pickup/predictions", json={"restaurant_id": "6f1c0f0e-0000-4000-8000-000000000000"}, headers=h
    )
    assert resp.status_code == 404
    resp = await client.post(
        "/pickup/predictions",
        json={"restaurant_id": dataset["0"], "requested_at": "2026-11-09T18:30:00"},
        headers=h,
    )
    assert resp.status_code == 422  # naive datetime


async def test_prediction_history(client: httpx.AsyncClient, h: dict, dataset: dict) -> None:
    ids = []
    for poi in ("0", "1", "5"):
        ids.append(
            (
                await client.post("/pickup/predictions", json={"restaurant_id": dataset[poi]}, headers=h)
            ).json()["id"]
        )
    first = (await client.get("/pickup/predictions?limit=2", headers=h)).json()
    second = (
        await client.get(f"/pickup/predictions?limit=2&cursor={first['next_cursor']}", headers=h)
    ).json()
    assert [p["id"] for p in first["items"] + second["items"]] == ids[::-1] and second["next_cursor"] is None
    assert first["items"][0]["restaurant_name"] == "POI-5"
    assert first["items"][0]["interval"]["nominal_coverage"] == pytest.approx(0.8)


async def test_model_info(client: httpx.AsyncClient, h: dict) -> None:
    resp = await client.get("/pickup/model", headers=h)
    assert resp.status_code == 200
    body = resp.json()
    assert (body["name"], body["version"]) == (fake_artifact.NAME, fake_artifact.VERSION)
    assert body["task"] == "regression:order_to_pickup_min"
    assert body["test_metrics"] == {
        "model": "xgboost",
        "mae": 1.0,
        "rmse": 1.2,
        "r2": 0.5,
    }  # from metrics.json
    assert body["interval"]["test_coverage"] == 0.8 and body["interval"]["nominal_coverage"] == pytest.approx(
        0.8
    )
    assert body["acknowledgement"] == "This research was supported by data provided by Meituan."
    text = " ".join(body["limitations"])
    assert "Not food preparation time." in text and "20.0% better" in text and "60.0%" in text


@pytest.fixture
async def no_model_client(database_url: str) -> AsyncIterator[httpx.AsyncClient]:
    app: FastAPI = create_app(make_settings(database_url))  # no MODEL_DIR
    async with app.router.lifespan_context(app):
        transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
        async with httpx.AsyncClient(transport=transport, base_url="http://test/api/v1") as c:
            yield c


async def test_without_model_predictions_are_503_but_history_works(
    no_model_client: httpx.AsyncClient, dataset: dict
) -> None:
    h = await auth_headers(no_model_client, "nomodel@example.com")
    resp = await no_model_client.post("/pickup/predictions", json={"restaurant_id": dataset["0"]}, headers=h)
    assert resp.status_code == 503 and resp.json()["error"]["code"] == "model_unavailable"
    assert (await no_model_client.get("/pickup/model", headers=h)).status_code == 503
    assert (await no_model_client.get("/pickup/predictions", headers=h)).status_code == 200
    assert (await no_model_client.get("/ready")).status_code == 503


async def test_startup_fails_fast_on_a_bad_artifact(database_url: str, tmp_path: Path) -> None:
    root = tmp_path / "artifacts"
    folder = fake_artifact.build(root)
    with (folder / "pipeline.joblib").open("ab") as fh:
        fh.write(b"tampered")
    app = create_app(
        make_settings(
            database_url,
            model_dir=root,
            active_model_name=fake_artifact.NAME,
            active_model_version=fake_artifact.VERSION,
        )
    )
    with pytest.raises(Exception, match="SHA-256 mismatch"):
        async with app.router.lifespan_context(app):
            pass


# ---- pickup log + wait stats ----


def log_body(restaurant_id: str, start: str, minutes: float, **extra) -> dict:
    arrived = datetime.fromisoformat(start)
    return {
        "restaurant_id": restaurant_id,
        "arrived_at": arrived.isoformat(),
        "picked_up_at": (arrived + timedelta(minutes=minutes)).isoformat(),
        **extra,
    }


async def test_pickup_log_crud(client: httpx.AsyncClient, h: dict, dataset: dict) -> None:
    own = await own_restaurant(client, h)
    resp = await client.post(
        "/pickup/logs", json=log_body(own["id"], "2026-11-09T18:00:00+07:00", 7.5, notes=" queue "), headers=h
    )
    assert resp.status_code == 201
    body = resp.json()
    assert (
        body["wait_minutes"] == "7.50"
        and body["notes"] == "queue"
        and body["restaurant_name"] == "Som Tam Corner"
    )
    await client.post("/pickup/logs", json=log_body(dataset["0"], "2026-11-10T12:00:00+07:00", 3), headers=h)

    listed = (await client.get("/pickup/logs", headers=h)).json()["items"]
    assert [i["restaurant_name"] for i in listed] == ["POI-0", "Som Tam Corner"]  # newest first
    only_own = (await client.get(f"/pickup/logs?restaurant_id={own['id']}", headers=h)).json()["items"]
    assert [i["id"] for i in only_own] == [body["id"]]
    page = (await client.get("/pickup/logs?limit=1", headers=h)).json()
    page2 = (await client.get(f"/pickup/logs?limit=1&cursor={page['next_cursor']}", headers=h)).json()
    assert page2["items"][0]["id"] == body["id"] and page2["next_cursor"] is None

    assert (await client.delete(f"/pickup/logs/{body['id']}", headers=h)).status_code == 204
    resp = await client.delete(f"/pickup/logs/{body['id']}", headers=h)
    assert resp.status_code == 404 and resp.json()["error"]["code"] == "pickup_log_not_found"


@pytest.mark.parametrize(
    ("minutes", "status", "code"),
    [
        (-1, 400, "invalid_pickup_times"),
        (180.01, 400, "pickup_wait_too_long"),
        (0, 201, None),
        (180, 201, None),
    ],
)
async def test_pickup_log_times(
    client: httpx.AsyncClient, h: dict, dataset: dict, minutes: float, status: int, code
) -> None:
    resp = await client.post(
        "/pickup/logs", json=log_body(dataset["0"], "2026-11-09T18:00:00+07:00", minutes), headers=h
    )
    assert resp.status_code == status
    if code:
        assert resp.json()["error"]["code"] == code


async def test_pickup_log_validation(client: httpx.AsyncClient, h: dict, dataset: dict) -> None:
    bad = [
        log_body(dataset["0"], "2026-11-09T18:00:00+07:00", 5, notes="x" * 301),
        {
            "restaurant_id": dataset["0"],
            "arrived_at": "2026-11-09T18:00:00",
            "picked_up_at": "2026-11-09T18:05:00",
        },
    ]
    for body in bad:
        assert (await client.post("/pickup/logs", json=body, headers=h)).status_code == 422
    missing = log_body("6f1c0f0e-0000-4000-8000-000000000000", "2026-11-09T18:00:00+07:00", 5)
    assert (await client.post("/pickup/logs", json=missing, headers=h)).status_code == 404


async def test_wait_stats_thresholds(client: httpx.AsyncClient, h: dict, dataset: dict) -> None:
    rid = dataset["0"]
    url = f"/pickup/restaurants/{rid}/wait-stats"
    waits = [2, 4, 6, 8, 10]
    for i, minutes in enumerate(waits[:4]):
        await client.post(
            "/pickup/logs", json=log_body(rid, f"2026-11-0{i + 1}T12:00:00+07:00", minutes), headers=h
        )
    four = (await client.get(url, headers=h)).json()
    assert four == {
        "restaurant_id": rid,
        "n": 4,
        "median_minutes": None,
        "p80_minutes": None,
        "confidence": "insufficient",
    }

    await client.post("/pickup/logs", json=log_body(rid, "2026-11-05T12:00:00+07:00", 10), headers=h)
    five = (await client.get(url, headers=h)).json()
    assert five["confidence"] == "low" and five["median_minutes"] == "6.00" and five["p80_minutes"] == "8.40"

    for day in range(10, 25):
        await client.post("/pickup/logs", json=log_body(rid, f"2026-11-{day}T12:00:00+07:00", 5), headers=h)
    assert (await client.get(url, headers=h)).json()["confidence"] == "ok"
