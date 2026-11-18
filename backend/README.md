# rideros-backend — FastAPI API (Phase 2)

Modular monolith (`docs/SYSTEM_ARCHITECTURE.md` §2.2). Python 3.14, FastAPI, SQLAlchemy 2 (async, asyncpg),
Alembic, PostgreSQL 18 + PostGIS 3.6.

Status: Phase 2 complete, awaiting approval. **P2a** platform (config, logging, errors, health) and auth;
**P2b** account/rider profile and TrueProfit; **P2c** shift simulator and rate limiting. P2c also had a Pickup
module (model serving, predictions, restaurant analytics, pickup log); it was removed on 2026-11-18 (migration
0006 drops its tables, `docs/HANDOFF.md` §4.20).

## Run with Docker (DB + API in one command)

From the repository root:

```powershell
copy .env.example .env      # then replace every CHANGE-ME (see the comment at the top of the file)
docker compose up --build   # db: 127.0.0.1:5432, API: http://127.0.0.1:8000/api/v1, docs: http://127.0.0.1:8000/docs
```

`scripts/entrypoint.sh` runs `alembic upgrade head`, then starts uvicorn. Both ports are bound to `127.0.0.1`
only. The image is built from the repository root (`backend/Dockerfile`, ignore rules in
`backend/Dockerfile.dockerignore`). The backend loads no model itself: the photo classifier runs in
`cv_service` and is called over HTTP (`CV_SERVICE_URL`).

## Run tests on the host

The tests use the compose `db` service and create a throw-away `rideros_test` database from
`TEST_DATABASE_URL` in the root `.env`. The name must end in `_test`, otherwise the run aborts. Rate limits are
off in the test settings, except in `tests/api/test_rate_limits.py`.

```powershell
docker compose up -d db
cd backend
python -m uv sync
python -m uv run pytest --cov=app/modules     # 463 tests, ~2 min
python -m uv run ruff check . ; python -m uv run ruff format --check .
```

## Layout

```
app/
  main.py            create_app(settings) + lifespan (engine, session factory, cv client, rate limiter)
  core/              config, security (Argon2id, JWT), logging (structlog + request id), errors, deps,
                     pagination (cursor), timezones (IANA via tzdata), schemas (StrictModel, PatchModel),
                     rate_limit
  ml/                model_versions table + upsert (the photo classifier registers itself there)
  db/                base (naming convention, uuid PK), session, models (registry for Alembic)
  modules/<name>/    router -> service -> repository, plus schemas and models
alembic/versions/    hand-written migrations; tests check that they match the ORM models
scripts/             entrypoint.sh, set_role.py, evaluate_work_patterns.py
tests/unit, tests/api
```

## Auth contract

| Endpoint | Success | Notable errors |
|---|---|---|
| `POST /auth/register` | 201 user | 400 `weak_password`, 409 `email_taken`, 422 |
| `POST /auth/login` | 200 token pair | 401 `invalid_credentials` (same body for unknown e-mail) |
| `POST /auth/refresh` | 200 new pair (rotation) | 401 `invalid_refresh_token`, `refresh_token_expired`, `refresh_token_revoked` |
| `POST /auth/logout` | 204 (also for unknown tokens) | — |
| `POST /auth/forgot-password` | 202 always | 503 `password_reset_unavailable` in production without an e-mail provider |
| `POST /auth/reset-password` | 204 | 400 `invalid_reset_token`, 400 `weak_password`, 503 as above |
| `GET /me` | 200 user | 401 `not_authenticated`, `invalid_token`, `token_expired` |

- Access token: HS256 JWT, 15 minutes. Refresh token: opaque 256-bit, 30 days. Only SHA-256 hashes are stored.
- Presenting a revoked refresh token (already rotated or logged out) revokes every token of that login session.
- Logout ends one session (one login and its rotations). Other devices stay signed in.
- Password reset revokes every refresh token of the user.
- **D5, development only:** the reset link is written to the log as a `DEV ONLY` warning. With `ENV=production`
  and no e-mail provider, both reset endpoints return 503 and nothing is logged.

Errors always use `{"error": {"code", "message", "details"}}`. Every response carries `X-Request-ID`.

## Account and rider profile

| Endpoint | Success | Notable errors |
|---|---|---|
| `PATCH /me` | 200 user (`display_name` only) | 422 |
| `DELETE /me` + `{"password"}` | 204; the user and all of their data are deleted (PDPA), road report photos included; shared incidents get their counters recomputed and are removed when no report is left | 403 `invalid_password` |
| `GET /me/rider-profile` | 200; defaults with `is_configured: false` until the first save | — |
| `PUT /me/rider-profile` | 200; replaces the whole profile | 400 `invalid_timezone`, 422 |

## TrueProfit

