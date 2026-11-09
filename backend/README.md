# rideros-backend — FastAPI API (Phase 2)

Modular monolith (`docs/SYSTEM_ARCHITECTURE.md` §2.2). Python 3.14, FastAPI, SQLAlchemy 2 (async, asyncpg),
Alembic, PostgreSQL 18 + PostGIS 3.6.

Status: Phase 2 complete, awaiting approval. **P2a** platform (config, logging, errors, health) and auth;
**P2b** account/rider profile and TrueProfit; **P2c** pickup (model serving, predictions, restaurant analytics,
pickup log), shift simulator and rate limiting.

## Run with Docker (DB + API in one command)

From the repository root:

```powershell
copy .env.example .env      # then replace every CHANGE-ME (see the comment at the top of the file)
docker compose up --build   # db: 127.0.0.1:5432, API: http://127.0.0.1:8000/api/v1, docs: http://127.0.0.1:8000/docs
```

`scripts/entrypoint.sh` runs `alembic upgrade head`, imports the restaurant statistics if the table has no
dataset rows yet, then starts uvicorn. Both ports are bound to `127.0.0.1` only.

The image is built from the repository root (`backend/Dockerfile`, ignore rules in
`backend/Dockerfile.dockerignore`) because it installs the `rideros-ml` package from `ml/`; the pickled pipeline
needs it to load. `ml/artifacts` (gitignored, D4) is mounted read-only at `/artifacts`:

| Variable | Compose default | Meaning |
|---|---|---|
| `MODEL_DIR` | `/artifacts` | Artifact root; empty = start without a model (predictions answer 503, `/ready` is not ready) |
| `ACTIVE_MODEL_NAME` / `ACTIVE_MODEL_VERSION` | `pickup_o2p` / `1.0.0` | Folder `<MODEL_DIR>/<name>/<version>/` |
| `RESTAURANT_STATS_DIR` | `/artifacts/restaurant_stats/1.0.0` | Imported on start-up when `restaurants` has no dataset rows |

Produce the artifacts first with the ML pipeline (`ml/README.md`). Without them the API still starts.

Before `joblib.load` the registry checks the SHA-256 of every file in `metadata.json` -> `files`, the feature
schema and the library versions (scikit-learn, xgboost, pandas, numpy, joblib, Python major.minor). Any mismatch
stops the start-up; a pickle is never loaded unchecked. To import the statistics by hand on the host:

```powershell
cd backend
python -m uv run python -m scripts.import_restaurant_stats ..\ml\artifacts\restaurant_stats\1.0.0   # idempotent; --if-empty
```

## Run tests on the host

The tests use the compose `db` service and create a throw-away `rideros_test` database from
`TEST_DATABASE_URL` in the root `.env`. The name must end in `_test`, otherwise the run aborts. The API tests
build a small fake artifact (`tests/fake_artifact.py`); `tests/api/test_real_artifact.py` loads the real
`ml/artifacts/pickup_o2p/1.0.0` and is skipped when it is absent. Rate limits are off in the test settings,
except in `tests/api/test_rate_limits.py`.

```powershell
docker compose up -d db
cd backend
python -m uv sync
python -m uv run pytest --cov=app/modules     # 317 tests, ~45 s
python -m uv run ruff check . ; python -m uv run ruff format --check .
```

## Layout

