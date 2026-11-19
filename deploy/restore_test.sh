#!/bin/sh
# Restore test (docs/DEPLOYMENT.md §Restore): restores a backup into a throw-away PostgreSQL
# container built from the production db image, then compares it with the live database:
# row count of every table, the Alembic revision, and the PostGIS version.
# Touches nothing in the live stack (reads only). Exit 0 = everything matches.
#   deploy/restore_test.sh /opt/rideros/backups/db-<ts>.dump
# Run it right after backup.sh: rows written in between show up as differences.
set -eu

[ $# -ge 1 ] || { echo "usage: $0 DB_DUMP" >&2; exit 2; }
dump=$1
cd "$(dirname "$0")"
COMPOSE="docker compose -f compose.prod.yml"
name=rideros-restore-test-$$
image=$($COMPOSE images -q db | head -n 1)
[ -n "$image" ] || { echo "db image not found; start the stack first" >&2; exit 2; }

cleanup() { docker rm -f "$name" > /dev/null 2>&1 || true; }
trap cleanup EXIT INT TERM

# No network: the copy is reachable only through docker exec.
docker run -d --name "$name" --network none \
    -e POSTGRES_PASSWORD="$(od -An -tx1 -N24 /dev/urandom | tr -d ' \n')" -e POSTGRES_DB=restored \
    "$image" > /dev/null
i=0
until docker exec "$name" pg_isready -U postgres -d restored > /dev/null 2>&1; do
    i=$((i + 1)); [ $i -le 60 ] || { echo "restore container did not start" >&2; exit 1; }; sleep 1
done
sleep 2 # the entrypoint restarts the server once after initdb

start=$(date +%s)
docker exec -i "$name" pg_restore -U postgres -d restored --no-owner --exit-on-error < "$dump"
echo "restored $(basename "$dump") in $(( $(date +%s) - start )) s"

# Same query on both sides: "table<TAB>rows", plus the migration revision and the PostGIS version.
query="SELECT format('%s%s%s', table_name, chr(9), (xpath('/row/n/text()',
         query_to_xml(format('SELECT count(*) AS n FROM public.%I', table_name), false, true, '')))[1]::text)
       FROM information_schema.tables
       WHERE table_schema = 'public' AND table_type = 'BASE TABLE' AND table_name <> 'spatial_ref_sys'
       UNION ALL SELECT 'migration' || chr(9) || version_num FROM alembic_version
       UNION ALL SELECT 'postgis' || chr(9) || postgis_lib_version()
       ORDER BY 1"
live=$($COMPOSE exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tA -c "$0"' "$query")
restored=$(docker exec "$name" psql -U postgres -d restored -tA -c "$query")

status=0
printf '%-28s %12s %12s\n' table live restored
echo "$live" | while IFS="$(printf '\t')" read -r table n; do
    m=$(echo "$restored" | awk -F '\t' -v t="$table" '$1 == t { print $2 }')
    mark=""; [ "$n" = "$m" ] || mark="  <-- differs"
    printf '%-28s %12s %12s%s\n' "$table" "$n" "${m:-missing}" "$mark"
done
[ "$live" = "$restored" ] || status=1

if [ $status -eq 0 ]; then echo "RESTORE TEST PASSED"; else echo "RESTORE TEST FAILED"; fi
exit $status
