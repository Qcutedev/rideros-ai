# HANDOFF — RiderOS AI

> อัปเดตล่าสุด: 2026-11-12 · สถานะ: **Phase 5 RoadContext กำลังทำ: แผน + 12 การตัดสินใจอนุมัติ (§4.11) · P5a Backend `04bd24c` · ถัดไป P5b Mobile ใน Session ใหม่ที่ §4.2** · Phase 3 อนุมัติแล้ว 2026-11-11 · Phase 4 อนุมัติแล้ว 2026-11-12 (`cc2a8b9`, §4.9) · MVP Freeze (Tag `mvp-freeze`) · Intro ขี่รถ + ไอคอนแอป (`cdb78ba` → `4a364e1`, §4.8, ก่อนเริ่ม Phase 4) · P3a + P3b + UI (§4.4, `56526ee`) · P3c (a) Profile (`549c27b`, §4.5) · (b) Pickup (`f76d050`, §4.6) · (c) Shift (`aed472f`, §4.7) · การตัดสินใจ §4.1, §4.3, §4.6, §4.7 ยืนยันครบ · Phase 2 อนุมัติ + Commit แล้ว
> Phase 0 + Decisions D1–D7 อนุมัติแล้ว (ดู `docs/PROJECT_PLAN.md` §4) · Git บน `main`: `a7fe027` (Phase 0–1) → `5d7be02` (Phase 2) → `56526ee` (Phase 3 P3a–P3b + UI) → `549c27b` (P3c-a) → `f76d050` (P3c-b) → `aed472f` (P3c-c) → `cdb78ba` (Brand intro) → `4a364e1` (Ride intro) → `cc2a8b9` (Phase 4) → `7da3bde` (Logo) → `04bd24c` (P5a) · ยังไม่มี Remote / ยังไม่ Push · Commit เฉพาะเมื่อผู้ใช้สั่ง

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

### 4.8 Intro ตอนเข้าแอป (ฉากขี่รถ) + ไอคอนแอป — **เสร็จ 2026-11-12 (Commit `cdb78ba` แล้วแก้ใน `4a364e1` ตามที่ผู้ใช้สั่ง · ผู้ใช้ขอก่อนเริ่ม Phase 4 ไม่นับเป็นงานของ Phase ใด)**
- ที่มา: ภาพ `Premium RiderOS Emblem.png` ของผู้ใช้ + Spec "Minimal Luxury" (พื้นเขียวป่า, โลโก้สีงาช้าง, Accent มิ้นต์หม่น, ~3 วินาที, Flutter native animation, SVG, ไม่ใช้ GIF/Glow/Particle, ห้ามแก้ Dashboard)
- โลโก้ Vector: `mobile/assets/brand/rideros_logo.svg` (viewBox 808×600) แปลงจาก PNG ด้วย potrace (Script อยู่นอก Repo) · 1 `<path id>` ต่อ 1 Layer: `speed-lines`, `body`, `shoulder`, `helmet`, `wordmark-rider`, `wordmark-os` · ต่างจากภาพต้นฉบับ: เงารอยพับของตัว R เป็นสีงาช้างเรียบ · "OS" สีมิ้นต์ทึบ (`#8FD1A6`) ไม่ไล่สี · เส้นความเร็วจางจากซ้ายเหมือนเดิม
- รอบแรก (`cdb78ba`) เป็นโลโก้ถูกวาดด้วยปากกาแล้วเติมสี · ผู้ใช้ดูบน Emulator แล้วขอ (1) ไม่เอาไอคอนกลมใน Splash ของระบบ (2) ไม่ต้องยึดกับการโชว์โลโก้ อยากให้เป็นฉากขี่รถเคลื่อนที่ → `4a364e1` เปลี่ยนเป็นฉากขี่รถ
- `lib/app/intro/brand_logo.dart`: `BrandLogo` (อ่าน SVG → `Path` ด้วย Package `path_parsing`; `riderBounds`, `speedLinesBounds`, `wordmarkBounds`) · `lib/app/intro/ride_scene.dart`: `RideScene` (Timeline: `TweenSequence` + `Interval` บน 2 AnimationController + ระยะทางถนนที่สะสมจาก Ticker) + `RideScenePainter` (CustomPainter เต็มจอ, repaint จาก Animation ไม่ Rebuild) · `lib/app/intro/brand_intro.dart`: `BrandIntro` Overlay ใน `MaterialApp.builder` (`app.dart`) · Router/หน้าจอเดิมไม่แก้ · `SplashScreen` เดิมยังอยู่ใต้ Overlay (ใช้แสดง Error ตอน Restore ไม่ได้)
- Timeline (`AppDurations.introReveal` 2400 ms + `introExit` 600 ms): พื้นหลัง + เส้นถนนบางเฟดเข้า 0–0.36 s → ไรเดอร์ (ตัวขี่จากโลโก้) ขี่เข้าจากนอกจอซ้าย ชะลอถึงกลางจอ 0.14–1.25 s (ตอนเร็วตัวเอนไปข้างหน้า + เส้นความเร็วยืด) → กล้องขี่ตาม: เส้นแบ่งเลนไหลใต้ล้อ, เส้นลม 5 เส้นไหลคนละความเร็ว (Parallax), ตัวรถสั่นต่ำกว่า 1 px → Wordmark เฟด + ลอยขึ้นใต้ถนน 1.2–1.82 s → ค้าง → ไรเดอร์เร่งออกขวา + Wordmark จาง + Overlay จางเข้า Dashboard 2.4–3.0 s
- พฤติกรรม: ระหว่างเล่นกดหน้าข้างใต้ไม่ได้ · Session ยัง Restore อยู่ → ไรเดอร์ขี่อยู่กลางจอต่อ (ถนนยังไหล แทนแถบโหลด) แล้วค่อยออก · Restore ไม่สำเร็จ → ออกไปหน้า Error เดิม · ระบบเปิดลดการเคลื่อนไหว → ไม่มีอะไรเลื่อน ภาพนิ่งแล้วจางออก · ขนาดโลโก้ 62% ของด้านสั้น (160–340) · Token ใหม่ `AppColors.logoIvory`/`logoMint`
- Android: Adaptive icon (`mipmap-anydpi-v26`: พื้นไล่เฉดเขียว + โลโก้พร้อม Wordmark ในพื้นที่ปลอดภัย + monochrome) + ไอคอนแบบเก่าทุกขนาด · หน้าต่างก่อน Flutter และ Splash ของ Android 12+ (`values-v31`, `values-night-v31`) เป็น `#0D1915` แทนสีขาว และไม่มีไอคอน (`windowSplashScreenAnimatedIcon` = `drawable/splash_blank.xml` โปร่งใส) · ไม่มีโฟลเดอร์ `ios` จึงทำแค่ Android
- Test: `brandIntroEnabledProvider` (ปิด Intro ใน `navigation_test.dart` เพราะ Overlay บังหน้าจอ) + Navigation test ใหม่ 1 ตัวที่เปิด Intro จริง · `test/helpers/file_bundle.dart` (โหลด Asset จากดิสก์ใน Fake time) · `brand_logo_test.dart` 2 + `brand_intro_test.dart` 2
- ผล (`4a364e1`): `flutter analyze` No issues · `flutter test` **420 passed** (ลบ Test เส้นปากกาที่ไม่ใช้แล้ว 1) · ตรวจเฟรมจากภาพ Golden ชั่วคราว (ลบแล้ว) · gitleaks `dir` (381 ไฟล์) + `git` → no leaks found
- **ตรวจบน Emulator (Profile build `flutter build apk --profile` + `adb install -r`):** Splash ของระบบเป็นพื้นเขียวเข้มไม่มีไอคอน → ฉากขี่รถ → ไรเดอร์ออกขวา → หน้าหลัก · ไอคอนใหม่บน Launcher · Debug build ที่เปิดจาก Launcher เองช้า (Frame แรก +9.8 s, กระตุก) ต้องดูความลื่นด้วย Profile build (Frame แรก +2.4 s) · แอปที่ลงใน Emulator ตอนนี้เป็น Profile build
- ยังไม่ได้วัด FPS ด้วย DevTools

### 4.9 Phase 4 Integration (W9) — **อนุมัติแล้ว 2026-11-12 (Commit `cc2a8b9` · การตัดสินใจ 10 ข้อยืนยันตามที่แนะนำ · ข้อ 7 ที่ต่างจากแผนผู้ใช้ยืนยันแล้ว)**
- งานย่อย: **P4a** E2E `integration_test` + ตรวจตัวเลขกับ DB → **P4b** Deep link `rideros://reset-password` + งานค้าง (SnackBar §7, ดูบน Emulator: Dark mode Profile/Shift/ผลทำนาย, Shift `historical`, ผูกช่วงทำงาน, 503) → **P4c** แก้ Bug + MVP Freeze + Phase 4 Report แล้วรออนุมัติ
- การตัดสินใจ (ยืนยันแล้ว):
  1. รัน E2E ด้วย `flutter drive` + Driver ฝั่ง Host (`mobile/test_driver/integration_test.dart`) ตรวจ SQL ผ่าน `docker compose exec db psql` ในคำสั่งเดียว
  2. บัญชีใหม่ทุกรอบ `e2e+<timestamp>@example.com` · ตรวจ SQL ผ่านแล้ว Driver ลบผ่าน `DELETE /me` แล้วนับแถวที่เหลือต้องเป็น 0 · `E2E_KEEP=1` เก็บบัญชีไว้ · ถ้า Check ไม่ผ่านบัญชีจะค้างไว้ให้ดู
  3. ใช้ Dev stack (`docker compose`) ไม่แก้ Rate limit
  4. Intro ขี่รถเปิดใน E2E (Flow จริง) · ล้าง secure storage ก่อนเริ่ม
  5. เทียบกับ DB: ยอดรายได้/ค่าใช้จ่าย, กำไรสุทธิวันนี้ (หน้า Home + TrueProfit), ชั่วโมง, กำไร/ชม., ช่วง Pickup low–high + ค่ากลาง (`pickup_predictions`), ค่าใน Compare ของ Scenario ทั้ง 2 (`shift_scenarios`) + ชื่อที่กำไรสูงสุด · ตรวจ `rider_profiles` ที่กรอกตอน Onboarding ด้วย
  6. ร้านที่ทำนาย: ค้น `POI-203` (Meituan, `sufficient`, 2,433 orders)
  7. Deep link ตอน Login อยู่ยังเปิดหน้า Reset
  8. SnackBar แสดงบน ScaffoldMessenger ของหน้าที่มี FAB/แถบ ไม่ใช่ของ Shell
  9. MVP Freeze = หลังอนุมัติ Phase 4 ไม่เพิ่ม Feature ให้ Module 1–3 แก้ได้เฉพาะ Bug · Tag `mvp-freeze` เมื่อผู้ใช้สั่ง Commit
  10. ไม่มี CI ใน Phase 4 (Phase 6/7)
- พบระหว่างทำ: สมัครสมาชิกแล้วแอป Login ให้ทันที (`RegisterOutcome.signedIn`) จึงทดสอบ Login ด้วยการ Logout จากหน้าโปรไฟล์แล้ว Login ใหม่ · Journey จริง: Register → Onboarding → Logout → Login → Dashboard → Pickup → รายได้ → ค่าใช้จ่าย → TrueProfit → Scenario 2 อัน → Compare
- **P4a เสร็จ 2026-11-12** — `mobile/integration_test/app_journey_test.dart` (Journey ผ่าน UI ทั้งหมด) + `mobile/test_driver/integration_test.dart` (Driver ฝั่ง Host: เทียบ SQL แล้วลบบัญชี) · dev deps `integration_test`, `flutter_driver` (SDK) · วิธีรันใน `mobile/README.md` หัวข้อ "End-to-end journey"
  · ผล: `flutter drive ... -d emulator-5554` → All tests passed + **21 DB checks passed** + ลบบัญชีแล้วไม่มีแถวเหลือ (ผ่านติดกันหลายรอบ, ~40 s ต่อรอบหลัง Build) · ค่าที่ตรวจ: `rider_profiles` (motorcycle/40.00/38.50/0.6000), Pickup `POI-203` ช่วง `5–21 นาที` + ค่ากลาง (1 แถวใน `pickup_predictions`), วันนี้ รายได้ 850.50 / ค่าใช้จ่าย 120.25 / กำไร 730.25 / 5 ชม. / 146.05 ต่อชม. (หน้า Home + TrueProfit), Scenario A 562.50/58.59/503.91/100.78 และ B 600.00/82.50/517.50/103.50, กำไรสูงสุด = B
  · สิ่งที่แก้ใน Test harness ระหว่างทำ (ไม่ใช่บั๊กแอป): รอเมนู Dropdown ปิดก่อนแตะ, แตะซ้ำจนจุดแตะโดนเป้าหมาย (`hitTestWarningShouldBeFatal`) ระหว่างเปลี่ยนหน้า, เลื่อนหน้าเมื่อแถวอยู่นอก Lazy list, หาแถวร้านด้วย Key `restaurant.<id>` (ข้อความ `POI-203` ซ้ำกับช่องค้นหา)
