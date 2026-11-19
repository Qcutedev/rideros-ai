# syntax=docker/dockerfile:1
# RiderOS AI backend.
# Build context: repository root (see docker-compose.yml); ignore rules in Dockerfile.dockerignore.
FROM python:3.14.10-slim-trixie AS builder
COPY --from=ghcr.io/astral-sh/uv:0.13.7 /uv /bin/uv
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/opt/venv
WORKDIR /app
COPY backend/pyproject.toml backend/uv.lock backend/README.md ./
RUN uv sync --locked --no-dev --no-install-project --no-editable

FROM python:3.14.10-slim-trixie AS runtime
# libgomp1: OpenMP runtime used by scikit-learn (Work Patterns K-Means).
# upgrade: Debian security fixes newer than the base image (docs/SECURITY_AUDIT.md). The system pip
# is removed because the app runs from /opt/venv and pip's vendored packages carry known CVEs.
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends libgomp1 \
    && rm -rf /var/lib/apt/lists/* && python -m pip uninstall -y pip \
    && useradd --system --uid 10001 --no-create-home app
ENV PATH=/opt/venv/bin:$PATH \
    PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1
WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY backend/alembic.ini ./
COPY backend/alembic ./alembic
COPY backend/app ./app
COPY backend/scripts ./scripts
USER app
EXPOSE 8000
HEALTHCHECK --interval=10s --timeout=3s --start-period=60s --retries=3 \
    CMD ["python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/api/v1/ready', timeout=2).status == 200 else 1)"]
# Migrations run before the server starts (single-instance setup).
CMD ["sh", "scripts/entrypoint.sh"]
