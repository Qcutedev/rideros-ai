# HANDOFF — RiderOS AI

> อัปเดตล่าสุด: 2026-11-12 · สถานะ: **Phase 3 อนุมัติแล้ว 2026-11-11 · ถัดไป Phase 4 Integration (W9) — เริ่มใน Session ใหม่ที่ §4.2** · Brand intro + ไอคอนแอป (`cdb78ba`, §4.8, ก่อนเริ่ม Phase 4) · P3a + P3b + UI (§4.4, `56526ee`) · P3c (a) Profile (`549c27b`, §4.5) · (b) Pickup (`f76d050`, §4.6) · (c) Shift (`aed472f`, §4.7) · การตัดสินใจ §4.1, §4.3, §4.6, §4.7 ยืนยันครบ · Phase 2 อนุมัติ + Commit แล้ว
> Phase 0 + Decisions D1–D7 อนุมัติแล้ว (ดู `docs/PROJECT_PLAN.md` §4) · Git บน `main`: `a7fe027` (Phase 0–1) → `5d7be02` (Phase 2) → `56526ee` (Phase 3 P3a–P3b + UI) → `549c27b` (P3c-a) → `f76d050` (P3c-b) → `aed472f` (P3c-c) → `cdb78ba` (Brand intro) · ยังไม่มี Remote / ยังไม่ Push · Commit เฉพาะเมื่อผู้ใช้สั่ง

**Session ใหม่ (Phase 3) ให้อ่านตามลำดับ:** ไฟล์นี้ (โดยเฉพาะ §4) → `docs/DEVELOPMENT_ROADMAP.md` (W6–W8 + Phase 3 Exit Criteria) → `docs/SYSTEM_ARCHITECTURE.md` (§2.1 Flutter, §3 Data Flows, §4 API, §5 Security, §6 Folder Structure `mobile/`) → `backend/README.md` (API Contract จริงที่ App ต้องเรียก) → `docs/PROJECT_PLAN.md` (Scope ของหน้าจอ)

---

## 1. สรุป Phase 1 (เสร็จและอนุมัติแล้ว)

| งาน | ผลลัพธ์ / ไฟล์ |
|---|---|
| Dataset | Meituan INFORMS TSL ที่ Commit `1f9b4288…` + SHA-256 Pin → `ml/data/raw/` (gitignored) · License Gate + Validation Gate **PASS** |
| Build | `ml/data/processed/orders.parquet` — 546,226 orders (gitignored) |
| Model | `pickup_o2p` **1.0.0** = **XGBoost** (เลือกจาก Val MAE) → `ml/artifacts/pickup_o2p/1.0.0/` (gitignored, D4) |
| ผล Test (24 ต.ค. 2022, n=64,701, ประเมินครั้งเดียว) | MAE **4.509** นาที · RMSE 6.061 · R² 0.281 · Baseline POI median 4.636 · Interval 80% → Coverage จริง **81.6%** (กว้างเฉลี่ย 14.95 นาที) |
| Restaurant stats | `ml/artifacts/restaurant_stats/1.0.0/` — `restaurant_reference.csv` (4,938 ร้าน), `restaurant_time_stats.csv` (73,340 cells), `summary.json` |
| Reports (committed) | `ml/reports/data_validation/`, `ml/reports/eda/`, `ml/reports/pickup_o2p/1.0.0/RESULTS.md` |
| Tests | `ml/tests/` — **134 passed** (`python -m uv run pytest`, ~70 s) |
| Docs | `ml/README.md`, `ml/data/SOURCES.md` (License + Acknowledgement) |

**ความแม่นยำที่ผู้ใช้รับทราบแล้ว:** ดีกว่า Baseline รายร้านแค่ 2.7%; ข้อมูลชุดนี้ทำได้ดีกว่านี้อีกไม่มาก (Ablation ที่ใช้ข้อมูล Real-time = 4.479). **App ต้องแสดงเป็นช่วง (Interval) + ป้าย "ค่าประมาณจากข้อมูลต่างประเทศ"** ไม่แสดงตัวเลขเดี่ยว

### การตัดสินใจทางเทคนิคใน Phase 1 (อยู่ในโค้ดและ Config แล้ว)
1. ตัด 88 Ambiguous orders · `da_id` จาก Waybill ที่ Dispatch ครั้งแรก · Target rule 1 ≤ y ≤ 120 นาที
2. Timezone UTC+8 · ใช้ `is_weekend` แทน day-of-week
3. Feature *Deployable* = `poi_id, da_id, hour, minute_sin, minute_cos, is_weekend` (Backend ต้องส่งชุดนี้) · *Ablation* ใช้วัดผลเท่านั้น
4. Meituan estimate = Benchmark ไม่ใช่ Feature · ไม่ Refit บน Train+Val (Conformal ใช้ Val)

---

## 2. สิ่งที่ Phase 2 ต้องใช้จาก Phase 1 (Contract ของ Backend)

| ใช้ทำอะไร | ไฟล์ |
|---|---|
| โหลดโมเดล | `ml/artifacts/pickup_o2p/1.0.0/pipeline.joblib` — **ต้องตรวจ SHA-256 กับ `metadata.json` → `files` ก่อน `joblib.load` ทุกครั้ง** (pickle รันโค้ดได้) ดูตัวอย่างใน `ml/tests/test_artifact.py` |
| Input contract | `feature_schema.json` · สร้างแถว Input ด้วย `rideros_ml.features.inference.make_feature_row(poi_id, da_id, local_time)` (`local_time` = naive local datetime) |
| `da_id` ของร้าน | `restaurant_reference.csv` คอลัมน์ `reference_da_id` |
| Interval | `conformal.json` (`q_low`, `q_high`; low ไม่ต่ำกว่า 0) → `ConformalInterval.interval()` |
| ตาราง `restaurants` / `restaurant_time_stats` | `restaurant_reference.csv` / `restaurant_time_stats.csv` (มี `data_availability`: sufficient ≥ 30 orders, limited 5–29, insufficient ≤ 4) |
| ตาราง `model_versions` | `metadata.json` + `metrics.json` |
| Library versions ที่ต้องตรงกันตอนโหลด | `metadata.json` → `libraries` (Python 3.14, scikit-learn 1.9.1, xgboost 3.4.1, pandas 3.1.1) |

Artifact อยู่นอก Git → Backend ต้องอ่านจาก Path ที่ตั้งใน Config/ENV (ห้าม Commit Artifact เข้า `backend/`)

## 3. งานถัดไป — Phase 2 (W3–W5 ตาม Roadmap)

**ก่อนเริ่ม (ผู้ใช้ต้องทำเอง):**
1. เปิด Docker Desktop ให้รันอยู่ (ตอนตรวจ 2026-11-09 ติดตั้งแล้วแต่ Daemon ไม่ได้รัน; มี Autostart ใน Registry `Run` แล้ว แนะนำเปิด "Start Docker Desktop when you sign in")
   ตรวจด้วย: `docker version` ต้องเห็น Server
2. (ทางเลือก) สร้าง GitHub Repo แบบ **Private** ตาม D2 — ต้อง `gh auth login` เอง; **ถามผู้ใช้ก่อนสร้าง/Push**

**ลำดับงาน:**
- **P2a (W3):** Docker Compose (PostGIS) · FastAPI Skeleton · Config/Logging/Errors · Alembic Migration ชุดแรก · Auth (Register/Login/Refresh/Logout) + Tests · Forgot Password แบบ D5 (Dev log เท่านั้น)
  → **เสร็จ 2026-11-09 (ยังไม่ Commit)** — `backend/` + `docker-compose.yml` + `.env.example`; `postgis/postgis:18-3.6`, `python:3.14.6-slim-trixie`; Migration `0001` (users, refresh_tokens, password_reset_tokens + postgis/pg_trgm); 86 tests ผ่าน, Coverage `app/modules` 98%; วิธีรันดู `backend/README.md`. `.env` (gitignored) สร้างแล้วด้วย Secret สุ่ม
  · gitleaks `zricethezav/gitleaks:v8.30.0` (ไม่ได้ติดตั้งในเครื่อง ใช้ผ่าน Docker; Git Bash ต้องตั้ง `MSYS_NO_PATHCONV=1`): `git` (History) + `dir` (สำเนาไฟล์ที่จะ Commit ได้ = `git ls-files -co --exclude-standard`) → no leaks found
- **P2b (W4):** TrueProfit CRUD + Summaries/Trends (Timezone-aware) + Tests · Rider Profile
  → **เสร็จ 2026-11-09 (ยังไม่ Commit)** — Migration `0002` (`rider_profiles`, `work_sessions`, `income_records`, `expense_records` + `btree_gist`); โมดูลใหม่ `app/modules/profit/` (router/service/repository/schemas/models + `calculator.py` = กฎ §3.7 แบบ Pure function); `app/modules/users/` เพิ่ม PATCH/DELETE `/me`, GET/PUT `/me/rider-profile`; Helper กลาง `app/core/pagination.py` (Cursor), `app/core/timezones.py`, `app/core/schemas.py` (StrictModel/PatchModel); เพิ่ม Dependency `tzdata` (Windows ไม่มี IANA DB)
  · Tests **223 passed** (เดิม 86): `tests/unit/test_profit_calculator.py`, `tests/api/test_profile.py`, `test_trueprofit_crud.py`, `test_profit_reports.py`, `test_cross_user.py` (+ Exclusion constraint ใน `test_migrations.py`) · Coverage `app/modules` **99%** · ruff ผ่าน
  · `docker compose up --build` → Migration `0001 -> 0002` รันเอง, Backend healthy, Smoke test ผ่าน (register → profile → session → income/expense → summary/trends → DELETE /me) · gitleaks `dir` + `git` → no leaks found