```
app/
  main.py            create_app(settings) + lifespan (engine, session factory, model load, rate limiter)
  core/              config, security (Argon2id, JWT), logging (structlog + request id), errors, deps,
                     pagination (cursor), timezones (IANA via tzdata), schemas (StrictModel, PatchModel),
                     rate_limit
  ml/                registry (hash, schema and library checks, then load), predictor (feature row, interval)
  db/                base (naming convention, uuid PK), session, models (registry for Alembic)
  modules/<name>/    router -> service -> repository, plus schemas and models
alembic/versions/    hand-written migrations; tests check that they match the ORM models
scripts/             entrypoint.sh, import_restaurant_stats.py
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
| `DELETE /me` + `{"password"}` | 204; the user and all of their data are deleted (PDPA) | 403 `invalid_password` |
| `GET /me/rider-profile` | 200; defaults with `is_configured: false` until the first save | — |
| `PUT /me/rider-profile` | 200; replaces the whole profile | 400 `invalid_timezone`, 422 |

## TrueProfit

| Endpoint | Notes |
|---|---|
| `GET/POST /work-sessions`, `GET/PATCH/DELETE /work-sessions/{id}` | Aware datetimes, stored in UTC. 400 `invalid_time_range` / `work_session_too_long` (> 24 h), 409 `work_session_overlap` |
| `GET/POST /income`, `GET/PATCH/DELETE /income/{id}` | Optional `work_session_id` (own sessions only, else 400 `invalid_work_session`) |
| `GET/POST /expenses`, `GET/PATCH/DELETE /expenses/{id}` | `category`: fuel, maintenance, depreciation, other |
| `GET /profit/summary?period=day\|week\|month&date=` | One period containing `date` (default: today in the rider's zone) |
| `GET /profit/trends?granularity=day\|week\|month&from=&to=` | One point per bucket, empty ones included; at most 366 points (400 `range_too_large`) |

- Lists: `?limit=` (default 50, max 100) and `?cursor=` → `{"items": [...], "next_cursor": "..." | null}`, newest
  first. `from`/`to` are inclusive local dates (400 `invalid_date_range` if reversed, 400 `invalid_cursor`).
- Another user's id answers 404, exactly like an id that does not exist. PATCH applies only the fields sent.
- Money and other decimals are JSON strings (`"800.00"`). Input accepts numbers or strings.
- Rules (`app/modules/profit/calculator.py`, `docs/DATABASE_DESIGN.md` §3.7): weeks run Monday–Sunday in the
  rider's time zone (profile, default `Asia/Bangkok`); a session counts on the local date it started, also
  past midnight; `working_hours` of an income record counts only while it has no work session; with zero
  hours the per-hour values are `null` and `reason` is `"no_working_hours"`.

## Pickup (Order-to-Pickup)

The model predicts **Order-to-Pickup** minutes: from the order to the pickup at the restaurant. It is not the
rider's waiting time and not the cooking time. It was trained on Meituan data from China (CC BY-NC 4.0). Every
prediction carries the `foreign_dataset` warning and a disclaimer. `/pickup/model` carries the acknowledgement
*This research was supported by data provided by Meituan.*

| Endpoint | Notes |
|---|---|
| `GET /pickup/restaurants?q=&source=&limit=&cursor=` | Dataset restaurants (shared) and the caller's own; name search (trigram index); dataset first |
| `POST /pickup/restaurants` | 201 own restaurant (`name`, optional `location {lat, lng}`); the location is shown only to the owner |
| `GET /pickup/restaurants/{id}/analytics` | Dataset statistics: overall, 24 hourly cells for weekday and weekend, `data_availability` |
| `GET /pickup/restaurants/{id}/wait-stats` | The caller's own logs only: median, P80, `confidence` insufficient (n < 5), low (n < 20), ok |
| `POST /pickup/predictions` | 201; `restaurant_id`, optional aware `requested_at` (default now, read in the rider's zone). 400 `restaurant_not_supported` (own restaurants), 503 `model_unavailable` |
| `GET /pickup/predictions` | The caller's history, newest first |
| `GET /pickup/model` | Model card: test metrics against the baseline, interval coverage, limitations, acknowledgement |
| `GET/POST /pickup/logs`, `DELETE /pickup/logs/{id}` | Real pickups. 400 `invalid_pickup_times` (pickup before arrival), `pickup_wait_too_long` (> 3 h) |

- A prediction is a point value and an 80% conformal interval (`low` is never below 0). Show the interval.
- `warnings`: always `foreign_dataset`; `limited_restaurant_data` or `insufficient_restaurant_data` by the
  restaurant's order count in the dataset (sufficient >= 30, limited 5-29, insufficient <= 4).
- Each prediction stores its model version and input features (`pickup_predictions`). `model_versions` is synced
  from the artifact at start-up (one active version per name).
- Another rider's own restaurant or log answers 404 `restaurant_not_found` / `pickup_log_not_found`.

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

## Rate limits

In-memory moving window per process (`limits`). Over the limit: 429 `rate_limited` with `Retry-After`.

| Scope | Default | Key |
|---|---|---|
| `POST /auth/register` | 3/minute | IP |
| `POST /auth/login` | 5/minute | IP, and separately per e-mail |
| `POST /auth/forgot-password` | 3/minute | IP, and separately per e-mail |
| `POST /auth/reset-password` | 3/minute | IP |
| Everything else under `/api/v1`, except health | 60/minute | User from a valid access token, else IP |

Settings: `RATE_LIMIT_ENABLED`, `RATE_LIMIT_DEFAULT`, `RATE_LIMIT_LOGIN`, `RATE_LIMIT_REGISTER`,
`RATE_LIMIT_PASSWORD_RESET`. The client IP is the socket address; `X-Forwarded-For` is not trusted yet.
