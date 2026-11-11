"""RoadContext (/road): duplicate grouping per category, status machine, map queries, privacy, photos."""

import io
import uuid
from datetime import UTC, datetime, timedelta
from pathlib import Path

import httpx
import pytest
from PIL import ExifTags, Image
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.db.models import IncidentReport, RoadIncident, User
from app.modules.road import service
from app.modules.road.images import ImageStorageUnavailableError
from app.modules.road.rules import CATEGORIES, default_road_rules
from tests.helpers import PASSWORD, auth_headers

LAT, LNG = 13.7563, 100.5018  # Bangkok
M_PER_DEG_LAT = 110_600  # close enough at this latitude; tests stay ≥10% away from every edge
RULES = default_road_rules()


def north(meters: float) -> float:
    return LAT + meters / M_PER_DEG_LAT


class Clock:
    def __init__(self) -> None:
        self.now = datetime(2026, 11, 12, 3, 0, tzinfo=UTC)

    def advance(self, delta: timedelta) -> None:
        self.now += delta


@pytest.fixture
def clock(monkeypatch: pytest.MonkeyPatch) -> Clock:
    c = Clock()
    monkeypatch.setattr(service, "utcnow", lambda: c.now)
    return c


@pytest.fixture
async def riders(client: httpx.AsyncClient) -> list[dict[str, str]]:
    return [await auth_headers(client, f"rider{i}@example.com") for i in range(3)]


async def report(
    client: httpx.AsyncClient,
    headers: dict[str, str],
    category: str = "flooding",
    lat: float = LAT,
    lng: float = LNG,
    *,
    image: bytes | None = None,
    description: str | None = None,
) -> httpx.Response:
    data = {"category": category, "lat": repr(lat), "lng": repr(lng)}
    if description is not None:
        data["description"] = description
    files = {"image": ("photo.jpg", image, "image/jpeg")} if image is not None else None
    return await client.post("/road/reports", data=data, files=files, headers=headers)


async def confirm(client: httpx.AsyncClient, headers: dict, incident_id: str, still: bool) -> httpx.Response:
    return await client.post(
        f"/road/incidents/{incident_id}/confirmations", json={"still_present": still}, headers=headers
    )


def jpeg(size: tuple[int, int] = (40, 20), exif: Image.Exif | None = None) -> bytes:
    out = io.BytesIO()
    Image.new("RGB", size, (200, 30, 30)).save(out, "JPEG", exif=exif or Image.Exif())
    return out.getvalue()


# ---- duplicate grouping: every category ----


@pytest.mark.parametrize("category", CATEGORIES)
async def test_report_inside_radius_and_window_joins_the_incident(
    client: httpx.AsyncClient, riders: list, clock: Clock, category: str
) -> None:
    rule = RULES[category]
    first = await report(client, riders[0], category)
    assert first.status_code == 201, first.text
    assert first.json()["merged"] is False and first.json()["status"] == "unverified"

    clock.advance(rule.window)  # exactly at the end of the window still counts
    second = await report(client, riders[1], category, north(rule.radius_m * 0.9))
    assert second.status_code == 201, second.text
    body = second.json()
    assert body["merged"] is True and body["incident_id"] == first.json()["incident_id"]
    assert body["incident"]["report_count"] == 2 and body["incident"]["distinct_reporters"] == 2
    # The location stays the first report's; expiry moves to the latest report + TTL.
    assert body["incident"]["location"] == {"lat": LAT, "lng": LNG}
    assert datetime.fromisoformat(body["incident"]["expires_at"]) == clock.now + rule.ttl


@pytest.mark.parametrize("category", CATEGORIES)
async def test_report_outside_radius_opens_a_new_incident(
    client: httpx.AsyncClient, riders: list, clock: Clock, category: str
) -> None:
    first = (await report(client, riders[0], category)).json()
    second = (await report(client, riders[1], category, north(RULES[category].radius_m * 1.1))).json()
    assert second["merged"] is False and second["incident_id"] != first["incident_id"]


@pytest.mark.parametrize("category", CATEGORIES)
async def test_report_after_the_window_opens_a_new_incident(
    client: httpx.AsyncClient, riders: list, clock: Clock, category: str
) -> None:
    rule = RULES[category]
    assert rule.ttl > rule.window  # so the first incident is still open, only out of the window
    first = (await report(client, riders[0], category)).json()
    clock.advance(rule.window + timedelta(minutes=1))
    second = (await report(client, riders[1], category)).json()
    assert second["merged"] is False and second["incident_id"] != first["incident_id"]
    old = (await client.get(f"/road/incidents/{first['incident_id']}", headers=riders[0])).json()
    assert old["status"] == "unverified"