- **P2c (W5):** Pickup API (Model Registry, Predictions, Analytics, Pickup Log) · Shift Simulator API · Rate Limiting · Cross-user Tests
  → **เสร็จ 2026-11-09 (ยังไม่ Commit)** — Migration `0003` (`restaurants` + GiST/Trigram index, `restaurant_time_stats`, `pickup_logs`, `model_versions`, `pickup_predictions`, `shift_scenarios`); `app/ml/registry.py` (ตรวจ SHA-256 ทุกไฟล์ + Feature schema + Library versions ก่อน `joblib.load`, Fail fast) + `app/ml/predictor.py`; โมดูลใหม่ `app/modules/pickup/` (+ `importer.py`) และ `app/modules/shifts/` (+ `estimator.py`); `app/core/rate_limit.py` (`limits`, In-memory); `/ready` ตรวจโมเดลด้วย; `scripts/entrypoint.sh` (migrate → import ถ้าว่าง → uvicorn) + `scripts/import_restaurant_stats.py`
  · `ml/pyproject.toml` แยก Dependency group `train` (catboost/optuna/matplotlib) ออกจาก Runtime; Linux ใช้ `xgboost-cpu`; `ml/uv.lock` เปลี่ยนแค่ nvidia-nccl ออก + xgboost-cpu เข้า. Backend ติดตั้ง `rideros-ml` เป็น Path dependency (`../ml`) + Pin เวอร์ชัน Library ตาม `metadata.json`
  · Docker: Build context = Root (`backend/Dockerfile` + `backend/Dockerfile.dockerignore` แบบ Allow-list), Mount `./ml/artifacts:/artifacts:ro`, Image 1.03 GB
  · Tests **317 passed** (~45 s; เดิม 223): `tests/unit/test_registry.py`, `test_shift_estimator.py`, `tests/api/test_pickup.py`, `test_shifts.py`, `test_rate_limits.py`, `test_real_artifact.py` (ข้ามถ้าไม่มี Artifact จริง) + Cross-user ของ P2c ใน `test_cross_user.py` · Coverage `app/modules` **99%** · ruff ผ่าน
  · Import จริงใน Dev DB: 4,938 ร้าน + 73,340 cells (~14 s, Idempotent) · `docker compose up --build` → healthy พร้อมโมเดลจริง, Smoke test ผ่าน (POI-1 เวลา 18:30 Bangkok → 11.43 นาที ช่วง 5.04–19.99; `/pickup/model` MAE 4.509 vs Baseline 4.636, Coverage 81.6% ตรงกับ Phase 1; Login ครั้งที่ 6 → 429) · gitleaks `dir` (168 ไฟล์) + `git` → no leaks found

### 3.1 การตัดสินใจใน P2a — **ผู้ใช้ยืนยันแล้ว (OK ทั้ง 6 ข้อ, 2026-11-09)**
1. `POST /auth/reset-password` คืน **204** (สำเร็จ) / **400 `invalid_reset_token`** — ต่างจากตาราง §4 ที่เขียน "202 เสมอ" (เหตุผล: ผู้ใช้ต้องรู้ว่าลิงก์หมดอายุ; `forgot-password` ยังคืน 202 เสมอ)
2. `register` คืน User เท่านั้น (ไม่คืน Token → App ต้อง Login ต่อ); Email ซ้ำ → 409 `email_taken`
3. `logout` ใช้ Refresh Token อย่างเดียว และ Revoke ทั้ง Family (Session นั้น) เครื่องอื่นไม่โดน; นำ Token ที่ Revoke แล้วมาใช้ซ้ำ → Revoke ทั้ง Family + 401 `refresh_token_revoked`
4. `ENV=production` และไม่มี Email Provider → forgot/reset คืน 503 `password_reset_unavailable` ไม่ Log Link
5. `rider_profiles` ย้ายไป Migration ของ P2b; Rate limit ไป P2c (ตอนนี้ Auth ยังไม่ Rate-limited)
6. Common-password list เป็นรายการเล็ก Hand-curated (`app/core/common_passwords.txt`) — ขยายใน Phase 6

### 3.2 การตัดสินใจใน P2b — **ผู้ใช้ยืนยันแล้ว (ตามคำแนะนำทั้ง 9 ข้อ, 2026-11-09)**
1. `DELETE /me` ต้องส่ง `{"password"}` ใน Body (กัน Access token ที่หลุดลบบัญชีได้) · รหัสผิด → 403 `invalid_password` · ลบแบบ Hard delete + CASCADE ทุกตาราง (รวม Refresh token)
2. `PATCH /me` แก้ได้แค่ `display_name` (เปลี่ยน Email ต้องมีการยืนยัน → ยังไม่ทำ)
3. `GET /me/rider-profile` ถ้ายังไม่เคยบันทึก คืนค่า Default + `is_configured: false` (ไม่ใช่ 404) · `PUT` = แทนที่ทั้งก้อน (ช่องที่ไม่ส่ง → null/Default) · `currency` รับแค่ `THB` · Timezone ผิด → 400 `invalid_timezone`
4. Work session ซ้อนกัน → 409 `work_session_overlap` (Service ตรวจก่อน + DB Exclusion constraint `btree_gist` กัน Race) · ต่อกันพอดี (end = start) ได้ · ยาวได้ ≤ 24 ชม. (เท่ากับ 24 ได้) · เวลาต้องมี Timezone offset (naive → 422) · ช่วงเวลาผิด → 400 `invalid_time_range` / `work_session_too_long`
5. Income/Expense ผูกกับ Session ที่ไม่มีหรือเป็นของคนอื่น → **400** `invalid_work_session` (ตอบเหมือนกันทั้งสองกรณี) — Resource หลักของคนอื่นยังเป็น 404 ตาม §4
6. เงินและตัวเลขทศนิยมใน JSON เป็น **String** (`"800.00"`) กัน Float ปัดเศษ · รับ Input ได้ทั้ง Number และ String (ทศนิยมเกินหลัก → 422)
7. Summary/Trends: สัปดาห์ = ISO จันทร์–อาทิตย์, เดือน = ปฏิทิน, ตาม Timezone ใน Profile (ไม่มี → Asia/Bangkok) · Trends คืนทุก Bucket รวมช่วงว่าง และขยาย `from`/`to` ให้เต็ม Bucket · Default ย้อนหลัง 30 วัน / 12 สัปดาห์ / 12 เดือน · สูงสุด 366 จุด → 400 `range_too_large` · ไม่มีชั่วโมงทำงาน → per-hour = null + `reason: "no_working_hours"`
8. List: Cursor pagination `limit` (Default 50, Max 100) → `{"items", "next_cursor"}` เรียงใหม่สุดก่อน · Filter `from`/`to` (+ `work_session_id` ของ Income, `category` ของ Expense) · `from`/`to` ของ Work session = วันที่ Local ของ `started_at` · `from > to` → 400 `invalid_date_range` · Cursor เสีย → 400 `invalid_cursor`
9. `occurred_on` จำกัด 2000-01-01 ถึง 2100-12-31 · `order_count` ≤ 10,000 · `is_demo` ตั้งจาก Client ไม่ได้ (Field แปลกปลอม → 422)

### 3.3 การตัดสินใจใน P2c — **ผู้ใช้ยืนยันแล้ว (OK ทั้ง 9 ข้อ, 2026-11-09)**
1. **Model serving อยู่ใน Process ของ Backend** (ไม่แยก Service): `rideros-ml` เป็น Path dependency เพราะ Pickle ต้องใช้ Class ของ Package · โหลดตอน Startup ครั้งเดียว · ตรวจ SHA-256 ทุกไฟล์ + Schema + Library versions ก่อน `joblib.load` ไม่ตรง → Startup ล้ม (Fail fast) · `MODEL_DIR` ว่าง → API ขึ้นได้แต่ Prediction คืน 503 `model_unavailable` และ `/ready` ไม่ ready · Predict ใน Threadpool, `n_jobs=1`
2. Prediction คืน **ค่ากลาง + ช่วง Conformal 80%** (low ≥ 0) + `metric: "order_to_pickup_minutes"` + Disclaimer + Warning `foreign_dataset` เสมอ + `limited/insufficient_restaurant_data` ตาม `data_availability` · ทำนายได้เฉพาะร้านจาก Dataset ที่มี `reference_da_id` (ร้านที่ Rider สร้างเอง → 400 `restaurant_not_supported`) · เวลาสั่ง = `requested_at` (Default ตอนนี้) แปลงเป็นเวลา Local ตาม Timezone ใน Profile แล้วส่งให้โมเดล — หมายเหตุ: โมเดลเรียนจากเวลาจีน (UTC+8) จึงตีความแค่ "ชั่วโมงของวันตามเวลาท้องถิ่น"
3. ร้าน: ร้านจาก Dataset (`owner_id IS NULL`, ชื่อ `POI-{poi_id}`) เห็นทุกคน · ร้านที่สร้างเองเห็นเฉพาะเจ้าของ (คนอื่น → 404) · พิกัดแสดงเฉพาะเจ้าของ · ค้นหาชื่อด้วย Trigram · เรียงร้าน Dataset ก่อน
4. Import `restaurant_stats` เข้า DB ตอน Container start ถ้ายังไม่มีร้าน Dataset (`--if-empty`) · Upsert ตาม `(source, external_ref)` → รันซ้ำได้ · ตรวจจำนวนแถวกับ `summary.json` · `dataset_version` เก็บ Hash ของ orders
5. Pickup log: `picked_up_at ≥ arrived_at` และรอ ≤ 3 ชม. · `wait-stats` ใช้เฉพาะ Log ของตัวเอง: Median + P80, `confidence` insufficient (< 5) / low (< 20) / ok — ไม่ผสมกับ Dataset
6. Shift simulator: `start_time`/`end_time` เป็นเวลา Local `HH:MM` (ข้ามเที่ยงคืนได้), ยาว 30–960 นาที · สร้าง/แก้ Input → ประมาณทันที · 3 วิธี: `assumptions` (Default; ค่าน้ำมัน/ค่าเสื่อมเอาจาก Scenario → Profile → ไม่มีก็ไม่คิด + Warning), `historical` (84 วันล่าสุด, วันเดียวกันของสัปดาห์ถ้ามี ≥ 5 วัน ไม่งั้นทุกวัน, ช่วง P20–P80, < 5 วัน → 400 `insufficient_history`), `ml` สงวนไว้ (400 `estimation_method_unavailable`) · Scenario เป็นค่าประมาณเสมอ ไม่นับใน TrueProfit · Compare 2–5 รายการ คืนตัวที่กำไรรวมดีสุด + กำไรต่อชั่วโมงดีสุด
7. Rate limit In-memory ต่อ Process (`limits`, Moving window): register 3/นาที/IP · login 5/นาที ต่อ IP **และ** ต่อ Email · forgot-password 3/นาที ต่อ IP และต่อ Email · reset 3/นาที/IP · อื่นๆ 60/นาที ต่อ User (Token ถูกต้อง) ไม่งั้นต่อ IP · Health ไม่จำกัด · 429 `rate_limited` + `Retry-After` · ยังไม่เชื่อ `X-Forwarded-For` (ต้องตั้งเมื่อมี Reverse proxy ใน Phase 7)
8. `model_versions` Sync จาก Artifact ตอน Startup (Upsert + Active ได้ทีละ 1 ต่อชื่อ) · ทุก Prediction เก็บ `model_version_id` + Input features (Audit)
9. แยก Dependency ของ `ml/` เป็น Runtime / `train` / `dev` และใช้ `xgboost-cpu` บน Linux (Image เล็กลง ~200 MB) — Lock เปลี่ยนแค่ 2 Package (nvidia-nccl ออก, xgboost-cpu เข้า) · `ml/tests` 134 passed หลังแยก

**Exit criteria Phase 2 (ตรวจ 2026-11-09 — ผ่านครบ):** `docker compose up` ได้ DB + API + โมเดลในคำสั่งเดียว ✅ · Coverage `app/modules/**` 99% (≥ 80%) ✅ · Cross-user Tests ผ่านทุก Endpoint ✅ · Auth Tests (Token หมดอายุ/ปลอม/Refresh Reuse/Logout) ✅ · gitleaks no leaks ✅

