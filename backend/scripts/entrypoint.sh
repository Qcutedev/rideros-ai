#!/bin/sh
# Container start: migrate, then serve.
set -e
alembic upgrade head
exec uvicorn --factory app.main:create_app --host 0.0.0.0 --port 8000 --no-access-log
