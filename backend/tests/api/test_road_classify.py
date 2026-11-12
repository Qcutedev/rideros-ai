"""Background photo classification through cv_service (P5c). cv_service is replaced by httpx.MockTransport."""

import uuid
from collections.abc import AsyncIterator, Callable
from datetime import timedelta
from pathlib import Path

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.db.models import IncidentReport, ModelVersion
from app.main import create_app
from app.modules.road.rules import AI_PENDING_TIMEOUT
from tests.api.test_road import jpeg, report
from tests.conftest import make_settings
from tests.helpers import auth_headers

Handler = Callable[[httpx.Request], httpx.Response]
METRICS = {"accuracy": 0.9, "macro_f1": 0.88, "per_class": {}}


class FakeCv:
    """Answers /classify and /model like cv_service; records the calls."""

    def __init__(self, version: str) -> None:
        self.version = version
        self.label, self.confidence = "flooding", 0.8731
        self.classify_status = 200
        self.metrics: dict | None = METRICS
        self.calls: list[str] = []
        self.images: list[bytes] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        self.calls.append(request.url.path)
        model = {"name": "road_cv", "version": self.version}
        if request.url.path == "/classify":
            self.images.append(request.content)
            if self.classify_status != 200:
                return httpx.Response(self.classify_status, json={"detail": "boom"})
            return httpx.Response(
                200,
                json={
                    "label": self.label,
                    "confidence": self.confidence,
                    "probabilities": {},
                    "model": model,
                },
            )
        if request.url.path == "/model":
            return httpx.Response(
                200,
                json={
                    **model,
                    "arch": "mobilenet_v3_large",
                    "classes": ["flooding", "road_damage", "other"],
                    "input": {"crop": 224},
                    "trained_at": "2026-11-12T13:00:00+00:00",
                    "metrics": self.metrics,
                },
            )
        return httpx.Response(404)


@pytest.fixture
def cv() -> FakeCv:
    return FakeCv(version=f"test-{uuid.uuid4().hex[:8]}")  # model_versions is not truncated between tests


@pytest.fixture
async def cv_client(database_url: str, road_image_dir: Path, cv: FakeCv) -> AsyncIterator[httpx.AsyncClient]:
    app: FastAPI = create_app(
        make_settings(database_url, road_image_dir=road_image_dir, cv_service_url="http://cv.test")
    )
    async with app.router.lifespan_context(app):
        await app.state.cv_client.aclose()
        app.state.cv_client = httpx.AsyncClient(transport=httpx.MockTransport(cv), base_url="http://cv.test")
        transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
        async with httpx.AsyncClient(transport=transport, base_url="http://test/api/v1") as c:
            c.app = app  # type: ignore[attr-defined]
            yield c


def _factory(client: httpx.AsyncClient) -> async_sessionmaker[AsyncSession]:
    return client.app.state.session_factory  # type: ignore[attr-defined]


async def _row(client: httpx.AsyncClient, report_id: str) -> IncidentReport:
    async with _factory(client)() as s:
        row = await s.get(IncidentReport, uuid.UUID(report_id))
        assert row is not None
        return row


async def test_photo_report_gets_a_suggestion_and_keeps_its_category(cv_client, cv):
    headers = await auth_headers(cv_client, "cv1@example.com")
    cv.label = "road_damage"
    created = (await report(cv_client, headers, "flooding", image=jpeg())).json()
    # The background task ran before the ASGI call returned.
    assert cv.calls == ["/classify", "/model"]
    assert cv.images and b"\xff\xd8" in cv.images[0]  # the stored JPEG was sent
    row = await _row(cv_client, created["report_id"])
    assert (row.ai_status, row.ai_label, str(row.ai_confidence)) == ("done", "road_damage", "0.873")
    assert row.category == "flooding"  # a suggestion never changes the category
    assert created["status"] == "unverified"

    mine = (await cv_client.get("/road/reports", headers=headers)).json()["items"][0]
    assert mine["ai_status"] == "done" and mine["ai_label"] == "road_damage"
    detail = (await cv_client.get(f"/road/incidents/{created['incident_id']}", headers=headers)).json()
    assert detail["status"] == "unverified" and detail["category"] == "flooding"

    async with _factory(cv_client)() as s:
        mv = await s.scalar(select(ModelVersion).where(ModelVersion.id == row.ai_model_version_id))
    assert mv is not None and (mv.name, mv.version) == ("road_cv", cv.version)
    assert mv.metrics == METRICS and mv.task == "image_classification:road_photo"
    assert mv.is_active and "Thailand" in mv.dataset


