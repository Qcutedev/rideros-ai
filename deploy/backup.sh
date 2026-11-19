#!/bin/sh
# Backup of the production stack (docs/DEPLOYMENT.md §Backup): a pg_dump (custom format) of the
# database. Keeps the newest $BACKUP_KEEP dumps (default 7).
# Daily via cron on the server, e.g.:
#   15 3 * * * /opt/rideros/app/deploy/backup.sh >> /opt/rideros/backups/backup.log 2>&1
# The files hold personal data (accounts, income, work times): they are written mode 600.
set -eu

cd "$(dirname "$0")"
env_value() { # KEY DEFAULT -> value from deploy/.env, else the default
    value=$(sed -n "s/^$1=//p" .env 2>/dev/null | tail -n 1)
    printf '%s' "${value:-$2}"
}
BACKUP_DIR=${BACKUP_DIR:-$(env_value BACKUP_DIR /opt/rideros/backups)}
BACKUP_KEEP=${BACKUP_KEEP:-$(env_value BACKUP_KEEP 7)}
COMPOSE="docker compose -f compose.prod.yml"

umask 077
mkdir -p "$BACKUP_DIR"
ts=$(date -u +%Y%m%dT%H%M%SZ)
db_file="$BACKUP_DIR/db-$ts.dump"

# Write to .part first, so a failed run never leaves a file that looks complete.
$COMPOSE exec -T db sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom' > "$db_file.part"
mv "$db_file.part" "$db_file"

prune() { # PATTERN: delete all but the newest $BACKUP_KEEP matches
    # shellcheck disable=SC2012  # names are ours: db-<UTC timestamp>.dump, no spaces
    ls -1t "$BACKUP_DIR"/$1 2>/dev/null | tail -n +"$((BACKUP_KEEP + 1))" | while read -r old; do rm -f -- "$old"; done
}
prune 'db-*.dump'

echo "$(date -u +%FT%TZ) backup ok: $(basename "$db_file") ($(wc -c < "$db_file") bytes)"
