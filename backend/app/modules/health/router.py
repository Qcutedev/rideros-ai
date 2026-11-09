from typing import Any

import structlog
from fastapi import APIRouter, Request, status
from fastapi.responses import JSONResponse
from sqlalchemy import text

router = APIRouter(tags=["health"])
log = structlog.get_logger(__name__)


@router.get("/health")
async def health() -> dict[str, str]:
    """Liveness: the process is up. Does not touch the database."""
    return {"status": "ok"}


@router.get("/ready", responses={503: {"description": "A dependency is not ready"}})
async def ready(request: Request) -> JSONResponse:
    """Readiness: the database answers and the pickup model is loaded."""
    checks: dict[str, Any] = {}
    try:
        async with request.app.state.engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        checks["database"] = "ok"
    except Exception as exc:  # report any driver/network error as not ready
        log.warning("readiness_database_failed", error_type=type(exc).__name__)
        checks["database"] = "unavailable"

    model = getattr(request.app.state, "model", None)
    checks["model"] = f"ok ({model.name}/{model.version})" if model is not None else "not_loaded"

    ok = checks["database"] == "ok" and model is not None
    return JSONResponse(
        status_code=status.HTTP_200_OK if ok else status.HTTP_503_SERVICE_UNAVAILABLE,
        content={"status": "ok" if ok else "unavailable", "checks": checks},
    )