@pytest.mark.parametrize("category", CATEGORIES)
async def test_other_category_at_the_same_spot_is_a_separate_incident(
    client: httpx.AsyncClient, riders: list, clock: Clock, category: str
) -> None:
    other = next(c for c in CATEGORIES if c != category)
    first = (await report(client, riders[0], category)).json()
    second = (await report(client, riders[1], other)).json()
    assert second["merged"] is False and second["incident_id"] != first["incident_id"]


@pytest.mark.parametrize("category", CATEGORIES)
async def test_expired_incident_is_not_joined(
    client: httpx.AsyncClient, riders: list, clock: Clock, category: str, db: AsyncSession
) -> None:
    first = (await report(client, riders[0], category)).json()
    clock.advance(RULES[category].ttl)
    second = (await report(client, riders[1], category)).json()
    assert second["merged"] is False
    row = await db.get(RoadIncident, uuid.UUID(first["incident_id"]))
    assert row is not None and row.status == "expired"  # written by the next RoadContext write


async def test_report_joins_the_closest_open_incident(
    client: httpx.AsyncClient, riders: list, clock: Clock
) -> None:
    await report(client, riders[0], "flooding")
    far = (await report(client, riders[1], "flooding", north(400))).json()  # > 300 m: its own incident
    assert far["merged"] is False
    joined = (await report(client, riders[2], "flooding", north(250))).json()  # 250 m vs 150 m away
    assert joined["merged"] is True and joined["incident_id"] == far["incident_id"]


async def test_same_rider_cannot_report_the_same_incident_twice(
    client: httpx.AsyncClient, riders: list, clock: Clock
) -> None:
    first = (await report(client, riders[0])).json()
    again = await report(client, riders[0], lat=north(100))
    assert again.status_code == 409
    error = again.json()["error"]
    assert error["code"] == "already_reported" and error["details"] == [{"incident_id": first["incident_id"]}]


# ---- status machine ----


async def test_still_present_from_another_rider_corroborates(
    client: httpx.AsyncClient, riders: list, clock: Clock
) -> None:
    incident = (await report(client, riders[0], "road_obstacle")).json()["incident_id"]
    own = (await confirm(client, riders[0], incident, True)).json()
    assert (
        own["status"] == "unverified" and own["distinct_reporters"] == 1
    )  # the reporter alone is not enough

    clock.advance(timedelta(hours=1))
    body = (await confirm(client, riders[1], incident, True)).json()
    assert body["status"] == "corroborated" and body["distinct_reporters"] == 2 and body["report_count"] == 1
    assert body["my_confirmation"]["still_present"] is True
    assert datetime.fromisoformat(body["expires_at"]) == clock.now + RULES["road_obstacle"].ttl


async def test_corroboration_needs_both_riders_inside_the_window(
    client: httpx.AsyncClient, riders: list, clock: Clock
) -> None:
    rule = RULES["traffic_incident"]
    incident = (await report(client, riders[0], "traffic_incident")).json()["incident_id"]
    clock.advance(rule.window + timedelta(minutes=1))  # still open: TTL 3 h > window 2 h
    body = (await confirm(client, riders[1], incident, True)).json()
    assert body["status"] == "unverified" and body["distinct_reporters"] == 2


async def test_two_cleared_after_the_last_report_resolve(
    client: httpx.AsyncClient, riders: list, clock: Clock
) -> None:
    incident = (await report(client, riders[0], "road_closure")).json()["incident_id"]
    clock.advance(timedelta(minutes=5))
    one = (await confirm(client, riders[1], incident, False)).json()
    assert one["status"] == "unverified" and one["cleared_count"] == 1

    # A newer "still there" outweighs the earlier "cleared".
    clock.advance(timedelta(minutes=5))
    (await confirm(client, riders[2], incident, True)).json()
    clock.advance(timedelta(minutes=5))
    two = (await confirm(client, riders[0], incident, False)).json()
    assert two["status"] == "corroborated" and two["cleared_count"] == 1

    clock.advance(timedelta(minutes=5))
    done = (await confirm(client, riders[1], incident, False)).json()
    assert done["status"] == "resolved" and done["cleared_count"] == 2
    closed = await confirm(client, riders[2], incident, True)
    assert closed.status_code == 409 and closed.json()["error"]["code"] == "incident_closed"


