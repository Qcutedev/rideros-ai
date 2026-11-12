"""Photo classification of new reports through cv_service (Architecture §2.5 / §3.3).

The report is written first with `ai_status = "pending"`; after the response is sent a background
task posts the stored (re-encoded, EXIF-free) JPEG to `POST /classify` and writes the suggestion.
The suggestion never changes the report's category or the incident's status. Any failure (service
down, timeout, odd answer) ends in `ai_status = "failed"`; the report itself is never affected.
"""

import asyncio
import uuid
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any

import httpx
import structlog
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.modules.pickup import repository as model_repo
from app.modules.pickup.models import ModelVersion
from app.modules.road.images import ImageStore
from app.modules.road.models import IncidentReport

log = structlog.get_logger(__name__)

# Labels the classifier may answer with (cv_service training/build.py CLASSES).
CV_LABELS = frozenset({"flooding", "road_damage", "other"})
CV_DATASET = (
    "RDD2022 (CC BY 4.0; China_MotorBike, Czech, India, United_States) + AlleyFloodNet (CC BY 4.0) "
    "+ Flood10k flooded images (CC BY-NC 4.0); no photos from Thailand"
)


class CvAnswerError(ValueError):
    """cv_service answered, but not with something we can store."""


def create_client(settings: Settings) -> httpx.AsyncClient | None:
    if not settings.cv_service_url:
        return None
    return httpx.AsyncClient(base_url=settings.cv_service_url, timeout=settings.cv_timeout_seconds)


def _parse(body: Any) -> tuple[str, Decimal, str, str]:
    try:
        label, confidence = body["label"], float(body["confidence"])
        name, version = str(body["model"]["name"]), str(body["model"]["version"])
    except (KeyError, TypeError, ValueError) as exc:
        raise CvAnswerError("malformed /classify answer") from exc
    if label not in CV_LABELS or not 0.0 <= confidence <= 1.0:
        raise CvAnswerError(f"unexpected label/confidence: {label!r} {confidence!r}")
    return label, Decimal(f"{confidence:.3f}"), name, version


async def _model_version_id(
    session: AsyncSession, client: httpx.AsyncClient, name: str, version: str
) -> uuid.UUID:
    """The model_versions row of the classifier, registered from GET /model the first time it is seen."""
    existing = await session.scalar(
        select(ModelVersion.id).where(ModelVersion.name == name, ModelVersion.version == version)
    )
    if existing is not None:
        return existing
    resp = await client.get("/model")
    resp.raise_for_status()
    info = resp.json()
    if info.get("name") != name or info.get("version") != version:
        raise CvAnswerError("GET /model describes another model than /classify used")
    if not isinstance(info.get("metrics"), dict):
        raise CvAnswerError("the classifier has no test metrics (run `python -m training evaluate`)")
    trained = info.get("trained_at")
    return await model_repo.activate_model_version(
        session,
        {
            "name": name,
            "version": version,
            "task": "image_classification:road_photo",
            "dataset": CV_DATASET,
            "metrics": info["metrics"],
            "feature_schema": {
                "arch": info.get("arch"),
                "classes": info.get("classes"),
                "input": info.get("input"),
                "pretrained_weights": info.get("pretrained_weights"),
            },
            "artifact_uri": f"cv_service:{name}/{version}",
            "trained_at": datetime.fromisoformat(trained) if trained else None,
        },
    )


async def _finish(session: AsyncSession, report_id: uuid.UUID, **values: Any) -> None:
    # Only a still-pending row is written: a deleted report (account deletion) is simply skipped.
    await session.execute(
        update(IncidentReport)
        .where(IncidentReport.id == report_id, IncidentReport.ai_status == "pending")
        .values(**values)
    )
    await session.commit()


async def classify_report(
    session_factory: async_sessionmaker[AsyncSession],
    client: httpx.AsyncClient,
    store: ImageStore,
    report_id: uuid.UUID,
) -> None:
    async with session_factory() as session:
        key = await session.scalar(
            select(IncidentReport.image_key).where(
                IncidentReport.id == report_id, IncidentReport.ai_status == "pending"
            )
        )
        if key is None:
            return
        started = datetime.now(UTC)
        try:
            data = await asyncio.to_thread(store.path(key).read_bytes)
            resp = await client.post("/classify", files={"image": ("photo.jpg", data, "image/jpeg")})
            resp.raise_for_status()
            label, confidence, name, version = _parse(resp.json())
            model_version_id = await _model_version_id(session, client, name, version)
            await _finish(
                session,
                report_id,
                ai_status="done",
                ai_label=label,
                ai_confidence=confidence,
                ai_model_version_id=model_version_id,
            )
            log.info(
                "road_photo_classified",
                report_id=str(report_id),
                label=label,
                confidence=str(confidence),
                model=f"{name}/{version}",
                ms=round((datetime.now(UTC) - started).total_seconds() * 1000),
            )
        except Exception as exc:  # noqa: BLE001 - every failure becomes ai_status="failed"
            await session.rollback()
            log.warning("road_photo_classify_failed", report_id=str(report_id), error=type(exc).__name__)
            await _finish(session, report_id, ai_status="failed")
