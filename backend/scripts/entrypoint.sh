#!/bin/sh
# Container start: migrate, import the restaurant aggregates once (if mounted), then serve.
set -e
alembic upgrade head
if [ -n "$RESTAURANT_STATS_DIR" ]; then
    if [ -f "$RESTAURANT_STATS_DIR/summary.json" ]; then
        python -m scripts.import_restaurant_stats "$RESTAURANT_STATS_DIR" --if-empty
    else
        echo "RESTAURANT_STATS_DIR=$RESTAURANT_STATS_DIR has no summary.json; skipping import" >&2
    fi
fi
exec uvicorn --factory app.main:create_app --host 0.0.0.0 --port 8000 --no-access-log