async def test_new_confirmation_replaces_the_old_one(
    client: httpx.AsyncClient, riders: list, clock: Clock, db: AsyncSession
) -> None:
    incident = (await report(client, riders[0])).json()["incident_id"]
    await confirm(client, riders[1], incident, False)
    clock.advance(timedelta(minutes=1))
    body = (await confirm(client, riders[1], incident, True)).json()
    assert body["my_confirmation"]["still_present"] is True and body["cleared_count"] == 0
    rows = (
        await db.execute(select(IncidentReport.report_type).where(IncidentReport.incident_id == incident))
    ).scalars()
    assert sorted(rows) == ["report", "still_present"]


async def test_expired_incident_reads_as_expired_and_leaves_the_map(
    client: httpx.AsyncClient, riders: list, clock: Clock
) -> None:
    incident = (await report(client, riders[0], "traffic_incident")).json()["incident_id"]
    clock.advance(RULES["traffic_incident"].ttl)
    detail = (await client.get(f"/road/incidents/{incident}", headers=riders[0])).json()
    assert detail["status"] == "expired"
    nearby = (
        await client.get("/road/incidents/nearby", params={"lat": LAT, "lng": LNG}, headers=riders[0])
    ).json()
    assert nearby["items"] == []
    late = await confirm(client, riders[1], incident, True)
    assert late.status_code == 409 and late.json()["error"]["code"] == "incident_closed"


async def test_admin_can_reject_and_riders_cannot(
    client: httpx.AsyncClient, riders: list, clock: Clock, db: AsyncSession
) -> None:
    incident = (await report(client, riders[0])).json()["incident_id"]
    url = f"/road/incidents/{incident}/status"
    denied = await client.patch(url, json={"status": "rejected"}, headers=riders[1])
    assert denied.status_code == 403 and denied.json()["error"]["code"] == "admin_only"

    await db.execute(update(User).where(User.email == "rider2@example.com").values(role="admin"))
    await db.commit()
    bad = await client.patch(url, json={"status": "corroborated"}, headers=riders[2])
    assert bad.status_code == 422
    done = await client.patch(url, json={"status": "rejected"}, headers=riders[2])
    assert done.status_code == 200 and done.json()["status"] == "rejected"
    again = await client.patch(url, json={"status": "resolved"}, headers=riders[2])
    assert again.status_code == 409
    missing = await client.patch(
        "/road/incidents/6f1c0f0e-0000-4000-8000-000000000000/status",
        json={"status": "rejected"},
        headers=riders[2],
    )
    assert missing.status_code == 404
    # A rejected incident no longer takes reports: a new one opens instead.
    assert (await report(client, riders[1])).json()["merged"] is False


# ---- map queries ----


async def test_bbox_returns_open_incidents_inside_the_box(
    client: httpx.AsyncClient, riders: list, clock: Clock
) -> None:
    inside = (await report(client, riders[0], "flooding")).json()["incident_id"]
    await report(client, riders[0], "flooding", LAT + 0.5)  # outside the box
    box = f"{LNG - 0.01},{LAT - 0.01},{LNG + 0.01},{LAT + 0.01}"
    body = (await client.get("/road/incidents", params={"bbox": box}, headers=riders[1])).json()
    assert [i["id"] for i in body["items"]] == [inside]
    assert body["truncated"] is False and "not verified" in body["notice"]
    assert body["items"][0]["distance_m"] is None


@pytest.mark.parametrize(
    "bbox",
    ["1,2,3", "a,b,c,d", "100.6,13.7,100.5,13.8", "100,13,103,14", "-181,0,-179,1", "100,13,101,13"],
)
async def test_bad_bbox_is_400(client: httpx.AsyncClient, riders: list, bbox: str) -> None:
    resp = await client.get("/road/incidents", params={"bbox": bbox}, headers=riders[0])
    assert resp.status_code == 400 and resp.json()["error"]["code"] == "invalid_bbox"