- **P4b เสร็จ 2026-11-12**
  · Deep link: `AndroidManifest.xml` intent-filter `rideros://reset-password` + `flutter_deeplinking_enabled` · `router.dart`: `resetLinkLocation()` (Android ส่งลิงก์ทั้งเส้น path ว่าง → `/reset-password?token=`) + `AppRedirect` (จำลิงก์ไว้ระหว่าง Restore session แล้วเปิดหลัง Restore) + `authRedirect` ให้ Reset เปิดได้ตอน Login อยู่ (ข้อ 7) · `reset_password_screen.dart`: Reset สำเร็จตอน Login อยู่ → Logout ในเครื่องก่อน แล้วไปหน้า Login + Notice
    → **ต่างจากที่เสนอในข้อ 7 ("Reset สำเร็จแล้วกลับหน้าเดิม")**: Backend `reset-password` Revoke Refresh token ทุกเครื่อง (`revoke_all_for_user`) ถ้ากลับหน้าเดิม Session จะหลุดภายใน 15 นาที จึงพาไป Login ทันที — **ผู้ใช้ยืนยันแล้ว 2026-11-12**
    · ตรวจบน Emulator: Cold start ด้วยลิงก์ → หน้า Reset + Token เติมให้ · Warm start ตอน Login อยู่ (บัญชีทิ้ง `p4.reset@`) → หน้า Reset → ตั้งรหัสใหม่ → หน้า Login + "ตั้งรหัสผ่านใหม่แล้ว…" · API: รหัสเก่า 401, รหัสใหม่เข้าได้ · ลบบัญชีทิ้งแล้ว
  · SnackBar (§7 สองข้อ, ข้อ 8): `app_shell.dart` ห่อ Body ของ Shell ด้วย `ScaffoldMessenger` (`shellMessengerKeyProvider`) + `HeroMode(enabled: false)` (ไม่งั้น SnackBar ของหลายหน้าใน Route เดียวกันได้ Hero tag ซ้ำ) · `closeForm` ส่งข้อความไปที่ Messenger นี้หลังปิดฟอร์ม → SnackBar อยู่บน Scaffold ของหน้าที่มี FAB/แถบ · ตรวจบน Emulator: "บันทึกแล้ว" อยู่เหนือปุ่ม "+ เพิ่มรายได้" · "ลบแล้ว" อยู่เหนือปุ่ม "+ เพิ่ม Scenario" และแถบ "เลือกแล้ว 2 รายการ" · ไม่มีแอปใช้ Hero อื่น
  · ดูบน Emulator (Profile build, บัญชีทิ้ง `p4.visual@` + ประวัติ 7 วันจาก API): Shift `historical` → รายได้ 700.00 / ค่าใช้จ่าย 82.00 / กำไร 618.00 / ช่วง 578.40–657.60 (ตรง DB) · ผูกช่วงทำงาน 11 พ.ย. → `actual_work_session_id` ตรง + SnackBar "ผูกกับช่วงทำงานแล้ว" เหนือแถบนำทาง · Dark mode หน้า Shift detail, Profile, ผลทำนาย อ่านง่าย สีถูก · 503: รัน Backend ด้วย `MODEL_DIR=` → หน้าผลทำนายแสดง "โมเดล Pickup ยังไม่พร้อมใช้งาน…" + ลองใหม่ → เปิดโมเดลคืน → ลองใหม่ได้ผล · ลบบัญชีทิ้งแล้ว Dev DB เหลือ `p3b.check@` เท่านั้น
  · Tests ใหม่: `router_redirect_test.dart` (+4: map ลิงก์, เปิดได้ทุกสถานะ, จำระหว่าง Restore, ที่อื่นตาม Guard) · `password_reset_screens_test.dart` (+1: Reset ตอน Login อยู่ → logout → Login) · `navigation_test.dart` (SnackBar อยู่ใน `RecordsScreen` และไม่ทับปุ่มเพิ่ม — Fail ถ้าไม่มีการแก้)

### 4.10 โลโก้หน้า Login เป็น Emblem ของแบรนด์ — **เสร็จ 2026-11-12 (ผู้ใช้ขอหลังอนุมัติ Phase 4 · Commit `7da3bde` ตามที่ผู้ใช้สั่ง · gitleaks `dir` + `git` → no leaks found)**
- `AppLogoMark` (`core/widgets/form_layout.dart`) เดิมเป็นไอคอน Material (มอเตอร์ไซค์ + ประกาย) ในกล่องมิ้นต์ → วาด Emblem จริง (เส้นความเร็ว + ไรเดอร์ ไม่มี Wordmark) จาก `assets/brand/rideros_logo.svg` สีงาช้าง: บนพื้นเขียว (Login, สมัคร/ลืม/ตั้งรหัสใหม่, Splash) ไม่มีกล่อง กว้าง 1.5 เท่าของความสูง · ธีมสว่าง (หน้า About) อยู่ในกล่องเขียวป่ามุมมนแบบไอคอนแอป
- `brand_logo.dart`: `BrandLayer.emblem`, `emblemBounds`, `BrandLogo.layerPaint()` (การไล่จางของเส้นความเร็ว/ลำตัว ย้ายมาจาก `RideScenePainter._fill` ใช้ร่วมกัน), `BrandEmblemPainter` · โหลด SVG ครั้งเดียวต่อ AssetBundle
- Tests: `test/widget/app_logo_mark_test.dart` (+2) + `brand_logo_test.dart` (emblemBounds) · `flutter analyze` No issues · `flutter test` **427 passed** · ดูบน Emulator (Profile build) หน้า Login + สมัครสมาชิก ถูกต้อง
- หัวหน้า สมัครสมาชิก / ลืมรหัสผ่าน / ตั้งรหัสใหม่ (`AuthHeader.page` ใน `core/widgets/auth_layout.dart`): โลโก้ (56) + หัวข้อ + คำอธิบาย **จัดกึ่งกลาง** เหมือนหน้า Login · ปุ่มย้อนกลับยังอยู่ซ้ายบน · Test: `design_system_test.dart` ตรวจตำแหน่งกึ่งกลาง (Fail ถ้าไม่มีการแก้) · `flutter test` **427 passed** · ดูบน Emulator หน้าสมัคร + ลืมรหัสผ่าน ถูกต้อง

### 4.11 Phase 5 RoadContext AI (W10–W11) — **อนุมัติแล้ว 2026-11-12** (แผน + การตัดสินใจ 12 ข้อ ยืนยันตามที่แนะนำ · การตัดสินใจระหว่าง P5c 2 ข้อ (Alley val, Commit reports) อนุมัติพร้อม Phase 5)
- งานย่อย: **P5a** Backend RoadContext (ยังไม่มี CV): Migration `0004` (`road_incidents`, `incident_reports`), Module `road` 6 Endpoint ตาม SYSTEM_ARCHITECTURE §4, กฎรวมซ้ำ `ST_DWithin` + หมวด + ช่วงเวลา (ค่าใน Config), Status machine §4, อัปโหลดรูป (Magic bytes, ≤ 5 MB, Re-encode ลบ EXIF, ชื่อ UUID), Tests → **P5b** Mobile (แผนที่ `flutter_map` + OSM, รายการใกล้ตัว, ฟอร์มรายงาน, รายละเอียด + ยังอยู่/คลี่คลายแล้ว) → **P5c** CV (ตรวจ License 3 ส่วน → Transfer learning torchvision → `cv_service/` `POST /classify` → Background classify → แสดง "AI แนะนำ") + Phase 5 Report แล้วรออนุมัติ · License ไม่ผ่าน → ตัด CV ตามลำดับตัด Scope แล้วรายงานตรงๆ
- การตัดสินใจ (ยืนยันแล้ว):
  1. ทางเข้า: คง 5 แท็บ + การ์ด "เหตุบนถนนใกล้คุณ" ที่หน้าหลัก → Route `/road`
  2. `expired` คิดตอนอ่าน (`expires_at < now()` = expired ไม่แสดงบนแผนที่) · เขียนสถานะลงแถวเมื่อมีการเขียนครั้งถัดไป · ไม่มี Scheduler
  3. รูปเห็นได้เฉพาะเจ้าของ Report (Endpoint ต้อง Auth) · คนอื่นเห็นข้อมูลรวมเท่านั้น
  4. เก็บรูปใน Docker volume `road_images` (S3 ตอน Phase 7) · `DELETE /me` ลบรูปด้วย
  5. Admin = `users.role = 'admin'` (มีอยู่แล้ว) ตั้งผ่านสคริปต์ CLI เท่านั้น · ไม่มี UI admin
  6. `geolocator` สิทธิ์ "ขณะใช้งาน" เท่านั้น · ปฏิเสธสิทธิ์ยังปักหมุดเองได้ · ไม่ติดตามเบื้องหลัง
  7. OSM standard tiles ตอน Dev + `userAgentPackageName` + Attribution "© OpenStreetMap" · เปลี่ยน Provider ใน Phase 7 (R9)
  8. CV 3 คลาส `flooding` / `road_damage` / `other` จาก Dataset ที่ License ผ่าน (RDD2022 + AlleyFloodNet/Flood10k) เลือกบางส่วน · ห้าม Commit Dataset
  9. MobileNetV3-Large (ImageNet weights ของ torchvision) · Split Train/Val/Test ไม่ปน · Metrics บน Test + Latency บน CPU ของ `cv_service` · ระบุว่าไม่มีภาพจากไทย
  10. แสดง "AI แนะนำ: <หมวด> (xx%)" + ป้าย `ค่าประมาณ` · < 0.6 → "AI ไม่แน่ใจ" · ไม่เปลี่ยนหมวด/สถานะเอง · ห้ามคำว่า "ยืนยันแล้ว" · `corroborated` แสดงเป็น "มีผู้รายงานหลายคน"
  11. `cv_service/` ตาม Architecture §6 · Training ใน `cv_service/training/` · uv project แยก (torch ไม่ปน `ml/`)
  12. รัศมี/ช่วงเวลา/TTL ตาม DATABASE_DESIGN §4 (ค่าเริ่มต้นที่ยังไม่ Validate — ระบุในเอกสาร)
- **P5a เสร็จ 2026-11-12 (Commit `04bd24c` ตามที่ผู้ใช้สั่ง · gitleaks `dir` + `git` → no leaks found)** — Backend RoadContext ไม่มี CV
  · Migration `0004_road_context.py` · Module `backend/app/modules/road/` (`rules.py` ค่าตาม §4 + `ROAD_RULES` JSON override รายหมวด, `models.py`, `schemas.py`, `images.py`, `service.py`, `router.py`) · `scripts/set_role.py` (ตั้ง admin) · Settings ใหม่: `ROAD_RULES`, `ROAD_CORROBORATE_MIN_REPORTERS`=2, `ROAD_RESOLVE_MIN_CLEARED`=2, `ROAD_IMAGE_DIR`, `ROAD_IMAGE_MAX_BYTES`=5 MB, `RATE_LIMIT_ROAD_REPORT`=10/min ต่อผู้ใช้ · deps `pillow`, `python-multipart` · compose volume `road-images` → `/data/road_images` (Dockerfile สร้างโฟลเดอร์ให้ user `app`) · API ทั้งหมดใน `backend/README.md` หัวข้อ RoadContext
  · Endpoint เพิ่มจาก Architecture §4: `GET /road/reports` (Report ของฉัน) + `GET /road/reports/{id}/image` (รูปของฉันเท่านั้น, ข้อ 3)
  · กฎ: รวมเข้ากับเหตุที่ใกล้ที่สุดหมวดเดียวกันภายในรัศมี + report ล่าสุดภายในช่วงเวลา · ตำแหน่งเหตุ = ของ Report แรก · `pg_advisory_xact_lock` ต่อหมวดกันเปิดเหตุซ้ำพร้อมกัน · ผู้ใช้เดิมรายงานเหตุเดิมซ้ำ → 409 `already_reported` · ยืนยันใหม่แทนที่ของเดิม · ตัดสินใจเพิ่มระหว่างทำ (บันทึกใน DATABASE_DESIGN): `unverified` → `resolved` ได้ด้วย 2 cleared, Admin ตั้งได้เฉพาะ resolved/rejected
  · รูป: Magic bytes JPEG/PNG/WebP, ≤ 5 MB (เช็ค Content-Length ก่อน + อ่านไม่เกิน), ≤ 40 MP, หมุนตาม EXIF แล้ว Re-encode เป็น JPEG ≤ 1600 px ไม่มี EXIF/GPS, ชื่อ `<uuid hex>.jpg` · เขียนไม่สำเร็จ → ลบไฟล์คืน · `DELETE /me` ลบรูป + คำนวณ `report_count`/`distinct_reporters` ใหม่ + ลบเหตุที่ไม่เหลือ Report
  · Tests: `tests/api/test_road.py` (58: กฎรวมซ้ำทุกหมวด 5 แบบ = ในรัศมี/ขอบช่วงเวลา, นอกรัศมี, เลยช่วงเวลา, ต่างหมวด, หมดอายุแล้วไม่รวม · ใกล้สุด · Corroborate/Resolve/แทนที่การยืนยัน/Expired/Admin · bbox/nearby · ความเป็นส่วนตัว · รูป EXIF/หมุน/PNG โปร่งใส/415/413/503/ลบไฟล์เมื่อพัง · ลบบัญชี) + rate limit + config · Backend **380 passed**, ruff สะอาด, Coverage `app/modules` 98% (road service 98%)
  · Dev stack: Rebuild แล้ว Migration 0004 ผ่าน · Smoke ผ่าน API จริง (รายงาน + รูป → 201, รูป 200 JPEG, nearby/bbox เจอ, `DELETE /me` → ไม่เหลือแถว/ไฟล์)
  · ถัดไป: **P5b Mobile** — ผู้ใช้สั่งให้เริ่มใน Session ใหม่ (§4.2)