**Phase 2 Report ส่ง 2026-11-09 → ผู้ใช้อนุมัติ + สั่ง Commit แล้ว (2026-11-09)**

## 4. งานถัดไป — Phase 3 Flutter App (W6–W8) · เริ่มใน Session ใหม่

**ตรวจสถานะจริงก่อนเริ่ม:** `git status` (ต้องสะอาด) · `docker version` (Daemon ต้องรัน) · `flutter --version` (2026-11-09 ติดตั้งแล้ว: Flutter 3.47.0 stable) · `flutter doctor` · มี `ml/artifacts/` อยู่ในเครื่อง (ไม่มีก็ได้ แต่ Prediction จะ 503)

**ผู้ใช้ต้องทำเองก่อน:** ~~`flutter doctor --android-licenses` · เตรียม Android Emulator~~ → **ทำแล้ว 2026-11-10**: Licenses Accept แล้ว (`flutter doctor` Android toolchain ✓) · ติดตั้ง Android Studio + AVD · Emulator `emulator-5554` = sdk gphone64 x86_64, Android 17 (API 37), System image `android-37.0;google_apis_playstore;x86_64`

**Backend สำหรับ Dev:** `docker compose up --build` ที่ Root → API `http://127.0.0.1:8000/api/v1`, Docs `/docs` · Android Emulator เข้าถึงเครื่อง Host ผ่าน `http://10.0.2.2:8000` แต่ Compose bind แค่ `127.0.0.1` (Emulator ผ่าน 10.0.2.2 ได้เพราะเป็น Loopback ของ Host; เครื่องจริงต้องใช้ `adb reverse tcp:8000 tcp:8000`)

**ลำดับงาน (Roadmap):**
- **P3a (W6):** `flutter create` ที่ `mobile/` (`.gitignore` ที่ Root มี Pattern `mobile/` แล้ว) · Design System (Tokens, Light/Dark) · go_router + Auth Guard · dio Client + Interceptor Refresh Token (มี Lock กัน Refresh ซ้ำ) + `AppFailure` แบบ Typed · Splash/Onboarding/Login/Register/Forgot
  → **เสร็จ 2026-11-10 (Commit `56526ee` · §4.1 ยืนยันแล้ว)** — `flutter create --project-name rideros_ai --org com.rideros --platforms android mobile`; Package: flutter_riverpod 3.5, go_router 18.1, dio 5.11, flutter_secure_storage 11.2, freezed 4.0 + json_serializable 6.15, decimal 3.2, intl 0.20 (+ flutter_localizations), dev: build_runner, mocktail
  · โครงสร้าง/วิธีรันดู `mobile/README.md` · หน้าจอ: Splash (Loading/Error+Retry), Login, Register, Forgot (ส่งแล้ว + DEV ONLY note), Reset (วางลิงก์หรือ Token), Onboarding (Rider profile), Home (ชั่วคราว: ทักทาย + Logout จนกว่า P3b)
  · Tests **135 passed** (`flutter test`, ~12 s): unit 82 (failure mapper, validators, token manager single-flight, interceptor refresh/retry/concurrency/no-loop, repository ผ่าน Fake HTTP adapter, session controller, router guard table) + widget/navigation 53 (ทุก Form validation + states, ทั้งแอปผ่าน Router จริง, Full-stack ผ่าน dio จริง) · Coverage `lib/` (ไม่รวม generated) **95.6%** · `flutter analyze` → No issues · `dart format` สะอาด
  · `flutter build apk --debug` ผ่าน (~191 s; Manifest + Network security config ของ Debug ถูกต้อง)
  · **รันบน Emulator แล้ว 2026-11-10**: `docker compose up -d` (`/ready` → database ok, model ok `pickup_o2p/1.0.0`) + `flutter run -d emulator-5554` → Splash → หน้า Login แสดงถูกต้อง (ธีม Light, ภาษาไทย) · ผู้ใช้ลองใช้เองบน Emulator (ยังไม่ได้รับ Feedback เรื่อง UI)
  · ~~gitleaks~~ ทำแล้วก่อน Commit `549c27b` (§4.5) · ยังไม่ได้ทำ: Deep link `rideros://reset-password` (เลื่อนไป Phase 4 เพราะต้องทดสอบบน Emulator)
- **P3b (W7):** Home Dashboard · TrueProfit Dashboard · Income/Expense Management (Forms + Validation + States)
  → **เสร็จ 2026-11-10 (Commit `56526ee` · §4.3 ยืนยันแล้ว)** — เพิ่ม `fl_chart ^1.3.1` · Bottom navigation (`StatefulShellRoute.indexedStack`: หน้าหลัก + กำไร) · Feature ใหม่ `lib/features/profit/` (domain: `profit_records.dart`, `profit_summary.dart`, `profit_period.dart`, `session_times.dart`, `profit_repositories.dart` · data: `ApiRecordRepository<T, I>` generic + `ProfitRepositoryImpl` · presentation: `profit_providers.dart`, `true_profit_screen.dart`, `records_screen.dart`, ฟอร์ม income/expense/work-session, widgets) · `app/routes.dart` (แยก Routes ออกจาก router; `router.dart` export ต่อ) · `app/app_shell.dart` · Home ใหม่ (`features/dashboard/presentation/home_screen.dart`) · core: `utils/date_json.dart`, `utils/formatters.dart`, `utils/clock.dart`, `network/paged_result.dart`, Validators เพิ่ม `requiredDecimal`/`optionalInt`/`optionalText`/`max`
  · หน้าจอ: Home (วันนี้ + สัปดาห์นี้ + บันทึกด่วน), TrueProfit (วัน/สัปดาห์/เดือน, ย้อน/ถัดไป, สรุปละเอียด, กราฟแท่งกำไรสุทธิ), รายการทั้งหมด (3 แท็บ รายได้/ค่าใช้จ่าย/ช่วงทำงาน, Cursor pagination + โหลดเพิ่ม, Pull-to-refresh, DEMO chip), ฟอร์มเพิ่ม/แก้/ลบ 3 แบบ (ยืนยันก่อนลบ)
  · Tests **255 passed** (`flutter test`, ~15 s; เดิม 135 + ใหม่ 120: unit formatters/dates/models/validators/repository ผ่าน Fake HTTP/notifiers + widget ทุกหน้าและทุก Form + navigation รวม Full-stack `/profit/summary`) · Coverage `lib/` **96.2%** · `flutter analyze` No issues · `dart format` สะอาด
  · **ทดสอบบน Emulator กับ API จริง 2026-11-10**: Login → Home/TrueProfit แสดงตัวเลขตรง `/profit/summary` · แก้รายได้ 780→800 ผ่านแอป → DB = 800.00 และ Link ช่วงทำงานยังอยู่ · Dev DB มีบัญชีทดสอบ `p3b.check@example.com` (รหัส `p3b check pass`; ชื่อแสดงเป็น `????? P3b` เพราะ curl บน Windows แปลงอักษรไทยตอน Seed — ไม่ใช่บั๊กแอป)
- **P3c (W8):** Pickup Intelligence + Restaurant Details · Shift Simulator + Scenario Comparison · Profile/Settings
  → ผู้ใช้กำหนดลำดับ: (a) Profile → (b) Pickup Intelligence → (c) Shift Simulator
  → **(a) Profile เสร็จ 2026-11-11 (Commit `549c27b`)** — รายละเอียด + การตัดสินใจ §4.5
  → **(b) Pickup Intelligence เสร็จ 2026-11-11 (Commit `f76d050`)** — รายละเอียด + การตัดสินใจ §4.6
  → **(c) Shift Simulator เสร็จ 2026-11-11 (Commit `aed472f`)** — รายละเอียด + การตัดสินใจ §4.7 · **P3c ครบแล้ว เหลือ Phase 3 Report**

**Stack ที่กำหนดแล้ว (SYSTEM_ARCHITECTURE §2.1):** Feature-first + Clean Architecture (`data/` → `domain/` → `presentation/`) · Riverpod (Notifier/AsyncNotifier) · go_router · dio · freezed + json_serializable · flutter_secure_storage (Refresh Token) · fl_chart · flutter_map · geolocator

**สิ่งที่ App ต้องทำตาม Backend contract (`backend/README.md`):**
- Error body `{"error": {"code", "message", "details"}}` → Map `code` เป็น `AppFailure`; 429 `rate_limited` อ่าน `Retry-After`
- `register` ไม่คืน Token → Login ต่อ · Access 15 นาที, Refresh 30 วัน (Rotation; Token ที่ใช้แล้ว Reuse → ทั้ง Session ถูก Revoke → ต้องพา User ไป Login)
- เงิน/ทศนิยมเป็น **String** (`"800.00"`) → ใช้ Decimal ห้าม `double` · เวลาส่งแบบมี Offset (Aware) · List ใช้ `next_cursor`
- `DELETE /me` ต้องส่ง Password · `GET /me/rider-profile` คืน `is_configured: false` ถ้ายังไม่ตั้ง → ใช้พา Onboarding
- **Pickup:** แสดงเป็น **ช่วง** (`interval.low`–`interval.high`) ไม่แสดงตัวเลขเดี่ยว · Label **"Order-to-Pickup"** เสมอ (ห้ามเรียกเวลารอ Rider / เวลาทำอาหาร) · แสดง `warnings` (`foreign_dataset` = "ค่าประมาณจากข้อมูลต่างประเทศ") และ `disclaimer` · หน้า Model Info ต้องแสดง Acknowledgement *This research was supported by data provided by Meituan.* · ร้านที่ User สร้างเองทำนายไม่ได้ (400 `restaurant_not_supported`) → ซ่อนปุ่มทำนาย
- **Shift:** Scenario เป็นค่าประมาณเสมอ (`is_estimate`) · วิธี `ml` ยังไม่เปิด → **ซ่อน** ใน UI (Exit criteria: ห้ามมีปุ่มที่ไม่ทำงาน)
- ไม่มี RoadContext ใน Phase 3 (Phase 5)