async def test_nearby_is_sorted_by_distance_and_limited_by_radius(
    client: httpx.AsyncClient, riders: list, clock: Clock
) -> None:
    far = (await report(client, riders[0], "road_damage", north(900))).json()["incident_id"]
    near = (await report(client, riders[0], "road_closure", north(300))).json()["incident_id"]
    await report(client, riders[0], "road_obstacle", north(3000))
    body = (
        await client.get(
            "/road/incidents/nearby", params={"lat": LAT, "lng": LNG, "radius_m": 1000}, headers=riders[1]
        )
    ).json()
    assert [i["id"] for i in body["items"]] == [near, far]
    assert 270 < body["items"][0]["distance_m"] < 330

    too_far = await client.get(
        "/road/incidents/nearby", params={"lat": LAT, "lng": LNG, "radius_m": 5001}, headers=riders[1]
    )
    assert too_far.status_code == 422


# ---- privacy ----


async def test_incidents_never_expose_reporters_and_reports_stay_private(
    client: httpx.AsyncClient, riders: list, clock: Clock
) -> None:
    created = (await report(client, riders[0], image=jpeg(), description="น้ำท่วมถึงเข่า")).json()
    incident, report_id = created["incident_id"], created["report_id"]

    other = (await client.get(f"/road/incidents/{incident}", headers=riders[1])).json()
    assert other["my_report"] is None and other["my_confirmation"] is None
    text = str(other)
    assert "user" not in text and "rider0" not in text and "น้ำท่วม" not in text

    mine = (await client.get(f"/road/incidents/{incident}", headers=riders[0])).json()["my_report"]
    assert mine["id"] == report_id and mine["has_image"] is True and mine["ai_status"] == "none"
    assert mine["description"] == "น้ำท่วมถึงเข่า"

    assert (await client.get(f"/road/reports/{report_id}/image", headers=riders[1])).status_code == 404
    assert (await client.get("/road/reports", headers=riders[1])).json()["items"] == []
    own = (await client.get("/road/reports", headers=riders[0])).json()["items"]
    assert [r["id"] for r in own] == [report_id]


async def test_own_reports_are_paged_newest_first(
    client: httpx.AsyncClient, riders: list, clock: Clock
) -> None:
    ids = []
    for category in CATEGORIES[:3]:
        clock.advance(timedelta(minutes=1))
        ids.append((await report(client, riders[0], category)).json()["report_id"])
    page1 = (await client.get("/road/reports", params={"limit": 2}, headers=riders[0])).json()
    page2 = (
        await client.get(
            "/road/reports", params={"limit": 2, "cursor": page1["next_cursor"]}, headers=riders[0]
        )
    ).json()
    assert [r["id"] for r in page1["items"] + page2["items"]] == ids[::-1]
    assert page2["next_cursor"] is None


async def test_account_deletion_removes_reports_photos_and_fixes_counters(
    client: httpx.AsyncClient, riders: list, clock: Clock, db: AsyncSession, road_image_dir: Path
) -> None:
    shared = (await report(client, riders[0], image=jpeg())).json()
    await report(client, riders[1], lat=north(50))
    alone = (await report(client, riders[0], "road_damage")).json()
    key = (
        await db.execute(select(IncidentReport.image_key).where(IncidentReport.id == shared["report_id"]))
    ).scalar()
    assert (road_image_dir / key).is_file()

    resp = await client.request("DELETE", "/me", json={"password": PASSWORD}, headers=riders[0])
    assert resp.status_code == 204
    assert not (road_image_dir / key).exists()
    after = (await client.get(f"/road/incidents/{shared['incident_id']}", headers=riders[1])).json()
    assert after["report_count"] == 1 and after["distinct_reporters"] == 1
    gone = await client.get(f"/road/incidents/{alone['incident_id']}", headers=riders[1])
    assert gone.status_code == 404


# ---- photos ----


async def test_photo_is_reencoded_without_exif_and_kept_upright(
    client: httpx.AsyncClient, riders: list, clock: Clock
) -> None:
    exif = Image.Exif()
    exif[ExifTags.Base.Make] = "TestCam"
    exif[ExifTags.Base.Orientation] = 6  # rotate 90° when shown
    exif[ExifTags.Base.GPSInfo] = {
        ExifTags.GPS.GPSLatitudeRef: "N",
        ExifTags.GPS.GPSLatitude: (13.0, 45.0, 0.0),
    }
    created = (await report(client, riders[0], image=jpeg((40, 20), exif))).json()

    resp = await client.get(f"/road/reports/{created['report_id']}/image", headers=riders[0])
    assert resp.status_code == 200 and resp.headers["content-type"] == "image/jpeg"
    assert b"TestCam" not in resp.content and b"Exif" not in resp.content
    with Image.open(io.BytesIO(resp.content)) as img:
        assert img.size == (20, 40) and len(img.getexif()) == 0


