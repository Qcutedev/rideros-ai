# PostgreSQL 18 + PostGIS 3 for amd64 and arm64 (postgis/postgis publishes amd64 only).
# PGDG packages, as in postgis/postgis. PGDG builds PostGIS against its newest PostgreSQL 18 minor,
# so the server package is installed in the same step: an older server fails to load postgis-3.so
# ("undefined symbol"). PGDG keeps only the newest PostGIS 3.x (3.7 at the time of writing; dev runs
# postgis/postgis:18-3.6, and a 3.6 dump restores into 3.7). The migrations create the extensions
# (postgis, pg_trgm, btree_gist), so no init script is needed.
FROM postgres:18.7-trixie
RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-18 postgresql-18-postgis-3 \
    && rm -rf /var/lib/apt/lists/*