### 4.1 การตัดสินใจใน P3a — **ผู้ใช้ยืนยันแล้ว (OK ทั้ง 13 ข้อ, 2026-11-10; ข้อ 10 = Commit ไฟล์ Generated · ไม่มี Feedback UI)**
1. `applicationId` = `com.rideros.rideros_ai`, สร้างเฉพาะ Platform `android` · ชื่อแอป "RiderOS AI"
2. UI ภาษาไทยอย่างเดียว ผ่าน gen-l10n (`lib/l10n/app_th.arb`) · Locale `th` คงที่ · เพิ่มภาษาอื่นภายหลังได้ด้วย ARB ใหม่
3. Onboarding = ตั้งค่า Rider profile หลัง Login ครั้งแรก (`is_configured: false`) · ทุกช่องไม่บังคับ · "ข้ามไปก่อน" = `PUT` ค่า Default → ไม่ถามซ้ำ · ไม่มีหน้า Intro/Carousel · Timezone `Asia/Bangkok` + THB แสดงเป็นข้อมูล (แก้ใน Profile P3c)
4. Register สำเร็จ → Login ต่ออัตโนมัติ · ถ้า Login ต่อไม่ผ่าน (เช่น 429) → หน้า Login พร้อมข้อความ "สมัครสำเร็จ"
5. Reset password: ยังไม่ทำ Deep link · หน้า Reset รับ "ลิงก์ทั้งเส้น" หรือ Token (Flow D5 อ่านลิงก์จาก Log) · Deep link `rideros://reset-password` เลื่อนไป Phase 4 (ทดสอบบน Emulator)
6. Access token อยู่ใน Memory เท่านั้น · Refresh token ใน `flutter_secure_storage` · `android:allowBackup="false"` · Logout ตอน Offline ลบ Token ในเครื่องเสมอ
7. Refresh ถูกปฏิเสธ (401/422) → ลบ Token + กลับหน้า Login พร้อม "เซสชันหมดอายุ" · Network/5xx ระหว่าง Refresh → แจ้ง Error ไม่ Logout · เปิดแอปตอน Offline → Splash แสดง Error + ลองใหม่ (เก็บ Token ไว้)
8. ปิด Automatic retry ของ Riverpod 3 ทั้งแอป (Error แสดงทันทีพร้อมปุ่มลองใหม่)
9. Riverpod แบบเขียน Provider เอง (ไม่ใช้ riverpod_generator) · Model ใช้ freezed + fromJson ตรงใน `domain/` (ไม่แยก DTO ถ้า Shape เหมือนกัน)
10. **Commit ไฟล์ Generated** (`*.g.dart`, `*.freezed.dart`, `lib/l10n/app_localizations*.dart`) เพื่อให้ Clone แล้ว `flutter analyze`/`test` ได้ทันที — ทางเลือก: gitignore แล้วให้ CI รัน `build_runner`
11. HTTP ธรรมดาได้เฉพาะ Debug build ไปที่ `10.0.2.2`/`127.0.0.1`/`localhost` · Release ต้อง `https` (ตรวจใน `AppConfig`) · ไม่มี Request/Response logging (กัน Password/Token หลุดลง Log)
12. Validation ฝั่ง App ตรงกับ Backend (Email ≤ 254, Password 8–128 และไม่เท่าชื่อหน้า @, Display name ≤ 80, ทศนิยมตาม NUMERIC ของคอลัมน์) · ตรวจรหัสผ่านที่พบบ่อยที่ Server อย่างเดียว
13. Home เป็นหน้าชั่วคราว (ทักทาย + Logout) จนกว่า P3b · ข้อความ DEV ONLY ในหน้า Forgot แสดงเฉพาะ Build ที่ไม่ใช่ Release

### 4.3 การตัดสินใจใน P3b — **ผู้ใช้ยืนยันแล้ว (ตามคำแนะนำทั้ง 11 ข้อ, 2026-11-10)**
1. Bottom navigation แสดงเฉพาะ Feature ที่เสร็จ: ตอนนี้ "หน้าหลัก" + "กำไร" · P3c เพิ่ม Pickup / Shift / Profile · ปุ่ม Logout อยู่ที่ AppBar ของ Home ชั่วคราวจนมีหน้า Profile
2. **ทำหน้าจัดการ "ช่วงทำงาน" (Work sessions) ใน P3b ด้วย** (นอก Roadmap เดิม) เพราะเป็นแหล่งชั่วโมงทำงาน (กำไร/ชม.) และ Shift `historical` ใน P3c ต้องใช้
3. รายได้ผูกกับช่วงทำงานที่ "เริ่มในวันเดียวกัน" ได้ · ผูกแล้วซ่อนช่องชั่วโมงและส่ง `working_hours: null` (Backend ไม่นับอยู่แล้ว กันชั่วโมงซ้ำ) · ฟอร์มค่าใช้จ่ายไม่มีการผูก (ไม่ส่ง `work_session_id` → Link เดิมไม่หาย)
4. ช่วงทำงานกรอกเป็น วันที่เริ่ม + เวลาเริ่ม + เวลาเลิก (24 ชม.) · เวลาเลิก ≤ เวลาเริ่ม = วันถัดไป · เวลาเท่ากัน = Error (ไม่เดาว่า 0 หรือ 24 ชม.) · ส่งเวลาพร้อม Offset ของเครื่อง และแสดงตามเวลาเครื่อง
5. Date picker เลือกได้ 2000-01-01 ถึง "วันนี้" ของเครื่อง (ไม่ให้บันทึกอนาคต; Backend รับถึง 2100) · ถ้าข้อมูลเดิมเป็นวันอนาคตยังเปิดแก้ได้
6. ไม่มีการคำนวณเงินฝั่งแอป: ตัวเลขสรุปทั้งหมดมาจาก Server · หลังบันทึก/ลบทุกครั้ง Reload ทุกรายการและสรุป (`profitDataRevisionProvider`) · แสดงเงินจาก Decimal (ไม่ผ่าน `double`) · กราฟแปลงเป็น `double` เฉพาะความสูงแท่ง
7. TrueProfit: ช่วงปัจจุบันให้ Server ตัดสิน "วันนี้" ตามเขตเวลาของ Rider · ปุ่ม "ถัดไป" ซ่อนที่ช่วงปัจจุบัน · การกลับมาช่วงปัจจุบันใช้วันที่ของเครื่อง · กราฟใช้หน้าต่าง Default ของ Backend (30 วัน / 12 สัปดาห์ / 12 เดือน) ที่จบที่ช่วงที่แสดง
8. รายการ (List) แสดงจำนวนเงินไม่มีสัญลักษณ์สกุลเงิน (API ของรายการไม่มี currency) · หน้าสรุปใช้ `currency` จาก API (THB → ฿)
9. แก้ไขใช้ `PATCH` ส่งทุกช่องในฟอร์ม (ช่องว่าง = `null` = ล้างค่า) · จำนวนเงิน 0 ได้ (ตาม Backend `ge=0`) · ลบจริง (Hard delete) หลังยืนยัน
10. รายการเรียงใหม่→เก่า, โหลดหน้าถัดไปอัตโนมัติเมื่อเลื่อนใกล้ท้าย + ปุ่ม "โหลดเพิ่ม" · ยังไม่มีตัวกรอง/ค้นหา
11. Record ที่ `is_demo: true` แสดงป้าย "DEMO" ในรายการ (DoD)

### 4.4 ปรับ UI ตาม `docs/RIDEROS_UI_DESIGN.md` (Rider Green) — **เสร็จ 2026-11-10 (Commit `56526ee` · ผู้ใช้สั่งให้แก้ตามเอกสาร)**
- ขอบเขต: เฉพาะหน้าจอที่มีแล้ว (P3a + P3b) · หน้า Pickup / Shift / Profile ยังไม่ทำ (รอยืนยัน §4.3 ก่อน P3c) แต่ Component พร้อมใช้แล้ว
- Tokens (`app/theme/tokens.dart`): `AppColors` ครบทั้ง Light/Dark ตาม §2.2–2.3 · `AppTypography` (Display 32 … Caption 12) · Spacing เพิ่ม 20 (`card`) · Radius input 12 / button 14 / card 16 / dialog 20 · `AppSemanticColors` เพิ่ม mint, border, hero (การ์ดเขียวเข้ม)
- ฟอนต์ **IBM Plex Sans Thai** (Regular/Medium/SemiBold/Bold) bundle ใน `mobile/assets/fonts/` + `OFL.txt` (SIL OFL 1.1 → Commit ได้) · ตัวเลขกว้างเท่ากันอยู่แล้ว
- Theme (`app/theme/app_theme.dart`): ColorScheme กำหนดเองทั้งหมด (ไม่ใช้ `fromSeed`) · AppBar สี Rider Green (Light) · NavigationBar active = Mint + Brand · Card ขอบบาง + เงาอ่อน · Input ขาว ขอบ 12 · Dialog 20
- **เบี่ยงจากเอกสาร (Contrast, §2.3 สั่งให้ตรวจ):** ตัวอักษรขาวบน `#00A884` = ~3.0:1 (ต่ำกว่า 4.5:1) → ปุ่มหลักใช้ Brand `#00796B` (~5.4:1) ใน Light และ `#55C7A5` + ตัวอักษรเข้ม (~8.5:1) ใน Dark · `#00A884` ใช้กับ Progress indicator · ขอบ Input ใช้ `#84968D`/`#5E7A6C` (≥3:1, WCAG 1.4.11) เพราะ Border `#DCE8E1` จางเกินสำหรับขอบช่องกรอก
- Components ใหม่: `LabeledField` (Label เหนือช่อง + ผูก Label ให้ Screen reader), `AppBadge` (DEMO/ค่าประมาณ/Dataset/neutral), `app_cards.dart` (`SectionHeader`, `SectionCard` ย้ายมาจาก profit, `MetricTile`, `MetricTileRow`), `SkeletonBox`/`SummarySkeleton`, `AppDestructiveButton`, `AppLogoMark` · `AsyncValueView` รับ `loading:` ได้
- หน้าจอ: Splash พื้น Forest Green + Loading ด้านล่าง · Login = Header สีเขียวเข้ม (โลโก้ + ชื่อแอป + Tagline) ด้านบน + ฟอร์มในการ์ดขาวซ้อนขึ้นมา (ทำใหม่หลังผู้ใช้ทักว่า Login ยังไม่เปลี่ยน) · Register / Forgot (ทั้งฟอร์มและหน้าส่งแล้ว) / Reset ใช้ `AuthLayout` เดียวกัน (`core/widgets/auth_layout.dart`: Header + ปุ่มย้อนกลับเมื่อ pop ได้ + การ์ดฟอร์ม) แทน AppBar · ฟอร์มทั้งหมด Label เหนือช่อง · Home = การ์ด "วันนี้" สีเขียวเข้ม (กำไรสุทธิ 32) + การ์ดสัปดาห์ + บันทึกด่วน 3 ช่อง · TrueProfit แถบช่วงเวลาเป็นการ์ด + ปุ่มใหม่ "กลับช่วงปัจจุบัน" (`profit.current`) + หมายเหตุเป็น Banner · Records = ไอคอนวงกลม Mint + ป้าย DEMO + chevron · Dialog ลบ ปุ่มแดง · Skeleton แทน Spinner ที่ Home/TrueProfit
- ข้อความปรับตามเอกสาร: `เชื่อมต่อไม่สำเร็จ`, `ส่งลิงก์รีเซ็ตรหัสผ่าน`, `มีลิงก์/รหัสแล้ว`, `ตั้งรหัสผ่านใหม่`, `ถ้ามีบัญชีนี้ เราได้ส่งลิงก์ไปแล้ว…`, Onboarding "ใช้ข้อมูลนี้คำนวณต้นทุนต่อกิโลเมตร…", `สกุลเงิน THB`
- ไม่ได้ทำ: ภาพประกอบไรเดอร์ใน Splash (ไม่มี Asset ที่มีสิทธิ์ใช้ → ใช้โลโก้ไอคอนแทน)
- ผล: `flutter analyze` No issues · `flutter test` **261 passed** (+6: ปุ่มย้อนกลับของ AuthHeader, skeleton, label semantics, badges/ปุ่มลบ Light+Dark, theme tokens, กลับช่วงปัจจุบัน) · ตรวจบน Emulator กับ API จริง: Login, Register, Home, TrueProfit, Records, ฟอร์มรายได้, Home ใน Dark mode
- หลังตรวจบน Emulator แก้แล้ว: Status bar หน้า Login (ไอคอนขาวบนพื้นขาว) · ข้อความใน Dropdown ใหญ่กว่าช่องอื่น (ยังไม่ได้ Screenshot ซ้ำหลังแก้ Dropdown; Tests ผ่าน)

