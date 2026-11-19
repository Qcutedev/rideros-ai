#!/bin/sh
# Restores a backup INTO THE LIVE production stack (docs/DEPLOYMENT.md §Restore). Destructive: the
# current database is replaced by the backup. Check the backup first with restore_test.sh.
#   deploy/restore.sh --yes /opt/rideros/backups/db-<ts>.dump
set -eu

[ "${1:-}" = "--yes" ] || { echo "usage: $0 --yes DB_DUMP  (replaces the live data)" >&2; exit 2; }
shift
[ $# -ge 1 ] || { echo "usage: $0 --yes DB_DUMP" >&2; exit 2; }
dump=$1
[ -f "$dump" ] || { echo "no such file: $dump" >&2; exit 2; }
cd "$(dirname "$0")"
COMPOSE="docker compose -f compose.prod.yml"

echo "stopping the backend (no writes during the restore)"
$COMPOSE stop backend
$COMPOSE up -d --wait db

echo "recreating the database"
# shellcheck disable=SC2016  # expanded inside the db container
$COMPOSE exec -T db sh -c '
    psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 \
        -c "DROP DATABASE IF EXISTS \"$POSTGRES_DB\" WITH (FORCE)" \
        -c "CREATE DATABASE \"$POSTGRES_DB\" OWNER \"$POSTGRES_USER\""'
# shellcheck disable=SC2016
$COMPOSE exec -T db sh -c 'pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --no-owner --exit-on-error' < "$dump"
echo "database restored from $(basename "$dump")"

$COMPOSE up -d --wait backend
echo "RESTORE DONE: backend is healthy"