async def test_known_model_is_not_registered_again(cv_client, cv):
    headers = await auth_headers(cv_client, "cv2@example.com")
    await report(cv_client, headers, "flooding", image=jpeg())
    await report(cv_client, headers, "road_damage", image=jpeg())
    assert cv.calls == ["/classify", "/model", "/classify"]


async def test_report_without_photo_is_not_classified(cv_client, cv):
    headers = await auth_headers(cv_client, "cv3@example.com")
    created = (await report(cv_client, headers)).json()
    assert cv.calls == []
    assert (await _row(cv_client, created["report_id"])).ai_status == "none"


@pytest.mark.parametrize(
    "breakage",
    [
        lambda cv: setattr(cv, "classify_status", 503),
        lambda cv: setattr(cv, "label", "pothole"),  # not a class the backend knows
        lambda cv: setattr(cv, "confidence", 1.7),
        lambda cv: setattr(cv, "metrics", None),  # model without test metrics is not recorded
    ],
)
async def test_any_classifier_problem_ends_as_failed(cv_client, cv, breakage):
    headers = await auth_headers(cv_client, "cv4@example.com")
    breakage(cv)
    resp = await report(cv_client, headers, image=jpeg())
    assert resp.status_code == 201  # the report itself is never affected
    row = await _row(cv_client, resp.json()["report_id"])
    assert (row.ai_status, row.ai_label, row.ai_confidence) == ("failed", None, None)


async def test_unreachable_classifier_ends_as_failed(cv_client, cv):
    def down(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("refused", request=request)

    app = cv_client.app  # type: ignore[attr-defined]
    await app.state.cv_client.aclose()
    app.state.cv_client = httpx.AsyncClient(transport=httpx.MockTransport(down), base_url="http://cv.test")
    headers = await auth_headers(cv_client, "cv5@example.com")
    resp = await report(cv_client, headers, image=jpeg())
    assert resp.status_code == 201
    assert (await _row(cv_client, resp.json()["report_id"])).ai_status == "failed"


async def test_a_lost_pending_task_reads_as_failed(cv_client, cv):
    headers = await auth_headers(cv_client, "cv6@example.com")
    cv.classify_status = 503
    created = (await report(cv_client, headers, image=jpeg())).json()
    rid = uuid.UUID(created["report_id"])
    async with _factory(cv_client)() as s:
        row = await s.get(IncidentReport, rid)
        assert row is not None
        await s.execute(update(IncidentReport).where(IncidentReport.id == rid).values(ai_status="pending"))
        await s.commit()
    mine = (await cv_client.get("/road/reports", headers=headers)).json()["items"][0]
    assert mine["ai_status"] == "pending"  # fresh: still waiting
    async with _factory(cv_client)() as s:
        await s.execute(
            update(IncidentReport)
            .where(IncidentReport.id == rid)
            .values(created_at=row.created_at - AI_PENDING_TIMEOUT - timedelta(seconds=1))
        )
        await s.commit()
    mine = (await cv_client.get("/road/reports", headers=headers)).json()["items"][0]
    assert mine["ai_status"] == "failed"


async def test_deleted_report_is_skipped(cv_client, cv):
    """The task finds nothing to do when the report vanished (account deleted) before it ran."""
    from app.modules.road import service
    from app.modules.road.classify import classify_report

    app = cv_client.app  # type: ignore[attr-defined]
    store = service.image_store(app.state.settings)
    await classify_report(_factory(cv_client), app.state.cv_client, store, uuid.uuid4())
    assert cv.calls == []