### 4.5 P3c กลุ่ม (a) Profile — **เสร็จ 2026-11-11 (Commit `549c27b` · ผู้ใช้สั่ง Commit หลังรับรายงาน ไม่ขอแก้การตัดสินใจ)**
- แท็บที่ 3 "โปรไฟล์" (`Routes.profile`) · ลำดับแท็บสุดท้ายตาม UI_STRUCTURE: หน้าหลัก · Pickup · กำไร · กะงาน · โปรไฟล์ → (b)/(c) ต้องแทรก Branch ใน `app/router.dart` + Destination ใน `app/app_shell.dart` ให้ตรงลำดับนี้
- ไฟล์ใหม่ `lib/features/profile/presentation/`: `profile_screen.dart` (S-PROFILE: การ์ดหัวสี hero ชื่อ/อีเมล/สมัครเมื่อ · บัญชี · รถและต้นทุน · ภูมิภาค · ข้อมูล · ปุ่มออกจากระบบ · ลิงก์ลบบัญชีสีแดง · Pull-to-refresh), `display_name_screen.dart` (`PATCH /me`), `rider_profile_form_screen.dart` (S-RIDER-PROFILE-FORM, `PUT /me/rider-profile` ส่งครบทุกช่อง), `rider_profile_fields.dart` (`RiderProfileControllers` + `RiderProfileFields` ใช้ร่วมกับ Onboarding), `delete_account_screen.dart` (S-ACCOUNT-DELETE), `about_screen.dart` (เกี่ยวกับแอป + ข้อมูล Meituan/CC BY-NC 4.0 + Acknowledgement + หน้า License), `profile_providers.dart`
- Routes ใหม่ (root navigator): `/profile/display-name`, `/profile/rider`, `/profile/delete-account`, `/profile/about`
- Auth: `AuthRepository.updateDisplayName` / `deleteAccount` (ลบ Token หลังสำเร็จ) · `SessionController.updateDisplayName` / `deleteAccount` → `SignedOut(SignOutReason.accountDeleted)` → หน้า Login แสดง "ลบบัญชีและข้อมูลทั้งหมดแล้ว" · `ApiErrorCode.invalidPassword` → "รหัสผ่านไม่ถูกต้อง"
- Core: ย้าย `features/profit/presentation/widgets/record_form_widgets.dart` → `core/widgets/form_widgets.dart` (`confirmDelete` รับ title/message/confirmLabel ได้) · `TileGroup` (app_cards) · `ListSkeleton` (status_views) · `AppDestructiveButton(isLoading)` · `FormLayout` ชิดบน (เดิม Center → ฟอร์มสั้นลอยกลางจอ) · `main.dart` ลงทะเบียน License ฟอนต์ (`assets/fonts/OFL.txt` อยู่ใน pubspec assets)
- **บั๊กที่แก้ (เจอบน Emulator):** `refreshListenable` ของ Router ยิงทุกครั้งที่ Session เปลี่ยน (เช่นแก้ชื่อ) → go_router ตั้ง Location ใหม่ทับ `context.pop()` → ฟอร์มไม่ปิด · แก้ด้วย `_GuardRefresh` ใน `app/router.dart` ที่แจ้งเฉพาะเมื่อ `_guardKey` (restoring / restore_failed / signed_out / signed_in+profileConfigured) เปลี่ยน · มี Regression test ใน `navigation_test.dart` (ยืนยันแล้วว่า Fail กับโค้ดเดิม)
- การตัดสินใจ: (1) Timezone เป็นช่องพิมพ์ชื่อ IANA (บังคับ ≤ 64 ตัว) Server ตรวจ → 400 `invalid_timezone` แสดงเป็น Banner (2) Currency แสดงอย่างเดียว ส่งค่าเดิมกลับ (3) Logout ไม่มี Dialog ยืนยัน (4) ลบบัญชี: ใส่รหัส → Dialog ยืนยัน → Error เป็น Banner (5) Email แก้ไม่ได้ (Backend ไม่มี Endpoint) (6) ปุ่ม Logout ออกจาก Home แล้ว
- gitleaks (Docker `zricethezav/gitleaks:v8.30.0`, `dir` สำเนาไฟล์ที่จะ Commit + `git`): เจอ 3 จุดเป็น Token ปลอมของ Reset password ใน Test (Commit `56526ee`) → ใส่ `// gitleaks:allow` ในไฟล์ปัจจุบัน + `.gitleaksignore` (Fingerprint ของ History) → no leaks found ทั้งสองแบบ
- ผล: `dart format` สะอาด · `flutter analyze` No issues · `flutter test` **296 passed** (+35: `test/widget/profile_screens_test.dart` 25 + navigation (Logout ผ่านโปรไฟล์, ฟอร์มโปรไฟล์ไรเดอร์, ลบบัญชี, Regression แก้ชื่อ) + unit `auth_repository_impl_test`/`session_controller_test` กลุ่ม 'account')
- **ตรวจบน Emulator กับ API จริง:** แท็บ 3 อัน, Home ไม่มี Logout · แก้ชื่อ → DB `users.display_name` = "Rider Check" และฟอร์มปิดกลับหน้าโปรไฟล์ · Timezone `Mars/Base` → Banner "เขตเวลาไม่ถูกต้อง" · ค่าเสื่อม 0.25 → DB `motorcycle|45.00|38.50|0.2500|Asia/Bangkok` + การ์ดอัปเดต · About แสดง Acknowledgement + License IBM Plex Sans Thai · Logout ได้ · ลบบัญชีด้วยบัญชีทิ้ง `p3c.delete@example.com`: รหัสผิด → "รหัสผ่านไม่ถูกต้อง", รหัสถูก → Login + แบนเนอร์, DB เหลือ 0 แถว · Onboarding หลัง Refactor แสดงเหมือนเดิม
- ไม่ได้ตรวจ: หน้าโปรไฟล์ใน Dark mode บน Emulator (Tests ผ่าน)

