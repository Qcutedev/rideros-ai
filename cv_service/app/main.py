"""POST /classify: one photo in, a suggested category + confidence out (Architecture §2.5).

The service is internal: only the backend calls it, over the compose network (no published port).
It answers with a suggestion only; the backend never changes a report's category or status from it.
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel

from app.classifier import Classifier, InvalidImageError, ModelLoadError
from app.config import Settings, get_settings

log = logging.getLogger("rideros.cv")


class ModelInfo(BaseModel):
    name: str
    version: str


class ClassifyResponse(BaseModel):
    label: str
    confidence: float
    probabilities: dict[str, float]
    model: ModelInfo


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        app.state.classifier = None
        if settings.cv_model_dir is not None:
            try:
                app.state.classifier = Classifier(settings.cv_model_dir, threads=settings.cv_threads)
                log.info("model loaded: %s", settings.cv_model_dir)
            except ModelLoadError:
                log.exception("model not loaded; /classify will answer 503")
        yield

    app = FastAPI(title="RiderOS CV", version="1.0.0", lifespan=lifespan, docs_url=None, redoc_url=None)

    def classifier(request: Request) -> Classifier:
        clf = request.app.state.classifier
        if clf is None:
            raise HTTPException(503, "model_unavailable")
        return clf

    @app.get("/health")
    async def health(request: Request) -> dict:
        clf = request.app.state.classifier
        return {
            "status": "ok" if clf else "no_model",
            "model": {"name": clf.name, "version": clf.version} if clf else None,
        }

    @app.get("/model")
    async def model(request: Request) -> dict:
        """What the backend records in model_versions: identity, inputs and the test metrics verbatim."""
        clf = classifier(request)
        meta = clf.metadata
        return {
            "name": clf.name,
            "version": clf.version,
            "arch": meta.get("arch"),
            "classes": clf.classes,
            "input": meta.get("input"),
            "pretrained_weights": meta.get("pretrained_weights"),
            "trained_at": meta.get("trained_at"),
            "data": meta.get("data"),
            "metrics": clf.metrics,
        }

    @app.post("/classify", response_model=ClassifyResponse)
    async def classify(request: Request, image: UploadFile = File(...)) -> ClassifyResponse:
        clf = classifier(request)
        data = await image.read(settings.cv_max_bytes + 1)
        if len(data) > settings.cv_max_bytes:
            raise HTTPException(413, "image_too_large")
        try:
            pred = await run_in_threadpool(clf.classify, data)
        except InvalidImageError as exc:
            raise HTTPException(415, "unsupported_image") from exc
        return ClassifyResponse(
            label=pred.label,
            confidence=pred.confidence,
            probabilities=pred.probabilities,
            model=ModelInfo(name=clf.name, version=clf.version),
        )

    return app


app = create_app()
