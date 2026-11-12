# syntax=docker/dockerfile:1
# RiderOS AI photo classifier (POST /classify). CPU-only torch from the PyTorch CPU index (uv.lock),
# so the image carries no CUDA libraries. The model is mounted read-only from cv_service/artifacts.
# Build context: cv_service/ (allow-list in .dockerignore: no datasets, no weights in the image).
FROM python:3.14.6-slim-trixie AS builder
COPY --from=ghcr.io/astral-sh/uv:0.13.7 /uv /bin/uv
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/opt/venv
WORKDIR /app
COPY pyproject.toml uv.lock README.md ./
RUN uv sync --locked --no-dev --no-group train --no-install-project

FROM python:3.14.6-slim-trixie AS runtime
RUN useradd --system --uid 10001 --no-create-home app
ENV PATH=/opt/venv/bin:$PATH \
    PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1
WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY app ./app
USER app
EXPOSE 8100
HEALTHCHECK --interval=10s --timeout=3s --start-period=30s --retries=3 \
    CMD ["python", "-c", "import json,sys,urllib.request; r=urllib.request.urlopen('http://127.0.0.1:8100/health', timeout=2); sys.exit(0 if json.load(r)['status'] == 'ok' else 1)"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8100", "--workers", "1"]