### 4.6 P3c กลุ่ม (b) Pickup Intelligence — **เสร็จ 2026-11-11 (Commit `f76d050` ตามที่ผู้ใช้สั่ง · การตัดสินใจด้านล่างผู้ใช้ยืนยันตามที่เสนอพร้อมอนุมัติ Phase 3, 2026-11-11)**
- แท็บที่ 2 "Pickup" (`Routes.pickup`) → แท็บตอนนี้: หน้าหลัก · Pickup · กำไร · โปรไฟล์ ((c) ต้องแทรก "กะงาน" ก่อนโปรไฟล์ ใน `app/router.dart` + `app/app_shell.dart`)
- Feature ใหม่ `lib/features/pickup/`: domain `pickup_models.dart` (freezed: Restaurant, RestaurantInput, StatCell, OverallStats, RestaurantAnalytics, WaitStats, PredictionInterval, Prediction, ModelInfo, PickupLog, PickupLogInput + `PickupLimits`, `PredictionWarning`), `pickup_repository.dart`, `pickup_times.dart` (`pickupTimes`, `isWaitTooLong`) · data `pickup_repository_impl.dart` · presentation `pickup_providers.dart` (`pickupDataRevisionProvider`, `restaurantListProvider(RestaurantQuery)`, `restaurantAnalyticsProvider`, `waitStatsProvider`, `predictionProvider`, `modelInfoProvider`, `predictionHistoryProvider`, `pickupLogListProvider`, `PickupFormController`), `pickup_labels.dart`, จอ `pickup_search_screen.dart` (S-PICKUP-SEARCH + โหมด Picker ผ่าน `onSelect`), `restaurant_screen.dart`, `prediction_result_screen.dart`, `prediction_history_screen.dart`, `pickup_logs_screen.dart`, `pickup_log_form_screen.dart`, `own_restaurant_form_screen.dart`, `model_info_screen.dart`, `widgets/hourly_heatmap.dart`
- Routes: ในแท็บ `/pickup/restaurants/:id`, `/pickup/restaurants/:id/prediction`, `/pickup/predictions`, `/pickup/logs` · root navigator `/pickup/logs/new?restaurant_id=&restaurant_name=`, `/pickup/own-restaurant`, `/pickup/select-restaurant`, `/pickup/model` · โปรไฟล์มี Tile "ข้อมูลโมเดล Pickup" (`profile.modelInfo`)
- Core: ย้าย `PagedState`/`PagedListNotifier` → `core/presentation/paged_list.dart` (มี Hook `watchDependencies()`; profit ใช้ `ProfitPagedListNotifier` และ `profit_providers.dart` export ต่อ) · `_PagedList` ของ records → `core/widgets/paged_list_view.dart` (`PagedListView` + `header`/`loading`/`keyPrefix`, `RoundIcon`) · `Formats.count` (คั่นหลักพัน) · Error code ใหม่ `model_unavailable`, `restaurant_not_supported`, `invalid_pickup_times`, `pickup_wait_too_long`
- การตัดสินใจ (ผู้ใช้ยังไม่ได้ยืนยันทีละข้อ): (1) รายละเอียดร้าน/ผลทำนาย/ประวัติ/บันทึกอยู่ในแท็บ (เห็น Bottom nav) · ฟอร์ม/Picker/การ์ดโมเดลบน root (การ์ดโมเดลเปิดจากโปรไฟล์ได้) (2) เปิดหน้าผลทำนาย = `POST /pickup/predictions` 1 ครั้ง (เวลาสั่ง = ตอนนี้ ให้ Server ตีความตาม Timezone) · "ทำนายอีกครั้ง"/ลองใหม่ = ขอใหม่ · ประวัติแตะไม่ได้ (API ไม่มี GET ทีละรายการ) (3) ช่วงแสดงเป็นนาทีเต็ม ปัด low ลง high ขึ้น (ช่วงไม่แคบกว่าที่โมเดลให้) · ค่ากลาง/สถิติ ทศนิยม 1 ตำแหน่ง (4) Disclaimer: ข้อความไทยของแอป + ข้อความ Server (อังกฤษ) ตามจริง · ข้อจำกัดในการ์ดโมเดล: สรุปไทย + รายการ Server (อังกฤษ) ใน Expander · Acknowledgement ใช้ข้อความคงที่ของแอป (5) Heatmap: สีเดียว 5 ระดับ (mint→primary) เทียบช่วงของร้านนั้นเอง · ชั่วโมงไม่มีข้อมูลเว้นว่าง · Tooltip + Semantics ทุกช่อง · เลือกสีตัวอักษรให้ ≥ 4.5:1 ทั้ง Light/Dark (คำนวณแล้ว) · ระบุว่าชั่วโมงเป็นเวลาท้องถิ่นของเมืองในข้อมูล (6) ฟอร์มบันทึกเวลารับ: วันที่ถึงร้าน (≤ วันนี้) + เวลาถึง + เวลารับ · เวลารับก่อนเวลาถึง = วันถัดไป · เท่ากัน = รอ 0 นาที · รอ > 3 ชม. แจ้งใต้ช่องและไม่ส่ง · ค่าเริ่ม = 10 นาทีก่อน → ตอนนี้ (7) ร้านของฉัน: lat/lng ใส่ทั้งคู่หรือไม่ใส่ · บันทึกแล้วกลับหน้าก่อน (รายการโหลดใหม่ ร้านของฉันขึ้นก่อนตาม API) · ไม่มีแก้/ลบร้าน และแก้ Log ไม่ได้ (API ไม่มี) (8) ค้นหา Debounce 350 ms, ตัดช่องว่าง, ≤ 120 ตัว · ตัวกรองเป็น SegmentedButton · ทางเข้า 3 อันเป็น Chip แนวนอน · FAB "เพิ่มร้านของฉัน" (9) ลบ Log ด้วยไอคอนถังขยะ + Dialog ยืนยัน → Snackbar
- ผล: `dart format` สะอาด · `flutter analyze` No issues · `flutter test` **367 passed** (+71: `test/unit/features/pickup_test.dart` 21, `test/widget/pickup_screens_test.dart` 46, navigation +4) · gitleaks `dir` (344 ไฟล์) + `git` → no leaks found · Coverage `lib/` (ไม่รวม generated/l10n) **97.1%**, `features/pickup` **98.5%**
- **ตรวจบน Emulator กับ API จริง:** แท็บ Pickup + รายการร้าน · POI-1: สถิติ (มัธยฐาน 10.4, P25–P75 7.9–14, 1,267 ออเดอร์, ชั่วโมงพีค 12:00) + Heatmap วันธรรมดา (00–07 ว่าง) · ทำนาย → **4–20 นาที** ค่ากลาง ~11 · Coverage 80% · คำเตือนข้อมูลต่างประเทศ · Disclaimer · โมเดล 1.0.0 · บันทึกเวลารับจากหน้าผล → DB `pickup_logs` POI-1 12:03Z→12:13Z (19:03→19:13 +07) · ประวัติแสดงรายการ · FAB บันทึก → ไม่เลือกร้าน → Picker → เพิ่มร้าน "Test Kitchen" (lat/lng) → DB `POINT(100.5018 13.7563)` → ร้านของฉันขึ้นก่อน → เลือก → บันทึก → รายการอัปเดต · ลบ Log (ยืนยัน) · ร้านของฉัน: ไม่มีปุ่มทำนาย + แสดงตำแหน่ง · การ์ดโมเดล (เปิดจากโปรไฟล์): MAE 4.51 vs 4.64, 64,701 ออเดอร์, 80% vs 81.6%, ช่วงกว้าง 14.9, CC BY-NC 4.0 + Acknowledgement · Dark mode หน้าร้าน + Heatmap
- แก้หลังรายงาน: ลบ Log แล้วออกจากหน้ารายการก่อนคำขอเสร็จ → เดิม `ref` ถูกใช้หลัง Dispose (Exception + รายงานว่าลบไม่สำเร็จทั้งที่ลบแล้ว) · ตอนนี้ `PickupFormController` อ่าน Repository + Revision ก่อน await และหน้ารายการเช็ก `context.mounted` (มี Test ทั้ง Unit + Widget) · `profit_providers.dart` ยังใช้รูปแบบเดิม (bump หลัง await) แต่ฟอร์มกำไรเป็นหน้าเต็ม ไม่ได้แก้ในกลุ่มนี้
- แก้หลังดูบน Emulator: ข้อความ Dialog ลบ Log เดิมพูดถึงกำไร → `logsDeleteMessage` · จำนวนออเดอร์ไม่มีคั่นหลักพัน → `Formats.count` · Skeleton 5 แถวล้นจอเตี้ย → ห่อ `SingleChildScrollView`
- Dev DB ตอนนี้มี: Log POI-1 1 รายการ, ร้าน "Test Kitchen" (ของ `p3b.check@example.com`), Prediction 2 รายการ
- ไม่ได้ตรวจ: Error 503 บน Emulator จริง (มี Widget test) · หน้าผลทำนาย/ฟอร์มใน Dark mode (Tests ผ่าน)

### 4.7 P3c กลุ่ม (c) Shift Simulator — **เสร็จ 2026-11-11 (Commit `aed472f` ตามที่ผู้ใช้สั่ง · การตัดสินใจด้านล่างผู้ใช้ยืนยันตามที่เสนอพร้อมอนุมัติ Phase 3, 2026-11-11)**
- Session ที่สร้างงานนี้หลุดกลางทาง (API safeguard ขึ้น `[reasoning_extraction]` ซึ่งเป็น False positive) · Session ถัดมาทำต่อจากไฟล์บนดิสก์จนเสร็จ
- แท็บที่ 4 "กะงาน" (`Routes.shifts`) → แท็บครบ 5 อันตาม UI_STRUCTURE: หน้าหลัก · Pickup · กำไร · กะงาน · โปรไฟล์
- Feature ใหม่ `lib/features/shifts/`: domain `shift_models.dart` (freezed: ShiftScenario, ShiftScenarioInput, ShiftAssumptions, ShiftEstimateDetails, ShiftComparison + `ClockTime`, `ShiftLimits`, `EstimationMethod {assumption, historical, ml}`), `shift_repository.dart` · data `shift_repository_impl.dart` (`/shift-scenarios`) · presentation `shifts_screen.dart` (S-SHIFTS + `_CompareBar`), `shift_form_screen.dart` (S-SHIFT-FORM), `shift_detail_screen.dart` (S-SHIFT-DETAIL), `shift_compare_screen.dart` (S-SHIFT-COMPARE), `work_session_picker_screen.dart`, `shift_providers.dart` (`shiftSelectionProvider`, `shiftListProvider`, `workedHistoryDaysProvider`, `shiftFormProvider` ฯลฯ), `shift_labels.dart`
- Routes: ในแท็บ `/shifts/scenarios/:id`, `/shifts/compare?ids=` · root navigator `/shifts/new`, `/shifts/edit/:id`, `/shifts/select-session`
- Core: Error code ใหม่ `invalid_shift_length`, `missing_assumption`, `insufficient_history`, `estimation_method_unavailable` (+ `shift_scenario_not_found` → not found) · `AppSecondaryButton(isLoading)` · `AsyncValue.keepingData` (`status_views.dart`: Reload แล้วยังแสดงข้อมูลเดิม ไม่กระพริบเป็น Skeleton) · `ProfitRepository.trends(from:)`
- การตัดสินใจ (ผู้ใช้ยังไม่ได้ยืนยันทีละข้อ): (1) รายการ/รายละเอียด/เปรียบเทียบอยู่ในแท็บ · ฟอร์ม + Picker ช่วงทำงานบน root (2) วิธี `ml` ไม่มีให้เลือก (Label "วิธีที่ยังไม่เปิดใช้" ถ้า Server ส่งมา) · `historical` เลือกได้เมื่อมีวันที่มีชั่วโมงทำงาน ≥ 5 วันใน 84 วันล่าสุด (นับจาก `/profit/trends` รายวัน) ฟอร์มบอกจำนวนวันที่มีตอนนี้ · ถ้านับไม่ได้ (Error) ให้เลือกได้และ Server ตรวจอีกครั้ง · `historical` ซ่อนช่องสมมติฐาน ส่งเฉพาะค่าใช้จ่ายคงที่ (3) ทุกตัวเลขมีป้าย "ค่าประมาณ" + Banner "ไม่นับรวมใน TrueProfit" (4) เลือก 2–5 รายการเพื่อเปรียบเทียบ (แถบล่าง: จำนวน + ล้างที่เลือก + เปรียบเทียบ) · ลบ Scenario ที่เลือกอยู่ → หลุดจากที่เลือก · หน้าเปรียบเทียบติดป้าย "กำไรสุทธิสูงสุด"/"กำไรต่อชั่วโมงสูงสุด" (อาจคนละ Scenario) (5) วันในสัปดาห์ไม่บังคับ (ค่าเริ่ม "ทุกวัน", เรียงจันทร์ก่อน) · เวลาเลิก ≤ เวลาเริ่ม = เลิกวันถัดไป · ความยาวกะผิด → แจ้งในแอปก่อนส่ง (6) รายละเอียด: "คำนวณใหม่ด้วยข้อมูลล่าสุด" + Snackbar · ผูก/ยกเลิกผูกช่วงทำงาน · ไม่กรอกระยะทาง → เตือน "ไม่รวมต้นทุนระยะทาง" · ที่มาของตัวเลข (7) สร้างใหม่ → ไปหน้ารายละเอียด (`context.go`, รายการอยู่ข้างใต้) **ไม่มี Snackbar** เพราะ Snackbar ขึ้นบน Scaffold ของ Shell แล้วทับแถบเปรียบเทียบหลังกดกลับ (ทำให้ Navigation test ตก) · แก้ไขแล้วยังมี Snackbar ตามเดิม
- ผล: `dart format` สะอาด · `flutter analyze` No issues · `flutter test` **415 passed** (+48: `test/unit/features/shift_test.dart` 23, `test/widget/shift_screens_test.dart` 26, navigation) · gitleaks `dir` (ไฟล์ที่ Commit) + `git` (9 commits) → no leaks found
- **ตรวจบน Emulator กับ API จริง:** แท็บ 5 อันเรียงถูก · รายการ 3 Scenario ใน Dev DB (Late night, Lunch rush, Friday evening) · รายละเอียด Late night 22:00–02:00 "เลิกวันถัดไป" + คำเตือนระยะทาง · ฟอร์ม: Dev DB มีประวัติ 2 วัน → มีแค่ "จากสมมติฐาน" · สร้าง "Emu check" 2.5 ออเดอร์/ชม. × ฿45 × 5 ชม. → ฿562.50 ตรง Server · กลับรายการ → เลือก 2 รายการ → แถบเปรียบเทียบไม่ถูกบัง → หน้าเปรียบเทียบติดป้ายถูก · ลบ (Dialog ยืนยัน) → ที่เลือกเหลือ 1 · ลบ "Emu check" แล้ว (Dev DB เหลือ 3 Scenario เดิม)
- Emulator จอดำ (แอป `HAS_DRAWN` แต่ `dumpsys window` บอก `shown=false` และ Layer Splash Screen ค้างบนสุด) = แอนิเมชัน Splash ของระบบค้าง ไม่ใช่โค้ดแอป → `adb emu kill` แล้ว `emulator.exe -avd Pixel_9_Pro -no-snapshot-load` (เมนู Cold Boot ใน Device Manager กดไม่ได้ตอน Emulator รันอยู่)
- ไม่ได้ตรวจบน Emulator: Dark mode หน้า Shift · วิธี historical (ประวัติไม่พอ) · ผูกช่วงทำงาน · คำนวณใหม่ (มี Widget test ทั้งหมด)