- **P5b โค้ด + Tests เสร็จ 2026-11-12 (Commit ตามที่ผู้ใช้สั่ง ก่อนตรวจบน Emulator ครบ) — ยังไม่ได้รายงาน P5b**
  · deps `flutter_map` 8.3, `latlong2`, `geolocator` 14, `image_picker` 1.2 · `AndroidManifest`: `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION` (ไม่มี background, ไม่ประกาศ CAMERA)
  · `lib/features/road/`: `domain/road_models.dart` (freezed: `Incident`, `IncidentList`, `OwnReport`, `MyConfirmation`, `ReportCreated` + `IncidentDetail`, `NewReport`, `ReportPhoto`, `RoadBounds` ปัดออก 3 ตำแหน่ง + `tooLarge` > 2°) · `data/road_repository_impl.dart` (multipart `FormData`, รูปเป็น bytes ผ่าน dio ที่มี Token) · `data/device_services.dart` (`LocationService` → `LocationFound`/`LocationMissing(serviceDisabled|denied|deniedForever|unavailable)`, `PhotoPicker` ย่อ 1600 px คุณภาพ 85) · `presentation/road_providers.dart` (`roadDataRevisionProvider`, `currentLocationProvider` ถามเมื่อเปิดหน้า Road เท่านั้น, bbox/nearby/detail/รูป/รายงานของฉัน, `ReportFormController`, `ConfirmationController`)
  · หน้าจอ (root navigator, ไม่มีแท็บ): `/road` (`RoadScreen`: แท็บ แผนที่ = Marker ตาม bbox debounce 400 ms + จุดตำแหน่งฉัน + ป้ายจำนวน/ซูมเข้า/ถูกตัด/Error + ปุ่มตำแหน่งฉัน · ใกล้ฉัน = รัศมี 2 กม. เรียงใกล้สุด + ระยะทาง + หน้าจอแก้สิทธิ์ตำแหน่ง/เปิดการตั้งค่า · FAB "รายงานเหตุ" → SnackBar ส่งแล้ว/รวมกับเหตุเดิม + "ดู") · `/road/report` (หมวด 5, ตำแหน่ง GPS หรือปักหมุด, รูปจากกล้อง/คลังภาพ ≤ 5 MB, รายละเอียด ≤ 500; `already_reported` → ปุ่ม "เปิดเหตุนี้") · `/road/pick-location` (หมุดกลางจอ, `extra` = จุดเริ่ม) · `/road/incidents/:id` (สถิติรวม, แผนที่เล็ก, ยังอยู่/คลี่คลายแล้ว + คำตอบของฉัน, รายงาน + รูปของฉัน, "AI แนะนำ: … (xx%)" + `ค่าประมาณ` / < 0.6 "AI ไม่แน่ใจ" / pending) · `/road/my-reports` · การ์ด "เหตุบนถนนใกล้คุณ" หน้าหลัก (ไม่ขอสิทธิ์ตำแหน่ง)
  · ป้ายสถานะ: unverified "รอผู้รายงานเพิ่ม", corroborated "มีผู้รายงานหลายคน", resolved "คลี่คลายแล้ว", expired "หมดอายุ", rejected "ผู้ดูแลนำออก" · ไม่มีคำว่า "ยืนยันแล้ว"/"Real-time" (มี Test) · หมายเหตุ "รายงานโดยไรเดอร์ ไม่ได้ตรวจสอบโดย RiderOS…" ทุกหน้า · Attribution "© OpenStreetMap contributors" ทำเอง (`OsmAttribution`) เพราะของ flutter_map ล้นในแผนที่แคบ · `mapTilesEnabledProvider` (Test ปิด tiles)
  · Core: `ApiFailure.details` + `detail(key)` (อ่าน `incident_id` ของ `already_reported`) · `AuthInterceptor` Retry หลัง Refresh ส่ง `FormData.clone()` (FormData ส่งซ้ำไม่ได้) · Error code + ข้อความไทย 6 ตัวของ Road
  · Tests: `test/helpers/road_fakes.dart` (`RoadFakes` = repo + location + photos; `fakeRepositories(..., road)` ตำแหน่งที่ 6) · `test/widget/road_screens_test.dart` 31 · `test/unit/features/road_test.dart` 18 · `navigation_test.dart` +1 (การ์ด → แผนที่ → รายงาน → SnackBar อยู่บน RoadScreen → รายละเอียด → กลับ) · `auth_interceptor_test.dart` +1 · กดปุ่มบนแผนที่ใน Test ด้วย `tester.tap` ตรงๆ (`tapKey`/`ensureVisible` เลื่อน TabBarView)
  · ผล: `flutter analyze` No issues · `flutter test` **478 passed** (+51)
  · ตรวจบน Emulator แล้วแค่: การ์ดหน้าหลัก, Dialog สิทธิ์ตำแหน่ง, แผนที่ OSM โหลด + ป้าย "0 เหตุในบริเวณนี้" (APK ที่ลงไว้ยังเป็นรุ่นก่อนแก้ Attribution: เห็น "© ©" ซ้ำ + ทับปุ่ม FAB — แก้ในโค้ดแล้ว ยังไม่ได้ดูซ้ำ)
- **P5b ตรวจบน Emulator ครบ 2026-11-12 (Profile APK, `emulator-5554`, บัญชี `p3b.check@example.com`) — Commit `a113abf` ตามที่ผู้ใช้สั่ง**
  · ผ่าน: Attribution "©" ตัวเดียว ไม่ทับ FAB · รายงานน้ำท่วม + รูปจากคลังภาพ (Android Photo Picker) → Marker + SnackBar → รายละเอียด + รูปของฉัน · ไฟล์บน Server = JPEG 717×1600 ไม่มี EXIF ชื่อ UUID (ต้นฉบับ PNG 1280×2856) · ปุ่มถ่ายรูปเปิดแอปกล้อง (`CaptureActivity`) ได้โดยไม่ประกาศ CAMERA และรูปกลับมาที่ฟอร์ม · รายงานซ้ำ → แถบ `already_reported` + "เปิดเหตุนี้" · ยังอยู่ → คลี่คลายแล้ว (คำตอบใหม่แทนของเดิม) · ใกล้ฉัน เรียงตามระยะ (0 ม./110 ม.) · รายงานของฉัน ("มีรูป") · Dialog สิทธิ์มีแค่ "ขณะใช้งาน/ครั้งนี้/ไม่อนุญาต" · ปฏิเสธ → ใกล้ฉันแสดง "เปิดการตั้งค่า" · ฟอร์มปักหมุดเอง → พิกัดใน DB ตรงกับที่ปัก (13.75567, 100.50257) · บัญชีที่ 2 (สร้างทิ้งผ่าน API) → รวมเหตุ `corroborated` แอปแสดง "มีผู้รายงานหลายคน" → แจ้งคลี่คลาย 2 คน → `resolved` แผนที่ไม่แสดงแล้ว หน้ารายละเอียดแสดง "เหตุนี้ปิดแล้ว" · ตอบเหตุที่ปิดแล้ว → 409 `incident_closed` · `DELETE /me` บัญชีที่ 2 → 204 + ตัวนับกลับเป็น 1/1 · Dark mode แผนที่/รายละเอียด/ฟอร์ม
  · แก้ Bug 2 จุดที่เจอ (มี Test ที่ล้มก่อนแก้): (1) SnackBar "ส่งรายงานแล้ว" ตามไปทับหน้ารายละเอียด/ฟอร์มเมื่อเปิดเหตุจาก Marker (ทับปุ่ม "เปิดเหตุนี้" จนกดไม่ได้) → `RoadScreen` มี `ScaffoldMessenger` ของตัวเอง · (2) ปฏิเสธสิทธิ์ตำแหน่งครั้งแรกแล้ว Dialog เด้งซ้ำทันที เพราะ Dialog ทำให้แอป pause/resume แล้ว `onResume` ถามใหม่ → ถามใหม่ตอน Resume เฉพาะ `deniedForever`/`serviceDisabled` (`denied` มีปุ่ม "อนุญาต" อยู่แล้ว) · Tests +3 (`navigation_test` 1, `road_screens_test` 2) → **481 passed**, analyze No issues
  · ข้อมูลทดสอบใน Dev DB ของ `p3b.check@example.com`: 4 เหตุ (น้ำท่วม resolved, ถนนชำรุด/สิ่งกีดขวาง/อุบัติเหตุ unverified) + รูป 1 ไฟล์
- **P5c ทำไปครึ่งทาง 2026-11-12 (โค้ด + Tests เสร็จ · ยังไม่ได้ Train · Commit ตามที่ผู้ใช้สั่งเพื่อไปต่อ Session ใหม่)**
  · **License gate ผ่าน** (รายละเอียด + SHA-256 + Provenance ใน `cv_service/data/SOURCES.md`): RDD2022 = CC BY 4.0 (figshare API record ทางการ `10.6084/m9.figshare.21431547.v1`) · AlleyFloodNet = CC BY 4.0 (Kaggle `seonyseony/alleyfloodnet`) · Flood10k = CC BY-NC 4.0 (Mendeley; ภาพรวบรวมจาก Twitter/Google → License คุ้มแค่ชุดรวม) · torchvision BSD · ImageNet weights = เงื่อนไข ImageNet (Non-commercial) · Dependencies ใน image `rideros-cv` permissive ทั้งหมด ไม่มี GPL/AGPL → **โมเดลถือเป็น Non-commercial** เหมือนโมเดล Pickup
  · ผู้ใช้เลือก (2026-11-12): ใช้ทั้ง AlleyFloodNet + Flood10k (เฉพาะ `flooded`) · ผู้ใช้โหลด zip AlleyFloodNet จาก Kaggle เอง (ไม่เก็บ Token)
  · `cv_service/` (uv project แยก, `package = false`): torch 2.15.0 + torchvision 0.29.2 จาก index `pytorch-cu132` บน Windows (Train บน RTX 3060 6 GB) / `pytorch-cpu` บน Linux (Docker) · `app/model.py` (MobileNetV3-Large + preprocessing ใช้ร่วม Train/Serve) · `app/classifier.py` (โหลด `model.pt` `weights_only=True`, ตรวจ `weights_sha256` + arch + release torch/torchvision, ≤ 40 MP, EXIF transpose) · `app/main.py` `POST /classify` (413/415/503), `GET /model` (metadata + `metrics.json` ตรงตัว), `/health` · `Dockerfile` (CPU, image 1.58 GB, user `app`, port 8100) + `.dockerignore` allow-list · compose service `cv` (ไม่ publish port, mount `cv_service/artifacts` → `/models:ro`, `CV_MODEL_DIR` default `/models/road_cv/1.0.0`)
  · `training/`: `download` (RDD2022 ดึงเฉพาะ 4 ประเทศด้วย HTTP Range จาก zip 13.3 GB + ตรวจ CRC-32 + Pin; Flood10k Pin = hash ที่ Mendeley ประกาศ; Alley = `--alley <zip>` แล้วต้อง **Pin hash ใน `training/sources.py` ก่อน** — `download` จะ fail closed พร้อมบอก hash) · `build` (label: RDD box D00/D10/D20/D40 = road_damage, ไม่มี box = other, box อื่นอย่างเดียว = ตัดทิ้ง · Alley non-flooding = other · dedupe dHash ≤ 3 bits · RDD split เป็นก้อน 25 เฟรมติดกัน · Alley ใช้ split ที่ผู้แต่งให้ · cap 3,000/คลาส แบ่งโควตาเท่ากันต่อแหล่ง เพราะ US/China มีแต่ damage · ย่อ 256 px → `data/interim/` + ชุด bench ≤ 1600 px 20/คลาส) · `train` (head 3 epochs → finetune ≤ 15 + cosine + early stop 4, เลือกตาม val macro-F1, AMP) · `evaluate` (ผ่าน `Classifier` ของ service บน CPU: accuracy, macro-F1, per-class, confusion matrix, baseline majority, แยกตามแหล่ง, coverage/accuracy ที่ threshold 0.6, latency 1 thread → `reports/1.0.0/` + copy `metrics.json` เข้า artifact)
  · Smoke run (cap 300, 1+1 epoch, ไม่รวม Alley) ผ่านครบ pipeline 1.4 นาที — **ผลไม่ใช่โมเดลจริง ลบทิ้งแล้ว**
  · ข้อมูลใน `cv_service/data/raw/` (gitignored, Pin แล้ว): `RDD2022_{China_MotorBike,Czech,India,United_States}.zip` + `Flood10k.zip` · RDD train: China_MotorBike dmg 1,934 · Czech dmg 1,072/empty 1,757 · India dmg 3,223/empty 3,921 · US dmg 4,805
  · Backend: `app/modules/road/classify.py` — รายงานมีรูป + ตั้ง `CV_SERVICE_URL` → `ai_status = pending` → BackgroundTask ส่ง JPEG ที่เก็บไว้ไป `/classify` → เขียน `ai_label`/`ai_confidence` (3 ตำแหน่ง)/`ai_model_version_id` · รุ่นโมเดลใหม่ลง `model_versions` จาก `GET /model` (metrics ตรงตัว, ไม่มี metrics → failed) · ทุกความผิดพลาด → `failed` ไม่กระทบ Report · ไม่เปลี่ยนหมวด/สถานะ · `pending` เกิน 10 นาที (`AI_PENDING_TIMEOUT`) อ่านเป็น `failed` · Settings `CV_SERVICE_URL`, `CV_TIMEOUT_SECONDS` · `httpx` ย้ายเป็น runtime dep · compose backend `CV_SERVICE_URL` default `http://cv:8100`
  · Tests: `cv_service` **33 passed** (ruff สะอาด) · Backend **390 passed** (+10 `tests/api/test_road_classify.py`), ruff สะอาด, Coverage `app/modules` 98% (`classify.py` 95%) · Mobile ไม่ได้แก้ (UI "AI แนะนำ" ทำไว้แล้วใน P5b)
  · ช่องว่างที่ผู้ใช้ทักระหว่าง Session: TrueProfit "รูปแบบการทำงาน" (K-Means Work Patterns, `GET /profit/patterns` ใน Architecture §4) **ยังไม่ได้ทำ** · Roadmap P2 ไม่ได้อยู่ใน Phase ใด · ติด MVP Freeze (Module 1–3 แก้ได้แค่ Bug) → ต้องให้ผู้ใช้ตัดสินใจก่อนทำ