| Endpoint | Notes |
|---|---|
| `GET/POST /work-sessions`, `GET/PATCH/DELETE /work-sessions/{id}` | Aware datetimes, stored in UTC. 400 `invalid_time_range` / `work_session_too_long` (> 24 h), 409 `work_session_overlap` |
| `GET/POST /income`, `GET/PATCH/DELETE /income/{id}` | Optional `work_session_id` (own sessions only, else 400 `invalid_work_session`) |
| `GET/POST /expenses`, `GET/PATCH/DELETE /expenses/{id}` | `category`: fuel, maintenance, depreciation, other |
| `GET /profit/summary?period=day\|week\|month&date=` | One period containing `date` (default: today in the rider's zone) |
| `GET /profit/trends?granularity=day\|week\|month&from=&to=` | One point per bucket, empty ones included; at most 366 points (400 `range_too_large`). Each point has `net_profit_moving_average` (trailing mean: 7 days / 4 weeks / 3 months) and `net_profit_trend` (least-squares line, only when the slope is significant at p < 0.05); `analysis` holds `status` (`insufficient_data` below 4 buckets with records), `direction` (`up`/`down`/`flat`), `slope_per_bucket`, `p_value` |
| `GET /profit/patterns` | K-Means work patterns of the last 180 days: `status` `ok` / `insufficient_data` (< 30 sessions) / `no_clear_pattern`; groups with time-of-day, length and day-type codes plus an estimated net profit/hour from linked records (method: `app/modules/profit/patterns.py`, benchmark: `scripts/evaluate_work_patterns.py` → `reports/work_patterns_benchmark.json`) |
| `GET /profit/heatmap` | Estimated net profit/hour by local weekday × 2-hour slot over the last 90 days. Money reaches a slot only through work sessions (records carry a date only): linked records, plus unlinked records of the same local day split over that day's sessions by length; each session spreads its money evenly over its minutes. Only sessions with income count. `status` `insufficient_data` below 10 counted sessions; a cell's per-hour values are `null` below 2 sessions or 1 hour; `excluded_*` counts what could not be placed (method: `app/modules/profit/heatmap.py`) |

- Lists: `?limit=` (default 50, max 100) and `?cursor=` → `{"items": [...], "next_cursor": "..." | null}`, newest
  first. `from`/`to` are inclusive local dates (400 `invalid_date_range` if reversed, 400 `invalid_cursor`).
- Another user's id answers 404, exactly like an id that does not exist. PATCH applies only the fields sent.
- Money and other decimals are JSON strings (`"800.00"`). Input accepts numbers or strings.
- Rules (`app/modules/profit/calculator.py`, `docs/DATABASE_DESIGN.md` §3.7): weeks run Monday–Sunday in the
  rider's time zone (profile, default `Asia/Bangkok`); a session counts on the local date it started, also
  past midnight; `working_hours` of an income record counts only while it has no work session; with zero
  hours the per-hour values are `null` and `reason` is `"no_working_hours"`.

## Shift simulator

| Endpoint | Notes |
|---|---|
| `GET/POST /shift-scenarios`, `GET/PATCH/DELETE /shift-scenarios/{id}` | Create, and every change of an input, estimates at once |
| `POST /shift-scenarios/{id}/estimate` | Re-estimate with the current profile and history |
| `POST /shift-scenarios/compare` + `{"ids": [...]}` | 2-5 own ids; returns them in order, plus `best_net_profit_id` and `best_net_profit_per_hour_id` |

- Times are local `HH:MM` without a zone. An end before the start crosses midnight. Length 30-960 minutes
  (400 `invalid_shift_length`). `planned_weekday` 0 = Monday.
- `estimation_method`:
  - `assumptions` (default): `orders_per_hour` x `income_per_order` x hours. Distance costs use `km_per_order`
    with the fuel and depreciation values from the scenario, else from the rider profile, else they are left out
    with the warning `distance_costs_not_included`. Plus `other_costs`. 400 `missing_assumption`.
  - `historical`: the rider's own work sessions of the last 84 days. It uses the same weekday when that has at
    least 5 days, else all days (`estimate_details.basis`). Net profit per hour x hours - `other_costs`;
    `estimate_low`/`estimate_high` = P20-P80 of the daily values. 400 `insufficient_history` below 5 days.
  - `ml`: reserved, 400 `estimation_method_unavailable`.
- Scenarios are always estimates (`is_estimate: true`) and never count in TrueProfit summaries.
  `actual_work_session_id` may link one of the rider's own work sessions (else 400 `invalid_work_session`).

## RoadContext (Phase 5)

| Endpoint | Success | Notable errors |
|---|---|---|
| `POST /road/reports` (multipart: `category`, `lat`, `lng`, `description?` ≤ 500, `image?`) | 201 `{report_id, incident_id, merged, status, incident}` | 409 `already_reported` (details: `incident_id`), 413 `image_too_large`, 415 `unsupported_image`, 503 `image_storage_unavailable`, 422 |
| `GET /road/reports` | 200 page of the rider's own reports (`has_image`, `ai_status`, `ai_label`, `ai_confidence`, `incident_status`) | — |
| `GET /road/reports/{id}/image` | 200 `image/jpeg`, own reports only | 404 `image_not_found` |
| `GET /road/incidents?bbox=min_lng,min_lat,max_lng,max_lat` | 200 `{items, truncated, notice}`; open incidents only, ≤ 300, newest report first | 400 `invalid_bbox` (span > 2°) |
| `GET /road/incidents/nearby?lat=&lng=&radius_m=` | 200 same shape + `distance_m`; radius 50–5,000 (default 2,000), ≤ 100, closest first | 422 |
| `GET /road/incidents/{id}` | 200 incident + `my_report`, `my_confirmation`, `notice` (any status) | 404 `incident_not_found` |
| `POST /road/incidents/{id}/confirmations` + `{"still_present": bool}` | 200 incident detail; a new answer replaces the rider's previous one | 404, 409 `incident_closed` |
| `PATCH /road/incidents/{id}/status` + `{"status": "resolved"\|"rejected"}` | 200 incident; admin only | 403 `admin_only`, 409 `incident_closed` |

- Categories: `flooding`, `road_damage`, `road_closure`, `road_obstacle`, `traffic_incident`. Status: `unverified`,
  `corroborated`, `resolved`, `expired`, `rejected`. Incidents never show who reported them.
- Grouping: a report joins the closest open incident of the same category within the category's radius whose last
  report is within its window; otherwise it opens a new incident at its own location. Reports and "still present"
  move `last_reported_at` and set `expires_at` = last report + TTL. Defaults (not validated yet; `ROAD_RULES`):

  | Category | Radius | Window | TTL |
  |---|---|---|---|
  | flooding | 300 m | 6 h | 12 h |
  | road_damage | 50 m | 30 d | 90 d |
  | road_closure | 200 m | 12 h | 24 h |
  | road_obstacle | 100 m | 3 h | 6 h |
  | traffic_incident | 200 m | 2 h | 3 h |

- `unverified` → `corroborated` when ≥ 2 riders (`ROAD_CORROBORATE_MIN_REPORTERS`) reported or said "still present"
  within the window. Open → `resolved` when ≥ 2 riders (`ROAD_RESOLVE_MIN_CLEARED`) said "cleared" after the last
  report. An open incident past `expires_at` reads as `expired` at once and is written as `expired` by the next
  RoadContext write (no scheduler). `corroborated` means "several riders reported it", never "verified".
- Photos: JPEG / PNG / WebP by magic bytes, ≤ 5 MB (`ROAD_IMAGE_MAX_BYTES`), ≤ 40 MP; re-encoded to JPEG
  ≤ 1600 px without EXIF (GPS included) and stored as `<uuid>.jpg` under `ROAD_IMAGE_DIR` (docker volume
  `road-images`). Only the author can fetch a photo.
- Photo suggestion (P5c, `app/modules/road/classify.py`): when `CV_SERVICE_URL` is set, a report with a photo
  is saved with `ai_status = "pending"`. After the response, a background task sends the stored JPEG to
  `cv_service` `POST /classify` and writes `ai_label` (`flooding` / `road_damage` / `other`), `ai_confidence`
  (3 decimals) and `ai_model_version_id`. The first time a classifier version answers, its row is added to
  `model_versions` from `GET /model`, with the test metrics copied verbatim. The suggestion never changes the
  category or the status. Any failure (timeout, 5xx, an unknown label, a model without metrics) leaves
  `ai_status = "failed"` and does not affect the report. A row still `pending` after 10 minutes (a task lost
  to a restart) reads as `failed`. With no `CV_SERVICE_URL`, photos keep `ai_status = "none"`.
- Admins: `python -m scripts.set_role <email> admin` (in docker: `docker compose exec backend python -m
  scripts.set_role <email> admin`). There is no API to grant roles.

## Rate limits

In-memory moving window per process (`limits`). Over the limit: 429 `rate_limited` with `Retry-After`.

| Scope | Default | Key |
|---|---|---|
| `POST /auth/register` | 3/minute | IP |
| `POST /auth/login` | 5/minute | IP, and separately per e-mail |
| `POST /auth/forgot-password` | 3/minute | IP, and separately per e-mail |
| `POST /auth/reset-password` | 3/minute | IP |
| `POST /road/reports`, `POST /road/incidents/{id}/confirmations` (together) | 10/minute | User |
| Everything else under `/api/v1`, except health | 60/minute | User from a valid access token, else IP |

Settings: `RATE_LIMIT_ENABLED`, `RATE_LIMIT_DEFAULT`, `RATE_LIMIT_LOGIN`, `RATE_LIMIT_REGISTER`,
`RATE_LIMIT_PASSWORD_RESET`, `RATE_LIMIT_ROAD_REPORT`. The client IP is the socket address; `X-Forwarded-For` is not trusted yet.