### 4.8 Brand intro (Splash แอนิเมชัน) + ไอคอนแอป — **เสร็จ 2026-11-12 (Commit `cdb78ba` ตามที่ผู้ใช้สั่ง · ผู้ใช้ขอก่อนเริ่ม Phase 4 ไม่นับเป็นงานของ Phase ใด)**
- ที่มา: ภาพ `Premium RiderOS Emblem.png` ของผู้ใช้ + Spec "Minimal Luxury" (พื้นเขียวป่า, โลโก้สีงาช้าง, Accent มิ้นต์หม่น, ~3 วินาที, Flutter native animation, SVG, ไม่ใช้ GIF/Glow/Particle, ห้ามแก้ Dashboard)
- โลโก้ Vector: `mobile/assets/brand/rideros_logo.svg` (viewBox 808×600) แปลงจาก PNG ด้วย potrace (Script อยู่นอก Repo) · 1 `<path id>` ต่อ 1 Layer: `speed-lines`, `body`, `shoulder`, `helmet`, `wordmark-rider`, `wordmark-os` · ต่างจากภาพต้นฉบับ: เงารอยพับของตัว R เป็นสีงาช้างเรียบ · "OS" สีมิ้นต์ทึบ (`#8FD1A6`) ไม่ไล่สี · เส้นความเร็วจางจากซ้ายเหมือนเดิม
- `lib/app/intro/brand_logo.dart`: `BrandLogo` (อ่าน SVG → `Path` ด้วย Package `path_parsing`), `LogoReveal` (Timeline: `Interval` + `TweenSequence`), `BrandLogoPainter` (CustomPainter, repaint จาก Animation ไม่ Rebuild) · `lib/app/intro/brand_intro.dart`: `BrandIntro` Overlay ใน `MaterialApp.builder` (`app.dart`) · Router/หน้าจอเดิมไม่แก้ · `SplashScreen` เดิมยังอยู่ใต้ Overlay (ใช้แสดง Error ตอน Restore ไม่ได้)
- Timeline (`AppDurations.introReveal` 2600 ms + `introExit` 400 ms): พื้นหลังเฟดเข้า 0–0.36 s → ปากกาวาดเส้นขอบ (ความเร็ว → R → ไหล่ → หมวก) 0.16–1.4 s → สีเติมกวาดซ้าย→ขวา 1.04–1.7 s → Wordmark เฟด + Scale 0.94→1 1.5–2.1 s → ค้าง → Overlay จางออก + โลโก้ Scale 1→1.03 2.6–3.0 s
- พฤติกรรม: ระหว่างเล่นกดหน้าข้างใต้ไม่ได้ · Session ยัง Restore อยู่ → ค้างโลโก้ + แถบโหลดบางสีมิ้นต์ แล้วค่อยจางออก · Restore ไม่สำเร็จ → จางออกไปหน้า Error เดิม · ระบบเปิดลดการเคลื่อนไหว → ข้ามแอนิเมชัน · ขนาดโลโก้ 62% ของด้านสั้น (160–340) · Token ใหม่ `AppColors.logoIvory`/`logoMint`
- Android: Adaptive icon (`mipmap-anydpi-v26`: พื้นไล่เฉดเขียว + โลโก้พร้อม Wordmark ในพื้นที่ปลอดภัย + monochrome) + ไอคอนแบบเก่าทุกขนาด · หน้าต่างก่อน Flutter และ Splash ของ Android 12+ (`values-v31`, `values-night-v31`) เป็น `#0D1915` แทนสีขาว · ไม่มีโฟลเดอร์ `ios` จึงทำแค่ Android
- Test: `brandIntroEnabledProvider` (ปิด Intro ใน `navigation_test.dart` เพราะ Overlay บังหน้าจอ) + Navigation test ใหม่ 1 ตัวที่เปิด Intro จริง · `test/helpers/file_bundle.dart` (โหลด Asset จากดิสก์ใน Fake time) · `brand_logo_test.dart` 3 + `brand_intro_test.dart` 2
- ผล: `flutter analyze` No issues · `flutter test` **421 passed** (+6) · `flutter build apk --debug` ผ่าน · ตรวจเฟรมแอนิเมชันจากภาพ Golden ชั่วคราว (ลบแล้ว) · gitleaks `dir` (379 ไฟล์) + `git` (12 commits) → no leaks found
- ยังไม่ได้ดูบน Emulator/เครื่องจริง (ความลื่น 60 FPS, ไอคอนบน Launcher, Splash Android 12+) → ดูพร้อม Phase 4

### 4.2 Session ถัดไปเริ่มตรงนี้
**Phase 3 อนุมัติแล้ว 2026-11-11 (ผู้ใช้ยืนยันการตัดสินใจ §4.6 + §4.7 ตามที่เสนอ) → Session ถัดไป: เริ่ม Phase 4 Integration (W9)**
- Exit criteria (Roadmap §Phase 4): E2E Register → Login → Dashboard → Pickup Prediction → Add Income → Add Expense → View Profit → Create Scenario → Compare ด้วย `integration_test` บน Emulator + API จริง · ตัวเลขใน App ตรงกับ DB (ตรวจด้วย SQL)
- งานค้างที่ยกมา Phase 4: Deep link `rideros://reset-password` (§4.1 ข้อ 5) · สิ่งที่ยังไม่ได้ดูบน Emulator (Dark mode หน้า Profile/Shift/ผลทำนาย, Shift historical, ผูกช่วงทำงาน, 503) · Known issues §7 (Snackbar ทับ FAB/แถบเปรียบเทียบ) · Roadmap W9 = แก้ Bug → MVP Freeze
- เริ่มด้วยการเสนอแผน + การตัดสินใจของ Phase 4 ให้ผู้ใช้ยืนยันก่อนลงมือ (แบ่งงานย่อยแบบ Phase 2/3) · จบ Phase 4 → Phase 4 Report แล้วรออนุมัติ **ห้ามเริ่ม Phase 5** · ห้าม Commit จนกว่าผู้ใช้สั่ง
- ข้อ 1 (ตรวจสถานะ) + ข้อ 3–5 ด้านล่างยังใช้ได้ · ข้อ 1 ตอนนี้ HEAD = Commit ที่บันทึกการอนุมัติ Phase 3 (ต่อจาก `2961f9a`)

1. ตรวจสถานะ: `git status` (ต้องสะอาด · HEAD = Commit ที่บันทึก HANDOFF นี้ ต่อจาก `aed472f`) · `docker compose ps` (ถ้าหยุด → `docker compose up -d`; `/ready` ต้อง database ok + model ok `pickup_o2p/1.0.0`) · `flutter devices` (ต้องเห็น `emulator-5554`; ถ้าไม่เห็น → `"$LOCALAPPDATA/Android/Sdk/emulator/emulator.exe" -avd Pixel_9_Pro` รันเบื้องหลังแบบไม่ Pipe output หรือให้ผู้ใช้เปิดจาก Android Studio → Device Manager) · `cd mobile; flutter analyze; flutter test` (ต้องได้ No issues + **415 passed**)
2. ~~เริ่ม P3c กลุ่ม (b) Pickup Intelligence ทุกหน้า~~ **เสร็จแล้ว (§4.6)** (UI_STRUCTURE §5.4 + RIDEROS_UI_DESIGN §4.4: S-PICKUP-SEARCH → S-RESTAURANT → S-PREDICTION-RESULT, S-PREDICTION-HISTORY, S-PICKUP-LOGS + S-PICKUP-LOG-FORM, S-OWN-RESTAURANT-FORM, S-MODEL-INFO) · เพิ่มแท็บ Pickup ตำแหน่งที่ 2 · เพิ่ม Tile "ข้อมูลโมเดล Pickup" → S-MODEL-INFO ในหัวข้อ "ข้อมูลและสัญญาอนุญาต" ของหน้าโปรไฟล์ (`profile_screen.dart`) · ดู API จริงที่ `backend/README.md` (`/pickup/restaurants`, `/pickup/restaurants/{id}/analytics`, `/pickup/restaurants/{id}/wait-stats`, `/pickup/predictions`, `/pickup/logs`, `/pickup/model`)
   → ~~(c) Shift Simulator~~ **เสร็จแล้ว (§4.7)**
   → ~~Phase 3 Report~~ **ส่งแล้ว 2026-11-11 (ผลตรวจ Exit criteria ด้านล่าง) → ผู้ใช้อนุมัติแล้ว 2026-11-11 + สั่ง Commit**
   → (เดิม) Phase 3 Report (ผู้ใช้สั่ง 2026-11-11 ให้ทำใน Session นี้) สรุป P3a–P3c ตามหัวข้อ Completed tasks / Created-Modified files / Decisions (รวมข้อที่ยังไม่ยืนยันใน §4.6 + §4.7) / Test results / Remaining tasks / Known issues / Next steps · เทียบ Exit criteria Phase 3 (ด้านล่าง) ทีละข้อ → **รออนุมัติ ห้ามเริ่ม Phase 4 จนกว่าผู้ใช้อนุมัติ**
   · แต่ละกลุ่ม: `dart format` + `flutter analyze` + `flutter test` + ดูบน Emulator แล้วรายงาน · **ห้ามเริ่ม Phase 4 · ห้าม Commit จนกว่าผู้ใช้สั่ง** · ก่อน Commit รัน gitleaks ตามวิธีใน §4.5
   · หน้าใหม่ทุกหน้าต้องตาม `docs/RIDEROS_UI_DESIGN.md` §4.4–4.6 และใช้ Component ที่มี (§4.4, §4.5): `SectionCard`, `SectionHeader`, `MetricTile`, `TileGroup`, `AppBadge` (`ค่าประมาณ`/`Dataset`/`ร้านของฉัน`/ระดับข้อมูล), `LabeledField`, `SummarySkeleton`/`ListSkeleton`, `AppBanner`, `AsyncValueView`, `RecordFormScaffold`/`RecordLoader`/`closeForm`/`confirmDelete` (`core/widgets/form_widgets.dart`) · Pickup: แสดงเป็นช่วงเสมอ + Label "Order-to-Pickup" + `warnings`/`disclaimer` · ร้านของฉันซ่อนปุ่มทำนาย · RoadContext ไม่มีแท็บ (Phase 5)