- **P5c เสร็จ 2026-11-12 (Train + Evaluate + E2E) → Phase 5 Report → ผู้ใช้อนุมัติ Phase 5 + สั่ง Commit 2026-11-12**
  · AlleyFloodNet: ผู้ใช้โหลด `archive.zip` จาก Kaggle (67,114,993 bytes, SHA-256 `4378b0ab…cb0d1`) → Pin ใน `training/sources.py` + SOURCES.md · `download` ตรวจผ่านครบ 6 ไฟล์ (`data/raw/manifest.json`)
  · โครง zip จริงไม่ตรงที่คาด: `AlleyFloodNet/flood_train_/{flooded,non_flooded}` + `flood_test_/…` **ไม่มี val** (paper มี val 79/90 แต่ไม่อยู่ใน zip) · โค้ดเดิมจะติดป้าย `flooding` ทุกภาพ (`flood_train_` ขึ้นต้นด้วย flood) → แก้ `build._alley_label` อ่านจากโฟลเดอร์ชั้นในสุดแบบตรงชื่อ · `_alley_split` อ่านเป็น Token · `alley_val()` ย้าย ~15/85 ของ train ไป val ด้วย Hash คงที่ · Tests +5 (cv_service **38 passed**)
  · `build`: 8,826 ภาพ (train 6,106 / val 1,340 / test 1,380) · ทุกแหล่งมีครบทุก split · ซ้ำ 189 · ป้ายขัดกัน 6
  · `train`: 278 s บน RTX 3060 · เลือก finetune epoch 6 (val macro-F1 0.8831) · early stop epoch 10 · `git_commit` ใน metadata = `528477e-dirty` (Train ก่อน Commit ตัวแก้ Alley — ระบุใน model card)
  · `evaluate` (Test n = 1,380): Accuracy **0.8804** · Macro-F1 **0.8755** · Baseline คลาสส่วนใหญ่ 0.2717 · F1 flooding 0.981 / road_damage 0.806 / other 0.840 · Threshold 0.6 แสดง 91.4% ของภาพ แม่น 0.9136 · Latency host 1 thread median 19.4 / p95 24.9 ms · ใน Container `cv` median **16.5** / p95 **22.8** ms (60 ภาพ, `Classifier.classify`)
  · จุดอ่อน (ใน model card): US/China road_damage 100% = Shortcut (ประเทศนั้นมีแต่ภาพชำรุด) · ค่าที่ควรดูคือ Czech 0.60 / India 0.78 · ภาพแห้ง → flooding 14/520 (2.7%) · ไม่มีภาพไทย
  · `cv_service/reports/1.0.0/`: `metrics.json` + `confusion_matrix.png` (สร้างจาก `evaluate`) + `model_card.md` (เขียนจากตัวเลขจริง) · `artifacts/` ไม่ Commit
  · E2E: `docker compose up -d --build` → backend/cv/db healthy · `/health` cv = ok `road_cv/1.0.0` · รายงานน้ำท่วม + รูป AlleyFloodNet test ผ่าน API → `ai_status=done`, `flooding` 0.917, `model_versions` เพิ่ม `road_cv/1.0.0` · รายงานสิ่งกีดขวาง + รูปซอยแห้ง → `other` 0.989 · Emulator: "AI แนะนำ: น้ำท่วม (92%)" / "AI แนะนำ: อื่นๆ (99%)" + `ค่าประมาณ` (Emulator ค้างจอดำ → Cold boot ตาม memory)
  · ข้อมูลทดสอบเพิ่มใน Dev DB ของ `p3b.check@example.com`: 2 รายงานมีรูป (คำอธิบาย "P5c E2E test photo")
  · License ส่วนที่ 3 (Package ใน Image `cv`) ตรวจซ้ำใน Container ตรงกับ SOURCES.md §4: MIT/BSD/Apache-2.0/PSF ไม่มี Copyleft
  · อัปเดต: `DATASET_ANALYSIS.md` (ตาราง CV ✅) · `DEVELOPMENT_ROADMAP.md` (Exit criteria Phase 5 ✅ 3 ข้อ, รออนุมัติ) · `cv_service/README.md` (Alley split)
  · ผลตรวจ: Backend **390 passed** · Mobile `flutter analyze` No issues + **481 passed** · cv_service **38 passed** + ruff สะอาด · gitleaks `dir` (440 ไฟล์) + `git` → no leaks found · ไฟล์ที่ Commit ได้ไม่มี `data/raw`/`data/interim`/`artifacts`/`*.pt`

### 4.12 K-Means Work Patterns (TrueProfit "รูปแบบการทำงาน") — **เสร็จ 2026-11-12 · Commit `4622708` ตามที่ผู้ใช้สั่งหลังรับรายงาน · gitleaks `dir` (448 ไฟล์) + `git` → no leaks found**
ผู้ใช้ตอบแผน 9 ข้อ (ใน §4.2 ด้านล่าง) ว่า "เอาตามที่นายคิดว่าดีที่สุด ทำแล้วโมเดลแม่นยำที่สุด" → ทำตาม 9 ข้อ + ปรับ 3 จุดจากผล Benchmark (ข้อ 4 เดิมใช้ Silhouette อย่างเดียว ไม่พอ)
- K-Means ไม่มี Label → "แม่นยำ" วัดจาก Benchmark ข้อมูลสังเคราะห์ที่รู้กลุ่มจริง (`backend/scripts/evaluate_work_patterns.py` → `backend/reports/work_patterns_benchmark.json`, 6 สถานการณ์ × 30/60/150 ช่วง × 30 รอบ) **ไม่ใช่ความแม่นยำกับไรเดอร์จริง** (ไม่มีข้อมูลจริง)
- วิธี (`backend/app/modules/profit/patterns.py`): Feature = ชั่วโมงเริ่ม sin/cos (scale ร่วมให้วงกลมรวมหนัก 1 Feature) + ความยาว (standardize) + สุดสัปดาห์ (น้ำหนัก 0.5) · k = 2–4, `n_init=10`, seed คงที่ · ทุกกลุ่ม ≥ 3 ช่วง · แสดงกลุ่มเมื่อผ่านครบ 3 ด่าน: (1) Silhouette ≥ 0.25 (2) **Permutation test**: ชนะ Silhouette ของข้อมูลสลับคอลัมน์อิสระทุกชุดจาก 39 ชุด (p ≤ 0.025) (3) **Bootstrap stability**: ARI เฉลี่ย 20 รอบ ≥ 0.6
- การปรับจากแผนเดิม (ตัวเลขจาก Benchmark):
  · Silhouette อย่างเดียว → ข้อมูลสุ่มก็ "เจอกลุ่ม" เพราะ Flag สุดสัปดาห์แบ่งเสมอ → เพิ่ม Permutation test
  · น้ำหนักสุดสัปดาห์ 1.0 → เลือก k ถูก 35% (แตกกลุ่มตามวัน) · 0.5 → 95% · 0 → 97% แต่กลุ่มหลอก 8% และเสียข้อมูลวัน → เลือก 0.5
  · Null 19 ชุด (p ≤ 0.05) → ข้อมูลสุ่ม n=30/60 หลุด 13% → 39 ชุด
- ผล Benchmark สุดท้าย: กลุ่มหลอก (ข้อมูลสุ่ม/นิสัยเดียว) **1.7%** · ตรวจพบกลุ่มจริง **99.2%** · k ถูก **94.5%** · ARI กับกลุ่มจริง 0.96–1.0 (ยกเว้น "ดึกข้ามเที่ยงคืน + กลางวัน" n=30: k ถูก 63%, ARI 0.89; n=150: 100%, 0.99)
- กำไร/ชม. ต่อกลุ่ม = (รายได้ − ค่าใช้จ่ายที่ผูก Session) ÷ ชม. (ไมโครวินาทีแบบ calculator) ของ Session ที่มีรายได้ผูกเท่านั้น · Decimal · ไม่มี → null/"—"
- API: `GET /profit/patterns` (Schema `WorkPatterns`/`PatternGroup` · ป้ายเป็น Code ให้แอปแปลภาษา) · คำนวณใน threadpool + `lru_cache(256)` ตามชุด Session (ผลคงที่จาก seed) · Latency ใน Container ครั้งแรก 772 ms, ซ้ำ 13 ms
- Mobile: `domain/work_patterns.dart`, `ProfitRepository.patterns()`, `workPatternsProvider` (รีโหลดตาม `profitDataRevisionProvider`, ไม่ขึ้นกับช่วงที่ดู), `widgets/work_patterns_card.dart` ใต้กราฟแนวโน้ม · 3 สถานะ: แถบความคืบหน้า / "ยังไม่เห็นรูปแบบชัดเจน" / รายการกลุ่ม + ป้าย `ค่าประมาณ` + จำนวนช่วงที่ใช้คิด · Error อยู่ในการ์ดเอง
- E2E: Backend container rebuild → บัญชี Dev `patterns.check@example.com` (รหัส `patterns check 2026`, Seed ผ่าน API 37 ช่วง) → ok k=2 Silhouette 0.935 / null 0.752 / stability 1.0 · กำไร/ชม. 80.25 และ 128.24 ตรงกับคิดมือ · Emulator (profile APK) แสดงการ์ดตรง API · บัญชี `p3b.check` แสดงแถบ "1 / 30"
- ผลตรวจ: Backend **421 passed** (เดิม 390 + ใหม่ 31: unit 27, API 4) · ruff check + format สะอาด · Mobile `flutter analyze` No issues + **490 passed** (เดิม 481)
- Known: Latency ครั้งแรก ~0.6–1 s (CPU) · Cache อยู่ใน Process (หายเมื่อ Restart, ไม่แชร์ข้าม Worker) · ข้อมูลน้อย (30 ช่วง) กับนิสัยกะดึกข้ามเที่ยงคืน k อาจเกิน · ชื่อช่วงเวลา (เช้า/กลางวัน/เย็น/ดึก) ใช้ขอบตายตัว ค่าเฉลี่ยใกล้ขอบ (เช่น 10:59) อาจได้ชื่อข้างเคียง

### 4.13 Phase 6 QA (W12) — **อนุมัติแล้ว 2026-11-14** (แผน + การตัดสินใจ 10 ข้อ ผู้ใช้ยืนยันตามที่แนะนำ 2026-11-14 "เอาเลย")
ลำดับ: P6a Security Audit → P6b Performance + แก้ Bug → P6c Regression Suite + Docs + Phase 6 Report · รายงานหลังจบแต่ละช่วง · ห้าม Commit จนกว่าผู้ใช้สั่ง
1. ผลสแกน: แก้ High/Critical ทุกข้อ · ระดับต่ำกว่าจดเป็น Accepted risk พร้อมเหตุผล
2. รายการรหัสผ่านพบบ่อย 87 คำ → SecLists `10k-most-common.txt` (MIT) Commit ใน Repo
3. `X-Forwarded-For` ของ Rate limiter → Phase 7 (ยังไม่มี Reverse proxy) · บันทึกใน Audit
4. Performance: สคริปต์ `httpx` async ใน `backend/perf/` (ไม่ใช้ Locust) · 200 req/Endpoint ที่ Concurrency 1 และ 10 · User ที่ Seed ไว้ · Retry 429
5. เป้า p95 (Docker ในเครื่อง): CRUD/Summary < 300 ms · Pickup prediction < 500 ms · `/profit/patterns` (Cache) < 500 ms, ครั้งแรกรายงานแยก · ไม่ผ่าน → แก้ Index/Query
6. Known issues ที่แก้ใน P6b: Detail ไม่ Refresh `pending`→`done` (Poll) · "คลี่คลายแล้ว" ที่หมดอายุ · Marker clustering + แผนที่โหมดมืด → Phase 7 (เปลี่ยน Tile provider)
7. CI: `scripts/regression.ps1` ในเครื่องเท่านั้น · GitHub Actions → Phase 7 ตอนสร้าง Repo
8. Coverage gate = ค่าปัจจุบัน − 2%
9. Docs: แก้ `SYSTEM_ARCHITECTURE.md` §5 ให้ตรงของจริง · ใหม่ `SECURITY_AUDIT.md`, `PERFORMANCE.md`, `TESTING.md` · README → Phase 7
10. Exit criteria: §5 ผ่านทุกข้อหรือเป็น Accepted risk · ไม่มี High/Critical ค้าง · p95 วัดจริงผ่านเป้า · Regression script เขียว · Docs อัปเดต
- พบตอนวางแผน: Release build Android ยังเซ็นด้วย debug key → Phase 7 (Release APK)
- **P6a Security Audit — เสร็จ 2026-11-14 · Commit `e8e7c24` ตามที่ผู้ใช้สั่งหลังรับรายงาน · gitleaks `dir` (451 ไฟล์) + `git` → no leaks found** · รายละเอียดทั้งหมด: `docs/SECURITY_AUDIT.md`
  · สแกน: pip-audit (backend/ml/cv) 0 · osv-scanner `pubspec.lock` 0 · ruff `S` 15 จุด = False positive/Offline · gitleaks History no leaks · trivy Image: Critical 3 → 0, High ที่มีแพตช์ 57 → 0, เหลือ High 47 ที่ Debian ยังไม่มีแพตช์ (Accepted R-6)
  · แก้ F-1: `app/core/body_limit.py` จำกัด Body ตอนรับข้อมูล (JSON 256 KiB `MAX_JSON_BODY_BYTES`, Multipart 5 MB + 64 KiB) เพราะ FastAPI อ่าน Form ก่อน Auth · F-2: Base image `python:3.14.10-slim-trixie` + `apt-get upgrade` + ลบ pip ระบบ (backend + cv) · F-3: Deny-list รหัสผ่าน 84 → 2,114 (SecLists 10k ที่ยาว ≥ 8 ตัวอักษร ได้แค่ 2,087 รายการ)
  · Test ใหม่ `backend/tests/api/test_security_audit.py` (55): Inventory 56 Endpoints (Public 8 / ต้อง Login 48) + 401 ทุกตัว · Body limit 5 ตัว (Fail เมื่อถอด Middleware) · Log ไม่มี Password/Token/พิกัด
  · แก้ `SYSTEM_ARCHITECTURE.md` §5 ให้ตรงโค้ด (`limits` ไม่ใช่ slowapi, ไม่ใช้ Pydantic Strict mode, gitleaks ยังไม่อยู่ใน CI)
  · ผลตรวจ: Backend **476 passed** (เดิม 421) · ruff check/format สะอาด · Coverage `app/modules`+`app/core` 98% · `docker compose build` + up → backend healthy, `/ready` model ok, cv ok, Body 300 KB → 413
  · Gotcha: อย่ารัน pytest ของ backend 2 ชุดพร้อมกัน (ใช้ Test DB เดียวกันและ DROP ทิ้งตอนเริ่ม)