async def test_large_png_with_alpha_is_downscaled(
    client: httpx.AsyncClient, riders: list, clock: Clock
) -> None:
    out = io.BytesIO()
    Image.new("RGBA", (3200, 1600), (0, 0, 0, 0)).save(out, "PNG")
    created = (await report(client, riders[0], image=out.getvalue())).json()
    resp = await client.get(f"/road/reports/{created['report_id']}/image", headers=riders[0])
    with Image.open(io.BytesIO(resp.content)) as img:
        assert img.size == (1600, 800) and img.format == "JPEG"
        assert img.getpixel((0, 0)) == (255, 255, 255)  # transparency flattened onto white


@pytest.mark.parametrize(
    "data",
    [
        b"<?php echo 'hi'; ?>",  # wrong magic bytes, whatever the client says the type is
        b"\xff\xd8\xff\xe0" + b"\x00" * 100,  # JPEG magic, not a JPEG
        b"GIF89a" + b"\x00" * 100,
    ],
)
async def test_non_images_are_415(
    client: httpx.AsyncClient, riders: list, clock: Clock, data: bytes, db: AsyncSession
) -> None:
    resp = await report(client, riders[0], image=data)
    assert resp.status_code == 415 and resp.json()["error"]["code"] == "unsupported_image"
    assert (await db.execute(select(RoadIncident))).first() is None  # nothing saved


async def test_photo_over_5_mb_is_413(client: httpx.AsyncClient, riders: list, clock: Clock) -> None:
    data = jpeg() + b"\x00" * (5 * 1024 * 1024)
    resp = await report(client, riders[0], image=data)
    assert resp.status_code == 413 and resp.json()["error"]["code"] == "image_too_large"


async def test_photo_without_storage_is_503(
    settings: Settings, db: AsyncSession, client: httpx.AsyncClient
) -> None:
    await auth_headers(client, "nostore@example.com")
    user_id = (await db.execute(select(User.id).where(User.email == "nostore@example.com"))).scalar_one()
    no_store = settings.model_copy(update={"road_image_dir": None})
    body = service.NewReport(category="flooding", lat=LAT, lng=LNG, description=None, image=jpeg())
    with pytest.raises(ImageStorageUnavailableError):
        await service.create_report(db, no_store, user_id, body)


@pytest.mark.parametrize(
    "data",
    [
        {"category": "earthquake", "lat": "13.7", "lng": "100.5"},
        {"category": "flooding", "lat": "91", "lng": "100.5"},
        {"category": "flooding", "lat": "13.7"},
        {"category": "flooding", "lat": "13.7", "lng": "100.5", "description": "x" * 501},
    ],
)
async def test_report_validation(client: httpx.AsyncClient, riders: list, data: dict) -> None:
    resp = await client.post("/road/reports", data=data, headers=riders[0])
    assert resp.status_code == 422


async def test_road_endpoints_require_login(client: httpx.AsyncClient) -> None:
    for method, url in (
        ("POST", "/road/reports"),
        ("GET", "/road/reports"),
        ("GET", "/road/incidents?bbox=100,13,100.1,13.1"),
        ("GET", "/road/incidents/nearby?lat=13&lng=100"),
    ):
        assert (await client.request(method, url)).status_code == 401


async def test_failed_write_leaves_no_photo_behind(
    client: httpx.AsyncClient,
    riders: list,
    clock: Clock,
    road_image_dir: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    before = set(road_image_dir.iterdir())

    async def boom(*args: object, **kwargs: object) -> None:
        raise RuntimeError("db down")

    monkeypatch.setattr(service, "_refresh", boom)
    resp = await report(client, riders[0], image=jpeg())
    assert resp.status_code == 500
    assert set(road_image_dir.iterdir()) == before


async def test_unknown_ids_and_bad_cursor(client: httpx.AsyncClient, riders: list) -> None:
    missing = "6f1c0f0e-0000-4000-8000-000000000000"
    assert (await client.get(f"/road/incidents/{missing}", headers=riders[0])).status_code == 404
    assert (await confirm(client, riders[0], missing, True)).status_code == 404
    assert (await client.get(f"/road/reports/{missing}/image", headers=riders[0])).status_code == 404
    bad = await client.get("/road/reports", params={"cursor": "WyJ4IiwieSJd"}, headers=riders[0])  # ["x","y"]
    assert bad.status_code == 400 and bad.json()["error"]["code"] == "invalid_cursor"