3. Widget/แนวทางที่มี: `AsyncValueView` (Loading/Empty/Error/Data), `AppBanner`, `SubmitNotifier` (อ่าน `ref` ที่ต้องใช้ก่อน await ดู `PickupFormController._save`), `PagedListNotifier` + `watchDependencies()` (`core/presentation/paged_list.dart`), `PagedListView` + `RoundIcon` (`core/widgets/paged_list_view.dart`), `Formats.count`, `Validators.optionalDecimal`, `DecimalConverter`, `profitDataRevisionProvider` · ข้อความใหม่ใส่ใน `lib/l10n/app_th.arb` แล้ว `flutter gen-l10n` · Model ใหม่ → `dart run build_runner build` · ฟอร์มเปิดบน root navigator (`parentNavigatorKey`) ดูตัวอย่าง `profileRoutes(rootKey)` ใน `app/router.dart` · Route ใหม่ต้องเพิ่มใน `allRoutePatterns` ของ `test/helpers/pump.dart` · Fake ใหม่ส่งผ่าน `fakeRepositories(auth, profiles, profit, pickup)` (ตัวอย่าง `test/helpers/pickup_fakes.dart`)
4. รันแอปบน Emulator: `flutter run -d emulator-5554` (รันเบื้องหลังแล้ว Session หลุดได้ `Lost connection to device` แต่แอปยังเปิดอยู่) · Screenshot: `adb -s emulator-5554 exec-out screencap -p > <scratchpad>/x.png` (ภาพจริง 1280×2856)
   · adb: Git Bash ต้อง `export MSYS_NO_PATHCONV=1` · หาพิกัดปุ่มจาก `adb shell uiautomator dump /sdcard/ui.xml` แล้วอ่าน `content-desc` + `bounds` · พิมพ์ช่องว่างด้วย `input text "a%sb"` · ซ่อนคีย์บอร์ดด้วย `input keyevent 4` (ESC ไม่ได้) · พิกัดเลื่อนเมื่อคีย์บอร์ดเปิด
   · บัญชีทดสอบใน Dev DB: `p3b.check@example.com` / `p3b check pass` (ชื่อแสดงตอนนี้ "Rider Check", ตั้งโปรไฟล์ไรเดอร์แล้ว, มีรายได้/ค่าใช้จ่ายจาก P3b) · `p3c.delete@example.com` ถูกลบแล้ว (สร้างบัญชีทิ้งใหม่ผ่าน API ถ้าต้องทดสอบลบ)
5. Test helper ที่ควรรู้: `test/helpers/pump.dart` (`pumpScreen`, `pushScreen`, `enter`, `tapKey`, `t` = ข้อความไทย, **`scrollIntoView` / `scrollAndTap`** สำหรับแถวที่อยู่นอกจอทดสอบ 800×600 ใน ListView), `fakes.dart` (`FakeAuthRepository` มี `updateNameError`/`deleteError`/`deleteGate`, `FakeRiderProfileRepository(configured:, profile)` มี `fetchGate`/`fetches`), `profit_fakes.dart` (`ProfitFakes`, `FakeRecordRepository`, `testNow` = อ. 10 พ.ย. 2026 14:07), `fake_http_adapter.dart` (Fake API สำหรับ dio) · `tester.pageBack()` หา Back button ไม่เจอ → ใช้ `tester.binding.handlePopRoute()` · หน้าที่อ่าน Session ต้องรอ Session restore ก่อน push (ดู display name tests)

**Exit criteria Phase 3:** ทุกหน้ามี Loading/Empty/Error/Success · ทุก Form มี Validation + Widget Test · Navigation Tests + Notifier/State Unit Tests · ไม่มีปุ่มที่ไม่ทำงาน (Feature ไม่พร้อม → ซ่อน) · `flutter analyze` ไม่มี Warning

**ผลตรวจ Exit criteria Phase 3 (2026-11-11, HEAD `2961f9a`, tree สะอาด):**
- States ✅ — 30 หน้าจอ (`*_screen.dart`): หน้าที่โหลดข้อมูลใช้ `AsyncValueView`/`PagedListView` (Loading = Skeleton/Spinner, Error = `ErrorView` + ลองใหม่, Empty เฉพาะหน้าที่เป็นรายการ) · ฟอร์มแก้ไขใช้ `RecordLoader` · ฟอร์มส่งข้อมูล: ปุ่มหมุน + กันกดซ้ำ + Error Banner · ไม่มี Empty โดยธรรมชาติ: ผลทำนาย, การ์ดโมเดล, รายละเอียด/เปรียบเทียบ Scenario (มี Loading/Error) · About เป็นข้อมูลคงที่ในแอป (ไม่โหลด)
- Forms ✅ — 14 ฟอร์ม (Login, Register, Forgot, Reset, Onboarding, ชื่อแสดง, โปรไฟล์ไรเดอร์, ลบบัญชี, รายได้, ค่าใช้จ่าย, ช่วงทำงาน, บันทึกเวลารับ, ร้านของฉัน, Scenario) มี Validation + Widget test ทุกฟอร์ม
- Navigation + Unit ✅ — `test/widget/navigation_test.dart` (Router จริง + Guard + Full-stack dio) · Unit: session controller, token manager single-flight, interceptor, router redirect, profit providers, pickup/shift notifiers + repositories
- ไม่มีปุ่มตาย ✅ — grep `onPressed: () {}`/`onTap: () {}`/`UnimplementedError`/`TODO` ใน `lib/` = 0 · ซ่อน: วิธี `ml`, ปุ่มทำนายของร้านของฉัน, แก้อีเมล, แก้/ลบร้าน, แก้ Log, Deep link
- `flutter analyze` ✅ No issues · `flutter test` **415 passed** · Coverage `lib/` (ไม่รวม generated/l10n) **96.9%** (5,102/5,263 บรรทัด; ต่ำสุด `core/storage` 57.1% = Wrapper ของ `flutter_secure_storage`)

**แบ่งงานแบบเดียวกับ Phase 2:** ทำ P3a → รายงานความคืบหน้า + การตัดสินใจให้ผู้ใช้ยืนยัน → P3b → P3c → Phase 3 Report แล้วรออนุมัติ **ห้ามเริ่ม Phase 4** · ห้าม Commit จนกว่าผู้ใช้สั่ง

## 5. คำสั่ง (PowerShell)

```powershell
cd "C:\dev\RiderOS AI\ml"
python -m uv sync                      # สร้าง/ซิงก์ .venv ตาม uv.lock
python -m uv run pytest                # 134 tests (~70 s); -m "not slow" เพื่อข้ามตัวที่ช้า
python -m uv run rideros-ml train      # ~29 นาที (1,738 s) — รันเบื้องหลัง
python -m uv run rideros-ml stats

cd "C:\dev\RiderOS AI"
docker compose up --build              # DB + API + โมเดล (ต้องมี ml/artifacts ก่อน); ครั้งแรก Import ร้านเอง
cd backend
python -m uv run pytest --cov=app/modules   # 317 tests (~45 s) ต้องมี `docker compose up -d db`
python -m uv run ruff check . ; python -m uv run ruff format --check .
```

ลำดับ Pipeline: `download → validate → build → eda → train → stats`

## 6. ข้อควรระวัง

- **ห้าม Commit** `ml/data/`, `ml/artifacts/`, ไฟล์ CSV/ZIP/Parquet/Joblib ใดๆ (CC BY-NC 4.0 + ห้ามแจกจ่าย; D1/D4) — ตรวจ `git diff --cached --name-only` ก่อน Commit ทุกครั้ง
- **Commit เฉพาะเมื่อผู้ใช้สั่ง** · ยังไม่มี Remote · Phase 3 ห้าม Commit Keystore/`key.properties` (อยู่ใน `.gitignore` แล้ว) หรือไฟล์ Config ที่มี Key
- Acknowledgement ต้องแสดงใน README และหน้า Model Info ของแอป: *This research was supported by data provided by Meituan.*
- Label ผลทำนายว่า **Order-to-Pickup** เสมอ ห้ามเรียกว่าเวลารอของ Rider หรือเวลาทำอาหาร
- uv ไม่อยู่ใน PATH → `python -m uv`. ถ้า Shell มี `VIRTUAL_ENV` ของ `ml/.venv` ค้าง `python` จะชี้ venv (ไม่มี uv) → ใช้ `%LOCALAPPDATA%\Python\pythoncore-3.14-64\python.exe -m uv ...` หรือ `ml\.venv\Scripts\*.exe` ตรงๆ
- ~~ผู้ใช้ต้องทำเองก่อน Phase 3: `flutter doctor --android-licenses`~~ ทำแล้ว 2026-11-10

## 7. Known issues (ไม่บล็อก Phase 3)

- (P3b) SnackBar "บันทึกแล้ว" ลอยทับปุ่ม "+ เพิ่ม…" ในหน้ารายการราว 4 วินาที (SnackBar แสดงบน Scaffold ของ Shell ซึ่งไม่รู้จัก FAB ของหน้าข้างใน) — ไม่บล็อก
- (P3c-c) SnackBar "ลบแล้ว" หลังลบ Scenario ลอยทับแถบ "เลือกแล้ว/ล้างที่เลือก" ของหน้ารายการกะงานราว 4 วินาที (สาเหตุเดียวกับข้อบน) — ไม่บล็อก
- (P3b) หลังแก้ 2 จุด (ป้ายจำนวนรายการ, ระยะขอบกราฟ) ยังไม่ได้ Screenshot ซ้ำบน Emulator (Tests ผ่าน)

- Artifact 1.0.0 มี `git_commit: "no-commit"` (Train ก่อน Commit แรก) — Train ใหม่ได้ถ้าต้องการผูกกับ Commit (ผลจะเหมือนเดิมเพราะ seed=42)
- ร้านที่ไม่มีใน Train: MAE 7.24, Coverage 65.1% (215 orders) → Backend แสดงคำเตือนตาม `data_availability` แล้ว (P2c) และ `/pickup/model` ระบุใน `limitations`
- Backend image 1.03 GB (scikit-learn + xgboost + pandas) — ลดได้ภายหลังด้วย Multi-stage/ตัด pyarrow
- Rate limiter อยู่ใน Memory ต่อ Process → หลาย Worker/หลาย Instance จะนับแยกกัน (ใช้ Redis ตอน Deploy ถ้าจำเป็น) · ยังไม่เชื่อ `X-Forwarded-For`
- Test run ไป Upsert/Activate แถว `model_versions` ใน Test DB (ไม่กระทบ Dev DB)
- Shift `historical` ใช้ค่าเฉลี่ยทั้งวันของ Session (ไม่แยกช่วงเวลาของวัน)
- ~~Lint เดิมใน `ml/src/`: E501 100 จุด + F401 1 จุด~~ → แก้แล้ว 2026-11-09: `ruff format` + ลบ import `numpy` ที่ไม่ได้ใช้; E501 ที่เหลือ 45 จุดเป็นข้อความ Report/Model card จึงใส่ `per-file-ignores` ใน `ml/pyproject.toml`; `ml/tests` 134 passed หลังแก้
- EDA เป็นรายงานจาก CLI ไม่ใช่ Notebook (บันทึกหมายเหตุใน Roadmap แล้ว)
- Data: Chronology ผิดปกติ 1 แถว (push > dispatch) และ 1 แถว (fetch > arrive); `estimate_meal_prepare_time = 0` มี 9,907 แถว