- **P6b Performance + แก้ Bug — เสร็จ 2026-11-14 · Commit `dd7f127` ตามที่ผู้ใช้สั่งหลังรับรายงาน · gitleaks `dir` (456 ไฟล์) + `git` → no leaks found** · รายละเอียดทั้งหมด: `docs/PERFORMANCE.md`
  · สคริปต์ `backend/perf/run.py` (`python -m perf.run`) + `backend/perf/compose.perf.yml` (ตั้งแค่ `RATE_LIMIT_ENABLED=false`) · Seed ไรเดอร์ชั่วคราวผ่าน API (132 ช่วงทำงาน/รายได้, 72 ค่าใช้จ่าย, 30 Pickup log, 3 Scenario, 5 รายงานถนน) แล้วลบด้วย `DELETE /me` · ผลดิบ `backend/reports/perf_p6b.json`
  · ผล (24 Endpoint × c=1/c=10 × 200 req = 9,600 req, Error 0): CRUD/Summary p95 สูงสุด 149.0 ms (< 300) · Pickup prediction c=10 p95 358.9 ms (< 500; ติด CPU ของ `ColumnTransformer` 11 ms/แถว + GIL, ~36 req/s) · `/profit/patterns` Cache c=10 110.5 ms · ครั้งแรก 621–660 ms (แยก) · ผ่านเป้าทั้งหมด จึงไม่แก้ Index/Query
  · แก้ F-P1: Argon2 hash/verify รันบน Event loop (Login บล็อกทุก Request ~70 ms) → `hash_password_async`/`verify_password_async` (`run_in_threadpool`) ใน Register/Login/Reset/`DELETE /me` · Test 2 ตัว (Fail เมื่อถอดการแก้)
  · Mobile cold start (Profile build, Emulator API 37, 10 รอบ): median 1,565 ms
  · แก้ Bug (a): หน้ารายละเอียดเหตุ `incidentDetailProvider` เป็น `StreamProvider` ถามซ้ำทุก 3 s (`aiPollInterval`) ขณะรูปของเรายัง `pending` ไม่เกิน 2 นาทีหลังรายงาน (`aiPollWindow`) · ถามพลาด → คงหน้าเดิมแล้วลองใหม่ · Timer ยกเลิกเมื่อออกจากหน้า
  · แก้ Bug (b): "คุณแจ้งว่าคลี่คลายแล้ว" ที่เก่ากว่า `last_reported_at` → Banner เตือน `roadConfirmMineClearedStale` + ปุ่มคลี่คลายไม่เป็นสถานะเลือก (กฎเดียวกับ Backend `created_at > last_reported_at`)
  · พบระหว่างตรวจบน Emulator + แก้: หลังตอบ ยังอยู่/คลี่คลาย หน้ารายละเอียดเด้งกลับบนสุด (Revision bump → Skeleton) → ใช้ `detail.keepingData` (แบบหน้า Shift) · Test ใหม่ Fail เมื่อถอดการแก้
  · ตรวจบน Emulator (บัญชี `patterns.check@example.com`): `docker compose pause cv` + `CV_TIMEOUT_SECONDS=120` (override ชั่วคราวใน scratchpad) → ส่งรายงานพร้อมรูปผ่าน API → หน้า Detail แสดง "AI กำลังดูรูปนี้" → `unpause` → เปลี่ยนเป็น "AI แนะนำ: อื่นๆ (99%)" เองภายใน ~8 s ไม่ต้องดึงรีเฟรช · ตอบคลี่คลาย → บัญชีที่ 2 (สร้างแล้วลบทิ้ง) รายงานซ้ำ → ดึงรีเฟรช → Banner ขึ้น, คลี่คลาย 0 คน → ตอบใหม่ → นับ 1 คน, ตำแหน่งเลื่อนไม่หาย · ข้อมูลทดสอบเหตุ `a3e6a123-…` ยังอยู่ใน Dev DB
  · ผลตรวจ: Backend **478 passed** · ruff check/format สะอาด · Coverage `app/modules`+`app/core` 98% · Mobile `flutter analyze` No issues · `dart format` สะอาด · `flutter test` **495 passed** (เดิม 490) · Coverage `lib/` (ไม่รวม generated/l10n) 96.7% (6,524/6,748)
  · Gotcha: `CV_TIMEOUT_SECONDS` สูงสุด 120 (เกินแล้ว Backend ไม่ Start) · Build Profile ครั้งแรกของ Session Fail แบบไม่มี Error ให้เห็น รันซ้ำผ่าน
- **P6c Regression + Docs — เสร็จ 2026-11-14 · Phase 6 อนุมัติแล้ว 2026-11-14 · Commit `3986b03` ตามที่ผู้ใช้สั่ง · gitleaks `dir` (458 ไฟล์) + `git` (37 Commits) → no leaks found** · รายละเอียด: `docs/TESTING.md`
  · `scripts/regression.ps1`: Backend (ruff check/format + pytest `--cov=app/modules --cov=app/core --cov-fail-under=96`) · ML + CV (ruff + pytest) · Mobile (analyze, `dart format` ของ lib/test/integration_test/test_driver, `flutter test --coverage` + Gate 94.7% ของ `lib/` ไม่รวม `*.g.dart`/`*.freezed.dart`/`lib/l10n/`) · `-E2E` เพิ่ม flutter drive · `-Skip`, `-FailFast` · Python รันด้วย `uv run --locked` · ทุกขั้นรันต่อแม้ Fail แล้วสรุปเป็นตาราง, Exit 1 ถ้ามี Fail
  · แก้ระหว่างทำ 2 จุด: (1) Shell เปิด `ml/.venv` ค้าง → `python` ไม่มี uv → สคริปต์เอา venv ออกจาก PATH ระหว่างรัน (คืนค่าตอนจบ) แล้วหา uv: `uv` → `python -m uv` → `py -3 -m uv` (2) PS 5.1 แปลง stderr ของ docker เป็น Error → ตัดสินจาก Exit code อย่างเดียว, Output ออก `Write-Host` (เก็บ Log ด้วย `*>` ได้)
  · ผล: **REGRESSION PASSED 14/14** (~4.5 นาที) · Backend 478 passed, Coverage 98.17% · ML 134 · CV 38 · Mobile 495, Coverage 96.68% · ทดสอบ Gate กลับด้าน (`-MobileCoverageGate 99`) → FAIL + Exit 1
  · Docs: ใหม่ `docs/TESTING.md` · Roadmap: Exit criteria Phase 6 + แยกหัวข้อ Phase 7 · SYSTEM_ARCHITECTURE โครงสร้าง Repo (`scripts/`, `.github/workflows/` = Phase 7)
  · Known: CV pytest มี Warning 1 ตัวจาก Library (`fastapi.testclient` ใช้ `httpx` ที่ Starlette ประกาศ Deprecated) ไม่ใช่โค้ดเรา

### 4.14 Trend: Moving Average + Linear Trend (TrueProfit) — **เสร็จ 2026-11-14 · Commit `b666e40` ตามที่ผู้ใช้สั่ง · gitleaks `dir` (461 ไฟล์) + `git` → no leaks found · ผู้ใช้ให้ตัดสินใจเอง ("แก้และคิดเอาเองละกัน") → ยกเว้น MVP Freeze เฉพาะงานนี้**
ที่มา: `PROJECT_PLAN.md` §3 เขียน "Trend (Moving Average / Linear Trend)" ไว้ แต่ที่ทำมีแค่ยอดรวมต่อช่วง (พบหลังอนุมัติ Phase 6 ตอนผู้ใช้ถามว่า AI ครบหรือยัง)
- ทิศทางที่ตัดสินใจ (ผู้ใช้มอบให้): ทำ Trend นี้ · **ไม่ทำ** Shift ML (ไม่มีข้อมูลรายกะ แหล่งไทยที่ผู้ใช้ส่งมาเป็นค่าสรุปทั้งหมด), Object Detection (P4 Optional), ค่าเริ่มต้นจากข้อมูลสาธารณะ (ยังไม่รู้ License) → จดเป็นข้อจำกัดใน README ตอน Phase 7 · ข้อมูลจำลองใช้ได้แค่ทดสอบระบบ/Demo ที่ติดป้าย ห้ามรายงานเป็นความแม่นยำจริง
- Backend `app/modules/profit/trend_analysis.py` (Pure) + `GET /profit/trends` เพิ่ม Field (ไม่ทำให้ Client เดิมพัง): ต่อจุด `net_profit_moving_average`, `net_profit_trend` · `analysis` {`status`, `moving_average_window`, `active_buckets`, `min_active_buckets`, `direction`, `slope_per_bucket`, `p_value`}
  · Span = Bucket แรกถึงสุดท้ายที่มีรายการ (Bucket ว่างข้างในนับ 0 · ก่อนเริ่มใช้แอปและหลังรายการล่าสุดไม่นับ) · MA ย้อนหลัง วัน 7 / สัปดาห์ 4 / เดือน 3 เฉพาะที่หน้าต่างอยู่ใน Span ทั้งหมด
  · OLS (`scipy.stats.linregress`) ต้องมี ≥ 4 Bucket ที่มีรายการ ไม่งั้น `insufficient_data` · `up`/`down` เฉพาะ p < 0.05 ไม่งั้น `flat` และไม่ส่งเส้น (เส้นเอียงที่ไม่มีนัยสำคัญอ่านเหมือนแนวโน้มจริง) · Test: ซีรีส์สุ่มไม่มีแนวโน้ม 400 ชุด → ขึ้น/ลงผิด < 9%
  · `scipy>=1.18` เป็น Dependency ตรง (ติดมากับ scikit-learn อยู่แล้ว)
- Mobile: `NetProfitChart` วาด MA (เส้นทึบ) + Trend (เส้นประ) ทับแท่งด้วย `LineChart` ใน `Stack` (เว้นครึ่งแท่งให้ตรงกลางแท่ง) · `TrendSummary` (Legend + ประโยค ขาขึ้น/ขาลง ฿x ต่อ{ช่วง} / ยังไม่เห็นแนวโน้มชัด / ต้องมีอย่างน้อย n + Badge `ค่าประมาณ` + "ไม่ใช่การพยากรณ์") · Server เก่าที่ไม่มี `analysis` → แสดงแท่งอย่างเดียว
- ตรวจ: API กับ Dev DB (`patterns.check` → flat, p 0.16–0.82) · Emulator Profile build: flat (MA อย่างเดียว) + บัญชีชั่วคราว `trend.check@example.com` รายได้เพิ่ม ~150/สัปดาห์ → "แนวโน้มขาขึ้น ฿147.06 ต่อสัปดาห์" เส้นตรงกลางแท่ง · Dark mode อ่านได้ · ลบบัญชีด้วย `DELETE /me` แล้ว (0 แถว)
- Tests: Backend unit `tests/unit/test_trend_analysis.py` (13) + API 2 ตัวใน `test_profit_reports.py` · Mobile model 1 + widget 5 (`true_profit_screen_test.dart` group "trend analysis")
- ผลตรวจ: `scripts/regression.ps1` **PASSED 14/14** · Backend **493 passed** (เดิม 478), Coverage 98.21% · ML 134 · CV 38 · Mobile analyze No issues, **501 passed** (เดิม 495), Coverage 96.74% (6,645/6,869)

