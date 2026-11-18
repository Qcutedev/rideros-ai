"""App factory. Serve with `uvicorn --factory app.main:create_app`; tests call `create_app(settings)`."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import structlog
from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.body_limit import BodySizeLimitMiddleware
from app.core.config import MULTIPART_OVERHEAD_BYTES, Settings, get_settings
from app.core.errors import register_error_handlers
from app.core.logging import RequestContextMiddleware, configure_logging
from app.core.rate_limit import RateLimiter, default_limit
from app.db.session import create_engine, create_session_factory
from app.modules.auth.router import router as auth_router
from app.modules.health.router import router as health_router
from app.modules.profit.router import router as profit_router
from app.modules.road.classify import create_client as create_cv_client
from app.modules.road.router import router as road_router
from app.modules.shifts.router import router as shifts_router
from app.modules.users.router import router as users_router

API_PREFIX = "/api/v1"


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()
    configure_logging(settings.log_level, settings.log_json)
    log = structlog.get_logger("app")

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        engine = create_engine(settings)
        app.state.engine = engine
        app.state.session_factory = create_session_factory(engine)
        # Photo classifier client (None when CV_SERVICE_URL is unset); tests may replace it.
        app.state.cv_client = create_cv_client(settings)
        log.info(
            "startup",
            env=settings.env,
            password_reset_enabled=settings.password_reset_enabled,
            cv_service=app.state.cv_client is not None,
            rate_limit_enabled=settings.rate_limit_enabled,
            rate_limit_storage=settings.rate_limit_storage_url.split("://", 1)[0],
        )
        try:
            yield
        finally:
            if app.state.cv_client is not None:
                await app.state.cv_client.aclose()
            await engine.dispose()
            log.info("shutdown")

    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        lifespan=lifespan,
        docs_url="/docs" if settings.show_docs else None,
        redoc_url=None,
        openapi_url="/openapi.json" if settings.show_docs else None,
    )
    app.state.settings = settings
    app.state.rate_limiter = RateLimiter(settings.rate_limit_enabled, settings.rate_limit_storage_url)

    register_error_handlers(app)
    if settings.cors_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=settings.cors_origins,
            allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
            allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
        )
    app.add_middleware(
        BodySizeLimitMiddleware,
        json_max_bytes=settings.max_json_body_bytes,
        multipart_max_bytes=settings.road_image_max_bytes + MULTIPART_OVERHEAD_BYTES,
    )
    app.add_middleware(RequestContextMiddleware)

    app.include_router(health_router, prefix=API_PREFIX)
    app.include_router(auth_router, prefix=API_PREFIX)  # per-endpoint limits (router.py)
    limited = [Depends(default_limit)]
    for router in (users_router, profit_router, shifts_router, road_router):
        app.include_router(router, prefix=API_PREFIX, dependencies=limited)
    return app