### 4.15 Phase 7 Deploy & Portfolio (W13) — **อนุมัติแล้ว 2026-11-16 (P7a + P7c; P7b พัก)** · **แผน + การตัดสินใจ 12 ข้อ ผู้ใช้ยืนยันตามที่แนะนำ 2026-11-15 ("เอาตามที่แนะนำเลย")**
ลำดับ: P7a เตรียม Production ในเครื่อง → P7b Deploy จริง + Restore test + Release APK → P7c GitHub + CI + README + Resume + Phase 7 Report · รายงานหลังจบแต่ละช่วง · ห้าม Commit จนกว่าผู้ใช้สั่ง
1. Hosting: Oracle Cloud Always Free (ARM A1 4 OCPU/24 GB) · สำรอง VPS ~€4–5/เดือน (Hetzner) · ผู้ใช้สมัครบัญชีเอง · ตรวจ Build arm64 (torch, xgboost, PostGIS) ด้วย `docker buildx --platform linux/arm64` ใน P7a ก่อน
2. Domain/HTTPS: `api.<IP>.sslip.io` + Caddy (Let's Encrypt อัตโนมัติ) · เปลี่ยนเป็นโดเมนของผู้ใช้ได้ภายหลัง
3. Deploy: `git clone` บน Server ด้วย Deploy key (read-only) แล้ว Build บน Server · ไม่ใช้ Registry · Model artifacts ส่งด้วย `scp` เท่านั้น (ไม่อยู่ใน Repo/Image/Registry ตาม D4)
4. Backend 2 uvicorn workers + Rate limiter บน Redis
5. `X-Forwarded-For` เชื่อเฉพาะที่มาจาก Caddy
6. Forgot Password ใน Production ปิด (D5, `email_provider="none"`) · ตรวจว่าแอปแสดงข้อความเหมาะสม · README แจ้ง
7. Tiles: สว่าง = OSM (+ User-Agent ของแอป + Attribution ตาม Tile policy, R9) · มืด = CARTO `dark_all` · ตรวจเงื่อนไขการใช้ก่อน
8. Marker clustering: `flutter_map_marker_cluster` ถ้า License + เวอร์ชันเข้ากับ flutter_map ได้ ไม่งั้นเขียนเอง
9. Backup: `pg_dump` รายวันผ่าน cron เก็บ 7 ชุด + tar รูป RoadContext · Restore test 1 รอบ บันทึกใน `docs/DEPLOYMENT.md`
10. APK: keystore ที่ `%USERPROFILE%\.rideros\` + `key.properties` (gitignored) · ผู้ใช้ Backup keystore เอง · arm64 APK เดียว แจกผ่าน GitHub Release
11. GitHub: Repo Private ด้วย `gh` (ถามก่อนสร้าง) · Actions: Backend pytest + ruff, ML/CV tests ที่ไม่ต้องใช้ Dataset, Flutter analyze + test · เปิด Public หลังตรวจ (gitleaks ทั้ง History, Dataset, Artifacts, License) และผู้ใช้สั่งเท่านั้น
12. README 17 หัวข้อ: Overview, Features, Screenshots, Architecture, Tech stack, AI/ML models + metrics, Datasets & licenses + Meituan acknowledgement, Project structure, Getting started, Configuration, Testing, API docs, Deployment, Security, Performance, Limitations (Shift ML, Object Detection, Domain shift, Non-commercial), License & credits · Resume bullets ใช้เฉพาะตัวเลขที่วัดจริง · Non-commercial (Meituan + Flood10k CC BY-NC): ไม่มีโฆษณา/ส่วนเก็บเงิน

- **P7a เตรียม Production — เสร็จ + ผู้ใช้อนุมัติ + Commit `e196411` (2026-11-15)** · gitleaks `dir` (473 ไฟล์) + `git` (41 commits) → no leaks found · รายละเอียด + Runbook: `docs/DEPLOYMENT.md`
  · Backend: `rate_limit.py` เป็น async `limits.aio` · `RATE_LIMIT_STORAGE_URL` (`memory://` / `redis://` ผ่าน redis-py) · Store ล่ม → 503 `rate_limit_unavailable` (Fail closed) + `/ready` มี `rate_limit` · Production + `WEB_CONCURRENCY` > 1 + `memory://` → ไม่ Start · Dependency ใหม่ `redis>=6.4` (MIT) · Dev compose เพิ่ม `valkey` (Test ใช้ DB 15) · `regression.ps1` สั่ง `up db valkey`
  · `deploy/`: `compose.prod.yml` (Caddy IP คงที่ 172.30.0.10 → `FORWARDED_ALLOW_IPS`, network `internal` ไม่มีทางออก) · `Caddyfile` (HSTS, เฉพาะ `/api/v1/*`, Body 6 MB) · `db/Dockerfile` · `prod.env.example` · `backup.sh` · `restore_test.sh` · `restore.sh --yes` · `smoke_test.py` (stdlib, 15 checks, ลบบัญชีทดสอบเอง)
  · เปลี่ยนจากแผน 3 จุด: (1) `postgis/postgis` มีแค่ amd64 → Build เองจาก `postgres:18.7-trixie` + PGDG (PGDG มีแค่ PostGIS 3.7.0, Dev ยัง 3.6.4; ต้องลง `postgresql-18` คู่กันไม่งั้น `undefined symbol: heap_datum_check`) (2) ข้อ 7: CARTO hosted basemaps เป็นของ Enterprise เท่านั้นแล้ว → โหมดมืดใช้ `darkModeTileBuilder` กลับสี OSM บนเครื่อง (3) ข้อ 8: `flutter_map_marker_cluster` 8.2.2 ต้องการ `latlong2 ^0.9.1` (เราใช้ 0.10.1) → เขียน Cluster เอง `widgets/incident_clusters.dart` (Greedy ระยะ 48 px · แตะ → ซูมพอดีกลุ่ม · จุดเดียวกัน ≤ 25 m หรือซูมสุดแล้ว → Bottom sheet รายการ)
  · Release signing: `android/app/build.gradle.kts` อ่าน `android/key.properties` (gitignored) · Keystore `%USERPROFILE%\.rideros\rideros-upload.jks` สร้างแล้ว · ไม่มีไฟล์ → Release ไม่เซ็น · APK arm64 ทดสอบ Build + `apksigner` ผ่าน (URL ชั่วคราว `api.example.invalid`)
  · ผลตรวจ: Backend **500 passed** (เดิม 493) ruff สะอาด · Mobile analyze No issues, **507 passed** (เดิม 501) · Local prod stack: smoke 15/15, XFF ปลอมไม่มีผล, 2 Worker นับร่วม, backup/restore_test PASSED (+ ทดสอบกลับด้าน FAILED ถูกต้อง), Disaster drill ผ่าน · arm64 (QEMU) backend/cv/db ใช้งานได้
  · **Regression เต็มรอบหลัง Commit (2026-11-15, HEAD `36378fa`):** `REGRESSION PASSED: 14 step(s)` · Backend **500 passed** Coverage 98.17% (Gate 96) · ML **134 passed** · CV **38 passed** (1 `StarletteDeprecationWarning` จาก `fastapi.testclient`) · Mobile analyze No issues, **507 passed**, Coverage `lib/` 96.8% (6723/6945, Gate 94.7)
  · **ตรวจบน Emulator แล้ว (2026-11-15, debug APK x64, บัญชี `p3b.check@example.com`):** Seed เหตุทดสอบ 7 รายการผ่าน API (คำอธิบาย "P7a cluster check" · จุดเดียวกัน 2 + ใกล้ 2 + ไกล 3; ยังเปิดอยู่ใน Dev DB หมดอายุเอง) → ซูมเมือง: Cluster "4" + Marker เดี่ยว · แตะ Cluster → ซูมพอดีกลุ่ม แตกเป็น Cluster "2" + 2 Marker · แตะ Cluster จุดเดียวกัน → Bottom sheet "2 เหตุที่จุดนี้" → แตะแถว → หน้ารายละเอียด · `cmd uimode night yes` → Tile OSM กลับสีมืด, Marker/Cluster/FAB อ่านออก, Attribution แสดง · ข้อสังเกต (ไม่แก้): ป้าย "5 เหตุในบริเวณนี้" นับจาก bbox ที่โหลด (มีขอบเผื่อ) จึงอาจมากกว่า Marker ที่เห็นบนจอ
  · Docs: ใหม่ `DEPLOYMENT.md` · แก้ `SECURITY_AUDIT.md` (R-3, R-7, R-8 แก้แล้ว), `SYSTEM_ARCHITECTURE.md` (Rate limiting), `TESTING.md` (valkey, Test ใหม่)

- **P7b พักไว้ (2026-11-15)** ตามที่ผู้ใช้สั่ง: สมัคร Oracle ไม่ผ่าน → ทำ P7c ก่อน (รายละเอียด §4.2)
- **P7c GitHub + CI + README — การตัดสินใจที่ผู้ใช้เลือก (2026-11-15):** (1) Repo `rideros-ai` บัญชี GitHub ของผู้ใช้ **Public** ตั้งแต่ Push แรก (เปลี่ยนจากแผนข้อ 11 ที่ให้เริ่ม Private) → ต้องตรวจครบก่อน Push: gitleaks History + ไฟล์ใหญ่/Dataset/Artifacts + ข้อมูลส่วนตัว (2) โค้ด **MIT** + หมายเหตุว่า Model/Dataset เป็น Non-commercial (Meituan, Flood10k CC BY-NC; ImageNet weights) และไม่อยู่ใน Repo (3) README หลักภาษา**อังกฤษ** (docs/ ภาษาไทยคงเดิม) (4) GitHub Release APK **เลื่อนไป P7b** (ไม่มี Server จริง APK ใช้ไม่ได้) → README ใช้ Screenshots + วิธีรันในเครื่อง
  · CI `.github/workflows/ci.yml`: backend (PostGIS + Valkey service, ruff + pytest Gate 96) · ml + cv_service (ruff + pytest, ไม่มี Dataset → Test ที่ต้องใช้ข้ามเอง) · mobile (Flutter 3.47.0 analyze + format + test + Gate 94.7) · gitleaks History · ไม่มี E2E (ต้องใช้ Emulator → `regression.ps1 -E2E`)
  · ตรวจในเครื่องแบบเดียวกับ CI: Backend ตัด `test_real_artifact.py` → 498 passed, Coverage 98.17% · Clone ใหม่ (ไม่มี Dataset/Artifacts): ML 117 passed + 17 skipped, CV 38 passed
  · ไฟล์ใหม่ (ยังไม่ Commit): `.github/workflows/ci.yml` · `README.md` (อังกฤษ 16 หัวข้อ + สารบัญ; Overview อยู่หัวไฟล์ · ตัวเลขทุกตัวมีที่มา) · `LICENSE` (MIT, ผู้ถือลิขสิทธิ์ "Qcutedev" + หมายเหตุ Data/Model ไม่อยู่ใต้ MIT) · `docs/PORTFOLIO.md` (Resume bullets EN/TH + ที่มาตัวเลข) · `docs/screenshots/` 6 ภาพ (กว้าง 480 px รวม ~780 KB: home, profit, pickup_predict, shift_compare, road_map.jpg, login)
  · Screenshots: บัญชี Demo `demo.screens@example.com` (รหัส `demo screens 2026`) Seed ผ่าน API ด้วยสคริปต์ชั่วคราวใน Scratchpad (ไม่อยู่ใน Repo; ใช้ `perf.run.Api`) → 92 กะ 120 วัน, ร้าน "Demo Kitchen", 3 Scenario, 7 เหตุถนน "Demo report" · README ระบุว่าเป็นบัญชี Demo ข้อมูล Seed · ถ่ายจาก Emulator (Status bar demo mode) · ยังอยู่ใน Dev DB
  · ตรวจ History ก่อน Public: Pack 1.24 MiB, Blob ใหญ่สุด 174 KB (HANDOFF), ไม่มี csv/parquet/zip/jpg/pt/joblib/jks/pem · **พบข้อมูลส่วนตัว 2 จุด:** อีเมลผู้ Commit จริงในทั้ง 43 Commits และ Path ชื่อผู้ใช้ Windows ใน HANDOFF (History) → ผู้ใช้เลือกเขียน History ใหม่ → แก้แล้ว (§4.16)

- **P7c Push แล้ว (2026-11-16, ผู้ใช้สั่ง "ต่อ")**: Commit `a9f38e1` (P7c) → `gh repo create` **https://github.com/Qcutedev/rideros-ai** (Public) → Push `main` + Tag `mvp-freeze` · CI รอบแรกแดง: `astral-sh/setup-uv@v10` ไม่มี Major tag → Pin `v10.3.3` (`ci: …` Commit ถัดมา) · **CI รอบสอง เขียวทั้ง 5 Jobs** (~2.5 นาที): backend 498 passed + 2 skipped (ไม่มี Artifact), Coverage 98.17% · ml 117 passed + 17 skipped · cv 38 passed · mobile analyze สะอาด, 507 passed, Coverage 96.70% (7377/7629; บน Linux นับบรรทัดต่างจาก Windows 96.8% 6723/6945) · gitleaks no leaks

### 4.16 เขียน Git History ใหม่ก่อนเปิด Public (2026-11-16, ผู้ใช้เลือก)
เหตุผล: Repo จะเป็น Public ตั้งแต่ Push แรก แต่ทั้ง 43 Commits มีอีเมลส่วนตัวของผู้ใช้ และ HANDOFF ทุกเวอร์ชันมี Path ที่มีชื่อผู้ใช้ Windows
- วิธี: `git filter-branch` (ยังไม่มี Remote) · อีเมลผู้เขียน/ผู้ Commit → `213143510+Qcutedev@users.noreply.github.com` · ใน `docs/HANDOFF.md` แทน Path Python ของผู้ใช้ด้วย `%LOCALAPPDATA%\Python` (แทนแบบ byte ผ่าน Python เพราะ backslash ใน sed ถูกยุบ)
- ตรวจแล้ว: ทุก Commit ต่างจากเดิมแค่บรรทัดนั้นใน HANDOFF · ชื่อผู้เขียน วันที่ ข้อความ Commit เหมือนเดิม · ไม่เหลือชื่อผู้ใช้ Windows/อีเมลเดิมใน History · Tag `mvp-freeze` สร้างใหม่บน `4e03d2f` (ข้อความ + วันที่เดิม, Tagger noreply)
- `.gitleaksignore` อ้าง Fingerprint ที่มี Commit hash → แก้ `56526ee…` เป็น `2432b21…` (Token ปลอมใน Flutter test 3 จุดเดิม) · gitleaks `git` หลังแก้ → no leaks found
- สำรองก่อนแก้: `.git/history-before-rewrite-2026-11-16.bundle` (ไม่ถูก Push · กู้ได้ด้วย `git clone <bundle>`) · `git config user.email` ของ Repo นี้ตั้งเป็น noreply แล้ว
- **Hash ในเอกสารนี้ก่อนหัวข้อนี้เป็น Hash เดิม** → เทียบตามตาราง (รวม `git_commit` `528477e-dirty` ใน metadata/Model card ของ CV → ใหม่ `70a8ee9`)

| เดิม | ใหม่ | Commit |
|---|---|---|
| `a7fe027` | `4b6d5b3` | feat(ml): Phase 0-1 docs and pickup order-to-pickup ML pipeline |
| `5d7be02` | `dc8b2c9` | feat(backend): Phase 2 FastAPI backend, database and model serving |
| `98c6d70` | `de818ad` | docs: record Phase 2 commit in HANDOFF |
| `56526ee` | `2432b21` | feat(mobile): Phase 3 P3a-P3b Flutter app with Rider Green UI |
| `831d408` | `45ff3ee` | docs: record Phase 3 P3a-P3b commit in HANDOFF |
| `549c27b` | `bab232c` | feat(mobile): Phase 3 P3c-a Profile, rider profile form and account delete |
| `2993f50` | `a27251e` | docs: record Phase 3 P3c-a Profile commit in HANDOFF |
| `f76d050` | `641660d` | feat(mobile): Phase 3 P3c-b Pickup Intelligence screens |
| `70cf671` | `a04bfb4` | docs: record Phase 3 P3c-b Pickup commit in HANDOFF |
| `aed472f` | `ac006aa` | feat(mobile): Phase 3 P3c-c Shift Simulator screens |
| `2961f9a` | `e49aa16` | docs: record Phase 3 P3c-c Shift commit in HANDOFF |
| `e9c9434` | `5fd0bcc` | docs: record Phase 3 approval and Phase 4 start in HANDOFF |
| `cdb78ba` | `14b9467` | feat(mobile): animated brand intro and RiderOS launcher icon |
| `fa0ed11` | `f3f5b52` | docs: record brand intro and launcher icon commit in HANDOFF |
| `4a364e1` | `14204e6` | feat(mobile): ride intro instead of logo reveal, no splash icon |
| `3e5679d` | `f095fb3` | docs: record ride intro commit in HANDOFF |
| `cc2a8b9` | `5628b57` | feat(mobile): Phase 4 E2E journey, reset deep link, snackbar placement |
| `a1571ef` | `4e03d2f` | docs: record Phase 4 approval and MVP freeze in HANDOFF |
| `7da3bde` | `61b8a9a` | feat(mobile): brand emblem logo on auth screens, centred page header |
| `496ec75` | `633c06a` | docs: record brand logo commit in HANDOFF |
| `04bd24c` | `d8d7a84` | feat(backend): Phase 5 P5a RoadContext reports, map queries and dedup rules |
| `48565ce` | `11818db` | docs: record Phase 5 plan, decisions and P5a in HANDOFF |
| `0ad4950` | `1b2d9e8` | feat(mobile): Phase 5 P5b RoadContext map, nearby list, reports and incident detail |
| `b53aeb2` | `26d056a` | docs: record Phase 5 P5b mobile RoadContext in HANDOFF |
| `a113abf` | `c182e4f` | fix(mobile): P5b road snackbar and repeated location prompt |
| `29580cb` | `f26588c` | docs: record P5b emulator check and fixes in HANDOFF |
| `bd6bf0a` | `298a4b7` | docs: note P5b fix commit in HANDOFF |
| `3f46018` | `01f9cfc` | feat(cv): Phase 5 P5c cv_service pipeline and background photo classify |
| `528477e` | `70a8ee9` | docs: record P5c progress and next steps in HANDOFF |
| `6ca5769` | `4967999` | feat(cv): Phase 5 P5c trained road classifier, metrics and model card |
| `4cf1e1c` | `24365a0` | docs: record P5c results and Phase 5 approval in HANDOFF |
| `4622708` | `be135b0` | feat(profit): K-Means work patterns endpoint and TrueProfit card |
| `c15d8a6` | `97baf8f` | docs: record K-Means work patterns results in HANDOFF |
| `e8e7c24` | `f425b06` | feat(security): Phase 6 P6a security audit fixes |
| `8641bcc` | `2a5f445` | docs: record P6a security audit and P6b plan in HANDOFF |
| `dd7f127` | `b472229` | feat(perf): Phase 6 P6b performance baseline and bug fixes |
| `0f58d36` | `46e8e5f` | docs: record P6b results and commit in HANDOFF |
| `3986b03` | `7f58022` | feat(qa): Phase 6 P6c regression script and testing docs |
| `e402508` | `eb65f0d` | docs: record Phase 6 approval and P6c results in HANDOFF |
| `b666e40` | `36ee62c` | feat(profit): moving average and linear trend of net profit |
| `632d9ee` | `48f0172` | docs: record trend analysis results and commit in HANDOFF |
| `e196411` | `334583f` | feat(deploy): Phase 7 P7a production stack, shared rate limiter, map clusters |
| `36378fa` | `f16a2cf` | docs: record P7a approval and commit in HANDOFF |

### 4.2 Session ถัดไปเริ่มตรงนี้
**2026-11-16: ผู้ใช้อนุมัติ Phase 7 (P7a + P7c) และสั่ง Commit HANDOFF** · Repo Public https://github.com/Qcutedev/rideros-ai · CI เขียว · **P7b Deploy ยังพัก** (ไม่มีวิธีชำระเงินที่ Oracle รับ) → ถ้ากลับมาทำ: ทางเลือก Hugging Face Spaces + Neon (ต้องปรับ Deploy), VPS เสียเงิน (Hetzner, ใช้ `deploy/` ได้ทันที) หรือวิดีโอ Demo จาก Emulator ใส่ README · งานถัดไปเริ่มเมื่อผู้ใช้สั่งเท่านั้น · ย้ำผู้ใช้สำรอง Keystore + `key.properties` นอกเครื่อง · ห้าม Commit จนกว่าผู้ใช้สั่ง · ก่อน Commit: gitleaks ตาม §4.5

(เดิม) **2026-11-15: P7c งานในเครื่องเสร็จ (CI, README, LICENSE, PORTFOLIO, Screenshots · §4.15) ยังไม่ Commit → รอผู้ใช้:** (1) ~~ข้อมูลส่วนตัวใน History~~ **เขียน History ใหม่แล้ว 2026-11-16 (§4.16; Hash เปลี่ยนทั้งหมด)** (2) สั่ง Commit (3) แล้วจึงสร้าง Repo `rideros-ai` Public ด้วย `gh` → Push (รวม Tag `mvp-freeze`) → ดู CI จนเขียว แก้ถ้าแดง → Phase 7 Report (P7b ค้าง) · ก่อน Commit: gitleaks ตาม §4.5

**2026-11-15: P7a อนุมัติ + Commit `e196411` (§4.15) → Session หน้าทำงานค้างตามลำดับ:** (1) ~~Regression เต็มรอบ~~ **ผ่านแล้ว 2026-11-15 (§4.15)** (2) ~~ดู Cluster + แผนที่มืดบน Emulator~~ **ผ่านแล้ว 2026-11-15 (§4.15)** (3) **P7b พักไว้ก่อนตามที่ผู้ใช้สั่ง (2026-11-15)**: สมัคร Oracle ไม่ผ่าน (Oracle ไม่รับวิธีชำระเงินที่ผู้ใช้มี) · ทางเลือกที่ไม่ต้องใช้บัตร เผื่อกลับมาทำ: Hugging Face Spaces + Neon (ต้องปรับ Deploy) หรือรันในเครื่อง + `adb reverse` · ผู้ใช้ทำโปรเจกต์ไว้ใส่ Resume/GitHub → ทำ P7c ก่อน · (เดิม) P7b: รอผู้ใช้สมัคร Oracle Cloud + สร้าง VM ตาม `docs/DEPLOYMENT.md` §2 ข้อ 1–2 แล้วส่ง Public IP + SSH user → ผมทำ §2 ข้อ 3–5 ผ่าน SSH → Deploy, smoke test URL จริง, restore_test, ตรวจ IP จริงผ่าน XFF, Release APK ด้วย `API_BASE_URL` จริง, เติม `DEPLOYMENT.md` §8.2 (4) P7c · ย้ำผู้ใช้สำรอง Keystore + `key.properties` ไว้นอกเครื่อง · ห้าม Commit จนกว่าผู้ใช้สั่ง · ก่อน Commit: gitleaks ตาม §4.5

**(เดิม) 2026-11-14: Trend MA + Linear เสร็จ + Commit `b666e40` (§4.14) → ถัดไป: เสนอแผน + การตัดสินใจ Phase 7 ให้ผู้ใช้ยืนยันก่อนลงมือ** · ห้าม Commit จนกว่าผู้ใช้สั่ง · ก่อน Commit: gitleaks ตาม §4.5

**(เดิม) 2026-11-14: Phase 6 อนุมัติแล้ว + Commit `3986b03` (ผู้ใช้สั่ง · §4.13) → ถัดไป: Phase 7 Deploy & Portfolio (W13) เริ่มด้วยการเสนอแผน + การตัดสินใจ** · ห้าม Commit จนกว่าผู้ใช้สั่ง · ก่อน Commit: gitleaks ตาม §4.5
- ตรวจซ้ำทั้งหมด: `.\scripts\regression.ps1` (ต้องได้ REGRESSION PASSED 14 step(s))
- Phase 7: เริ่มด้วยการเสนอแผน + การตัดสินใจ (Release APK + Signing key นอก Repo, Deploy Backend + Restore test, GitHub Repo Private (D2) + Actions จาก `scripts/regression.ps1`, README 17 หัวข้อ, Resume bullets จากตัวเลขจริง, งานที่ยกมา: `X-Forwarded-For`, Rate limiter หลาย Worker, Marker clustering + Tile โหมดมืด)

**(เดิม) 2026-11-14: P6b เสร็จ + Commit `dd7f127` (§4.13) → Session ใหม่เริ่ม P6c** (ผู้ใช้สั่ง) · ห้าม Commit จนกว่าผู้ใช้สั่ง · ก่อน Commit: gitleaks ตาม §4.5
- ตรวจสถานะ: `git status` สะอาด · `docker compose up -d` (`/ready` model ok) · Backend **478 passed** · Mobile **495 passed**, Coverage `lib/` 96.7% (→ Gate = 94.7% ตามข้อ 8) · Backend Coverage 98% (→ Gate 96%)
- P6c ตาม §4.13 ข้อ 7–10: `scripts/regression.ps1` (Backend pytest + ruff, ML/CV pytest, Flutter analyze/format/test + Coverage gate = ค่าปัจจุบัน − 2%) · `docs/TESTING.md` · Phase 6 Report เทียบ Exit criteria ข้อ 10 แล้วรออนุมัติ · ห้ามเริ่ม Phase 7
- วัด Perf ซ้ำ: คำสั่งใน `docs/PERFORMANCE.md` §2.3 (อย่าลืม `docker compose up -d backend` หลังวัดเพื่อเปิด Rate limit กลับ)

**(เดิม) 2026-11-14: P6a เสร็จ + Commit `e8e7c24`**
P6a เสร็จ (§4.13) → Session ใหม่เริ่ม P6b (ผู้ใช้สั่ง) · ห้าม Commit จนกว่าผู้ใช้สั่ง · ก่อน Commit: gitleaks ตาม §4.5
- P6b ตามการตัดสินใจ §4.13 ข้อ 4–6:
  1. `backend/perf/` สคริปต์ `httpx` async: Seed User ผ่าน API (Retry 429 · Rate limit 60/นาที/User → ใช้หลาย User หรือรัน Stack ด้วย `RATE_LIMIT_ENABLED=false` แล้วระบุในรายงาน) · 200 req/Endpoint ที่ Concurrency 1 และ 10 · p50/p95/p99 → `docs/PERFORMANCE.md` (ระบุเครื่อง, Docker, จำนวนข้อมูล)
  2. เป้า p95: CRUD/Summary < 300 ms · Pickup prediction < 500 ms · `/profit/patterns` (Cache) < 500 ms + ครั้งแรกแยก · ไม่ผ่าน → แก้ Index/Query แล้ววัดซ้ำ
  3. Mobile cold start: Profile build + `adb shell am start -W` (TotalTime) หลายรอบ
  4. แก้ Bug: (a) หน้า Detail ของรายงาน Poll จนกว่า `pending` → `done`/`failed` (b) "คุณแจ้งว่าคลี่คลายแล้ว" ต้องไม่แสดงเมื่อคำตอบเก่ากว่า Report ล่าสุด (กฎ Backend) · มี Test ทั้งคู่ + ตรวจบน Emulator
  5. รายงาน P6b แล้วรอ → P6c (`scripts/regression.ps1`, Coverage gate, `TESTING.md`, Phase 6 Report)

**(เดิม) 2026-11-12: K-Means Work Patterns เสร็จ + Commit `4622708` (§4.12) → ถัดไป: เสนอแผน Phase 6 QA (W12)**

**(เดิม) 2026-11-12: Phase 5 อนุมัติแล้ว + Commit (ผู้ใช้สั่ง) → K-Means Work Patterns**
- ผู้ใช้ตอบ Phase 5 Report: (1) อนุมัติ (2) K-Means Work Patterns = ทำ (3) Commit
- **แผน K-Means 9 ข้อ — ผู้ใช้ตอบ 2026-11-12 "เอาตามที่นายคิดว่าดีที่สุด ทำแล้วโมเดลแม่นยำที่สุด"** (ผลและสิ่งที่ปรับ: §4.12)
  · ขอบเขต: Backend `GET /profit/patterns` (SYSTEM_ARCHITECTURE §4) + การ์ด "รูปแบบการทำงาน" ในหน้า TrueProfit (`mobile/lib/features/profit/presentation/true_profit_screen.dart`) ไม่เพิ่มแท็บ
  1. ข้อมูล: `work_sessions` ย้อนหลัง 180 วัน · ต้อง ≥ 30 ช่วง (Roadmap) · ไม่ถึง → `insufficient_data` + `{have, need}`
  2. Feature จัดกลุ่ม = เวลาเท่านั้น: ชั่วโมงเริ่ม (sin/cos 24 ชม.), ความยาว (ชม.), วันธรรมดา/สุดสัปดาห์ · ไม่ใช้กำไร (รายได้หลายรายการไม่ผูก Session)
  3. กำไร/ชม. ต่อกลุ่ม = (รายได้ − ค่าใช้จ่ายที่ผูกกับ Session ในกลุ่ม) ÷ ชม. ของ Session ที่มีรายได้ผูก · ป้าย `ค่าประมาณ` + บอกจำนวน Session ที่ใช้คิด · ไม่มี → "—"
  4. k = 2–4 เลือกด้วย Silhouette · `StandardScaler` · `random_state` คงที่, `n_init=10` · Silhouette ดีสุด < 0.25 → "ยังไม่เห็นรูปแบบชัดเจน"
  5. คำนวณตอนเรียก ไม่เก็บโมเดล ไม่ลง `model_versions` · ใช้ scikit-learn 1.9.1 ที่มีใน backend แล้ว
  6. ชื่อกลุ่มจากกฎตายตัว (ไม่ใช้ AI แต่งคำ) เช่น "เย็น · สั้น ~3 ชม. · วันธรรมดา" · เช้า/กลางวัน/เย็น/ดึก ตามเวลาไทย · ข้ามเที่ยงคืนนับตามเวลาเริ่ม (DATABASE_DESIGN §3.7)
  7. UI: การ์ดแสดงแต่ละกลุ่ม (ชื่อ, จำนวนช่วง + สัดส่วน, ชม.เฉลี่ย, กำไรสุทธิ/ชม.) · ข้อมูลไม่พอ → แถบความคืบหน้า "บันทึกช่วงทำงานอีก n ครั้ง"
  8. Tests: Unit ข้อมูลสังเคราะห์ (2 กลุ่มชัด → เจอ 2; สุ่ม → ไม่ชัดเจน) · API `insufficient_data` + Cross-user · Mobile Widget tests การ์ด
  9. ยกเว้น MVP Freeze เฉพาะงานนี้ตามที่ผู้ใช้สั่ง (บันทึกแล้วที่นี่)
  · จบงาน → รายงาน (Completed / Files / Decisions / Tests / Known issues / Next) แล้วรอ · ต่อด้วยแผน Phase 6 QA

**(เดิม) 2026-11-12: P5c ทำไปครึ่งทาง**
1. ตรวจสถานะ: `git status` (สะอาด ยกเว้น CRLF noise ใน `mobile/lib/l10n/*.dart`) · `docker compose up -d db` · `cd cv_service; python -m uv sync; python -m uv run pytest` (**33 passed**) · ไฟล์ใน `cv_service/data/raw/` ยังอยู่ (5 zip)
2. **ต้องได้ zip AlleyFloodNet จากผู้ใช้ก่อน** (Kaggle ต้องล็อกอิน; ดู `~/Downloads`) → `python -m uv run python -m training download --alley <zip>` → ครั้งแรกจะ fail พร้อม hash → ดูโครงสร้าง zip (`build._alley_items` คาดโฟลเดอร์ train/val/test + flooding/non-flooding; ไม่ตรงจะ `ValueError`) → Pin hash + bytes ใน `training/sources.py` + ตาราง SOURCES.md → รัน `download` อีกครั้งจนผ่าน (เขียน `data/raw/manifest.json`)
   · ถ้าผู้ใช้ไม่อยากรอ: ทางเลือกคือ Train โดยไม่มี Alley (ต้องถามก่อน — คลาส other จะเหลือแค่ถนน RDD)
3. `build` → ดู `data/interim/build_summary.json` ว่าแต่ละแหล่งมีครบทุก split (Czech/India other ต้องอยู่ทั้ง val/test) → `train` (เบื้องหลัง, คาด 10–20 นาที) → `evaluate`
4. เขียน `cv_service/reports/1.0.0/model_card.md` จาก metrics จริง (ห้ามแต่งตัวเลข): Test metrics + baseline + แยกแหล่ง + threshold 0.6 + latency + ข้อจำกัด (ไม่มีภาพไทย, ภาพเว็บ, ไม่มีคลาสอุบัติเหตุ/ถนนปิด/สิ่งกีดขวาง → other, Non-commercial)
5. E2E: `docker compose up -d --build` → `/health` ของ cv = ok (exec ใน container) → Latency ใน container: `docker compose run --rm -v "./cv_service/data/interim/bench:/bench:ro" cv python -c ...` (ใช้ `training.evaluate.latency_ms` ไม่ได้เพราะ image ไม่มี `training/` → เขียน snippet เรียก `app.classifier.Classifier`) · รายงานพร้อมรูปผ่าน API → `ai_status = done` + แถว `model_versions` `road_cv/1.0.0` · ดูบน Emulator ว่า "AI แนะนำ: … (xx%)" + `ค่าประมาณ` ขึ้น
6. อัปเดต Roadmap/DATASET_ANALYSIS (ตาราง License CV ✅) → **Phase 5 Report** (Exit criteria Roadmap §Phase 5: CV License ยืนยัน + Metrics จริง + Latency) → รออนุมัติ · ห้ามเริ่ม Phase 6
7. แจ้งผู้ใช้อีกครั้งเรื่อง K-Means Work Patterns ที่ยังไม่ได้ทำ (§4.11) ใน Report — ให้ผู้ใช้ตัดสินใจว่าจะทำหลัง Phase 5 หรือไม่ (ติด MVP Freeze)
- ก่อน Commit ครั้งถัดไป: gitleaks ตาม §4.5 · `git diff --cached --name-only` ห้ามมี `cv_service/data/**` (ยกเว้น SOURCES.md) / `cv_service/artifacts/` / `*.pt`

**(เดิม) 2026-11-12: P5b ตรวจบน Emulator ครบ**
**2026-11-12: P5b ตรวจบน Emulator ครบ + แก้ Bug 2 จุด (§4.11) → รายงาน P5b แล้ว รอผู้ใช้สั่ง P5c (CV)** · Commit แล้ว `a113abf` (fix) + `29580cb` (HANDOFF) ตามที่ผู้ใช้สั่ง · gitleaks `dir` (411 ไฟล์) + `git` → no leaks found · ห้าม Commit จนกว่าผู้ใช้สั่ง
- P5c ตาม §4.11 ข้อ 8, 9, 10, 11: ตรวจ License Dataset ก่อน (RDD2022 + AlleyFloodNet/Flood10k) → `cv_service/` uv project แยก → Train MobileNetV3-Large → `POST /classify` → Background classify → แสดง "AI แนะนำ" (UI ทำไว้แล้วใน P5b) → Phase 5 Report แล้วรออนุมัติ

**(เดิม) 2026-11-12: P5b โค้ด + Tests เสร็จ**
**2026-11-12: P5b โค้ด + Tests เสร็จและ Commit แล้ว (§4.11) → Session ถัดไป: ตรวจ P5b บน Emulator ให้ครบ แล้วรายงาน P5b และรอสั่ง P5c** · ห้าม Commit จนกว่าผู้ใช้สั่ง
- ตรวจสถานะ: `git status` (สะอาด ยกเว้น CRLF noise ใน `mobile/lib/l10n/*.dart`) · `docker compose ps` + `/ready` · `flutter devices` เห็น `emulator-5554` · `flutter analyze` No issues · `flutter test` **478 passed**
- บน Emulator (`flutter build apk --profile` + `adb install -r`, `adb emu geo fix 100.5018 13.7563`, บัญชี `p3b.check@example.com`): Attribution ไม่ซ้ำ/ไม่ทับ FAB · ส่งรายงานพร้อมรูป (กล้อง/คลังภาพ; ตรวจ `image_picker` บน Android ว่าเปิดกล้องได้ไม่ต้องประกาศ CAMERA) → Marker + SnackBar → รายละเอียด + รูปของฉัน · รายงานซ้ำ → `already_reported` · ยังอยู่/คลี่คลายแล้ว · ใกล้ฉัน · ปฏิเสธสิทธิ์ตำแหน่ง → ปักหมุดเอง · รายงานของฉัน · Dark mode · ใช้บัญชีที่ 2 (สร้างทิ้งผ่าน API) ทดสอบ corroborated/resolved แล้วลบบัญชีทิ้ง
- แล้วรายงาน P5b (Completed / Files / Decisions ระหว่างทำ: ป้ายสถานะ unverified, การ์ดหน้าหลักไม่ขอสิทธิ์, หน้าเลือกตำแหน่งแยก, Attribution ทำเอง, SnackBar หลังรายงานอยู่บน RoadScreen / Tests / Known issues) → รอผู้ใช้สั่ง P5c
- ก่อน Commit ครั้งถัดไป: gitleaks ตาม §4.5

**(เดิม) 2026-11-12: Phase 5 แผนอนุมัติ (§4.11) · P5a Backend เสร็จ + Commit `04bd24c`**
**2026-11-12: Phase 5 แผนอนุมัติ (§4.11) · P5a Backend เสร็จ + Commit `04bd24c` → Session ถัดไป: P5b Mobile RoadContext แล้ว P5c CV + Phase 5 Report** · ห้าม Commit จนกว่าผู้ใช้สั่ง
- ตรวจสถานะ: `git status` (สะอาด ยกเว้น CRLF noise ใน `mobile/lib/l10n/*.dart`) · `docker compose up -d --build` (Image ต้องมี Migration 0004 + volume `road-images`) · `/ready` ok · `flutter devices` เห็น `emulator-5554` · `flutter test` **427 passed** · Backend **380 passed**
- P5b ตามข้อ 1, 3, 6, 7, 10 ใน §4.11: Route `/road` (การ์ด "เหตุบนถนนใกล้คุณ" ที่หน้าหลัก ไม่เพิ่มแท็บ) · `features/road/` (data/domain/presentation แบบ Pickup) · แผนที่ `flutter_map` + OSM (`userAgentPackageName`, Attribution) · รายการใกล้ตัว (`/road/incidents/nearby`) · ฟอร์มรายงาน (หมวด 5 อย่าง, `geolocator` ขณะใช้งาน + ลากหมุดเองได้, `image_picker` บีบอัด, คำอธิบาย ≤ 500) · หน้ารายละเอียด + ปุ่ม ยังอยู่/คลี่คลายแล้ว + "รายงานโดยผู้ใช้ · อัปเดตล่าสุด X นาทีที่แล้ว" (ห้าม "Real-time"/"ยืนยันแล้ว"; `corroborated` = "มีผู้รายงานหลายคน") · รายงานของฉัน + รูปของฉัน · Error codes: `already_reported` (details.incident_id → เปิดเหตุนั้น), `incident_closed`, `unsupported_image`, `image_too_large`, `image_storage_unavailable`, `invalid_bbox` · API ดู `backend/README.md` หัวข้อ RoadContext
- Android: สิทธิ์ `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION` + กล้อง/รูป · Emulator ตั้งตำแหน่ง: `adb emu geo fix 100.5018 13.7563`
- จบ P5b → รายงานแล้วหยุด รอสั่ง P5c


**2026-11-12: Phase 4 อนุมัติแล้ว + Commit `cc2a8b9` + Tag `mvp-freeze` (ผู้ใช้สั่ง) → Session ถัดไป: Phase 5 RoadContext AI (W10–W11)**
- MVP Freeze (ข้อ 9): Module 1–3 (Auth, TrueProfit, Pickup, Shift) แก้ได้เฉพาะ Bug ห้ามเพิ่ม Feature
- เริ่ม Phase 5 ด้วยการเสนอแผน + การตัดสินใจให้ผู้ใช้ยืนยันก่อน (แบบ Phase 4) · Exit criteria ใน Roadmap §Phase 5 · ลำดับตัด Scope: Object Detection → CV Classifier → (K-Means) → RoadContext ทั้ง Module · CV ต้องตรวจ License ของ Dataset ก่อน (Roadmap W11)
- ยังไม่ได้ตรวจ: `E2E_KEEP=1` (รอบที่รันถูกระบบหยุดเพราะหน่วยความจำเครื่องเหลือน้อย) · FPS ด้วย DevTools
- ผลตรวจตอน Commit: `flutter analyze` No issues · `dart format` สะอาด · `flutter test` **425 passed** · Coverage `lib/` (ไม่รวม generated/l10n) **97.1%** (5,371/5,534) · E2E 21/21 DB checks · gitleaks `dir` (383 ไฟล์) + `git` → no leaks found
- E2E ต้องมี: `docker compose up -d` (`/api/v1/ready` model ok) + `emulator-5554` · คำสั่งใน `mobile/README.md`

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
python -m uv run pytest --cov=app/modules   # 380 tests (~80 s) ต้องมี `docker compose up -d db`
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

## 7. Known issues

- ~~(P3b) SnackBar "บันทึกแล้ว" ลอยทับปุ่ม "+ เพิ่ม…"~~ · ~~(P3c-c) SnackBar "ลบแล้ว" ทับแถบเลือก Scenario~~ → แก้แล้วใน P4b (§4.9)
- (P3b) หลังแก้ 2 จุด (ป้ายจำนวนรายการ, ระยะขอบกราฟ) ยังไม่ได้ Screenshot ซ้ำบน Emulator (Tests ผ่าน)
- ~~(P5b) Marker ของเหตุต่างหมวดที่จุดเดียวกันซ้อนกันบนแผนที่ (ไม่มี Clustering)~~ → แก้แล้วใน P7a (§4.15): Cluster + รายการเมื่ออยู่จุดเดียวกัน
- ~~(P5b) คำตอบ "คลี่คลายแล้ว" ที่เก่ากว่า Report ล่าสุดยังแสดงเหมือนนับอยู่~~ → แก้แล้วใน P6b (§4.13)
- ~~(P5b) OSM tiles ไม่มีโหมดมืด~~ → P7a: กลับสีบนเครื่อง (`darkModeTileBuilder`) เพราะ CARTO ไม่ฟรีแล้ว · สีถนน/ป้ายเป็นแบบกลับสี ไม่ใช่ Style มืดที่ออกแบบมา
- (K-Means, §4.12) Work Patterns: Latency ครั้งแรก ~0.6–1 s · Cache ใน Process · ข้อมูลน้อยกับกะดึกข้ามเที่ยงคืน k อาจเกิน · Benchmark เป็นข้อมูลสังเคราะห์ ไม่ใช่ความแม่นยำกับไรเดอร์จริง
- (P5c) Image `rideros-cv` 1.58 GB (torch CPU) · ~~หน้า Detail ไม่ refresh เองตอน `pending` → `done`~~ → แก้แล้วใน P6b (Poll ทุก 3 s ไม่เกิน 2 นาที)
- (P6b) Pickup prediction ติด CPU ของ Process เดียว (~36 req/s, c=10 p95 359 ms) · P7a: Production 2 Worker + Rate limiter บน Valkey แล้ว (ยังไม่ได้วัด Perf ซ้ำบน Server)
- (P6b) ตัวเลข Perf/Cold start วัดบน Docker Desktop + Emulator ในเครื่องเดียว ไม่ใช่ Server/มือถือจริง

- Artifact 1.0.0 มี `git_commit: "no-commit"` (Train ก่อน Commit แรก) — Train ใหม่ได้ถ้าต้องการผูกกับ Commit (ผลจะเหมือนเดิมเพราะ seed=42)
- ร้านที่ไม่มีใน Train: MAE 7.24, Coverage 65.1% (215 orders) → Backend แสดงคำเตือนตาม `data_availability` แล้ว (P2c) และ `/pickup/model` ระบุใน `limitations`
- Backend image 1.03 GB (scikit-learn + xgboost + pandas) — ลดได้ภายหลังด้วย Multi-stage/ตัด pyarrow
- ~~Rate limiter อยู่ใน Memory ต่อ Process · ยังไม่เชื่อ `X-Forwarded-For`~~ → แก้แล้วใน P7a (Valkey + Trusted proxy = Caddy)
- Test run ไป Upsert/Activate แถว `model_versions` ใน Test DB (ไม่กระทบ Dev DB)
- Shift `historical` ใช้ค่าเฉลี่ยทั้งวันของ Session (ไม่แยกช่วงเวลาของวัน)
- ~~Lint เดิมใน `ml/src/`: E501 100 จุด + F401 1 จุด~~ → แก้แล้ว 2026-11-09: `ruff format` + ลบ import `numpy` ที่ไม่ได้ใช้; E501 ที่เหลือ 45 จุดเป็นข้อความ Report/Model card จึงใส่ `per-file-ignores` ใน `ml/pyproject.toml`; `ml/tests` 134 passed หลังแก้
- EDA เป็นรายงานจาก CLI ไม่ใช่ Notebook (บันทึกหมายเหตุใน Roadmap แล้ว)
- Data: Chronology ผิดปกติ 1 แถว (push > dispatch) และ 1 แถว (fetch > arrive); `estimate_meal_prepare_time = 0` มี 9,907 แถว
