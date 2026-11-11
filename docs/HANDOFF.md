# HANDOFF — RiderOS AI

> อัปเดตล่าสุด: 2026-11-11 · สถานะ: **Phase 3 กำลังทำ — P3a + P3b เสร็จ + ปรับ UI ตาม RIDEROS_UI_DESIGN.md (§4.4) (Commit แล้ว `56526ee`) · §4.1 + §4.3 ยืนยันแล้ว · **P3c ยังไม่เริ่ม — ผู้ใช้สั่งให้เริ่มใน Session ใหม่ที่ §4.2** · Phase 2 อนุมัติ + Commit แล้ว · การตัดสินใจ §3.1 P2a, §3.2 P2b, §3.3 P2c ยืนยันครบ
> Phase 0 + Decisions D1–D7 อนุมัติแล้ว (ดู `docs/PROJECT_PLAN.md` §4) · Git บน `main`: `a7fe027` (Phase 0–1) → `5d7be02` (Phase 2) → `56526ee` (Phase 3 P3a–P3b + UI) · ยังไม่มี Remote / ยังไม่ Push · Commit เฉพาะเมื่อผู้ใช้สั่ง

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
  · ยังไม่ได้ทำ: gitleaks (ทำตอนจบ Phase 3 ก่อน Commit) · Deep link `rideros://reset-password` (เลื่อนไป Phase 4 เพราะต้องทดสอบบน Emulator)
- **P3b (W7):** Home Dashboard · TrueProfit Dashboard · Income/Expense Management (Forms + Validation + States)
  → **เสร็จ 2026-11-10 (Commit `56526ee` · §4.3 ยืนยันแล้ว)** — เพิ่ม `fl_chart ^1.3.1` · Bottom navigation (`StatefulShellRoute.indexedStack`: หน้าหลัก + กำไร) · Feature ใหม่ `lib/features/profit/` (domain: `profit_records.dart`, `profit_summary.dart`, `profit_period.dart`, `session_times.dart`, `profit_repositories.dart` · data: `ApiRecordRepository<T, I>` generic + `ProfitRepositoryImpl` · presentation: `profit_providers.dart`, `true_profit_screen.dart`, `records_screen.dart`, ฟอร์ม income/expense/work-session, widgets) · `app/routes.dart` (แยก Routes ออกจาก router; `router.dart` export ต่อ) · `app/app_shell.dart` · Home ใหม่ (`features/dashboard/presentation/home_screen.dart`) · core: `utils/date_json.dart`, `utils/formatters.dart`, `utils/clock.dart`, `network/paged_result.dart`, Validators เพิ่ม `requiredDecimal`/`optionalInt`/`optionalText`/`max`
  · หน้าจอ: Home (วันนี้ + สัปดาห์นี้ + บันทึกด่วน), TrueProfit (วัน/สัปดาห์/เดือน, ย้อน/ถัดไป, สรุปละเอียด, กราฟแท่งกำไรสุทธิ), รายการทั้งหมด (3 แท็บ รายได้/ค่าใช้จ่าย/ช่วงทำงาน, Cursor pagination + โหลดเพิ่ม, Pull-to-refresh, DEMO chip), ฟอร์มเพิ่ม/แก้/ลบ 3 แบบ (ยืนยันก่อนลบ)
  · Tests **255 passed** (`flutter test`, ~15 s; เดิม 135 + ใหม่ 120: unit formatters/dates/models/validators/repository ผ่าน Fake HTTP/notifiers + widget ทุกหน้าและทุก Form + navigation รวม Full-stack `/profit/summary`) · Coverage `lib/` **96.2%** · `flutter analyze` No issues · `dart format` สะอาด
  · **ทดสอบบน Emulator กับ API จริง 2026-11-10**: Login → Home/TrueProfit แสดงตัวเลขตรง `/profit/summary` · แก้รายได้ 780→800 ผ่านแอป → DB = 800.00 และ Link ช่วงทำงานยังอยู่ · Dev DB มีบัญชีทดสอบ `p3b.check@example.com` (รหัส `p3b check pass`; ชื่อแสดงเป็น `????? P3b` เพราะ curl บน Windows แปลงอักษรไทยตอน Seed — ไม่ใช่บั๊กแอป)
- **P3c (W8):** Pickup Intelligence + Restaurant Details · Shift Simulator + Scenario Comparison · Profile/Settings

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

### 4.2 Session ถัดไปเริ่มตรงนี้
1. ตรวจสถานะ: `git status` (ต้องสะอาด · HEAD = Commit ที่บันทึก HANDOFF นี้ ต่อจาก `56526ee`) · `docker compose ps` (ถ้าหยุด → `docker compose up -d`) · `flutter devices` (ต้องเห็น `emulator-5554`; ถ้าไม่เห็น ให้ผู้ใช้เปิด Emulator จาก Android Studio → Device Manager) · `cd mobile; flutter analyze; flutter test` (ต้องได้ No issues + **261 passed**)
2. ~~ยืนยัน §4.1, §4.3~~ (ยืนยันแล้วทั้งคู่) · ถ้าผู้ใช้มีภาพ Mockup / ไฟล์ .docx ต้นฉบับของ UI ให้ขอมาเทียบก่อน (ไฟล์ .md ไม่มีภาพ — น่าจะหายตอนแปลงด้วย pandoc)
3. **เริ่ม P3c** ตามลำดับ: (a) Profile / Rider profile form / Account delete — ย้ายปุ่ม Logout ออกจาก AppBar ของ Home + เพิ่มแท็บ (b) Pickup Intelligence ทุกหน้า (c) Shift Simulator ทุกหน้า → แต่ละกลุ่ม: `dart format` + `flutter analyze` + `flutter test` + ดูบน Emulator แล้วรายงาน → Phase 3 Report → รออนุมัติ (ห้ามเริ่ม Phase 4 · ห้าม Commit จนกว่าผู้ใช้สั่ง)
   · หน้าใหม่ทุกหน้าต้องตาม `docs/RIDEROS_UI_DESIGN.md` §4.4–4.6 และใช้ Component ของ §4.4 ในไฟล์นี้ (`SectionCard`, `MetricTile`, `AppBadge` สำหรับ `ค่าประมาณ`/`Dataset`/`ร้านของฉัน`/ระดับข้อมูล, `LabeledField`, `SummarySkeleton`, `AppDestructiveButton` สำหรับลบบัญชี) · ห้ามแสดงตัวเลือก Shift `ml` · RoadContext ไม่มีแท็บ (Phase 5)
4. (P3b ใช้แล้ว) Widget ที่มี: `AsyncValueView` (Loading/Empty/Error/Data), `AppBanner`, `SubmitNotifier`, `Validators.optionalDecimal`, `DecimalConverter` · แทนที่ `features/dashboard/presentation/home_screen.dart` (ตอนนี้เป็นหน้าชั่วคราว) · ข้อความใหม่ใส่ใน `lib/l10n/app_th.arb` แล้ว `flutter gen-l10n` · Model ใหม่ → `dart run build_runner build`
5. รันแอปบน Emulator: `flutter run -d emulator-5554` (รันเบื้องหลังแล้ว Session หลุดได้ `Lost connection to device` แต่แอปยังเปิดอยู่) · Screenshot: `adb -s emulator-5554 exec-out screencap -p > <scratchpad>/x.png`
6. Test helper ที่ควรรู้: `test/helpers/pump.dart` (`pumpScreen`, `enter`, `tapKey`, `t` = ข้อความไทย), `fakes.dart` (`FakeAuthRepository`, `FakeRiderProfileRepository`), `profit_fakes.dart` (`ProfitFakes`, `FakeRecordRepository`, `testNow` = อ. 10 พ.ย. 2026 14:07), `pushScreen` (เปิดฟอร์มทับ Home เพื่อทดสอบ pop), `fake_http_adapter.dart` (Fake API สำหรับ dio) · `tester.pageBack()` หา Back button ไม่เจอ → ใช้ `tester.binding.handlePopRoute()`

**Exit criteria Phase 3:** ทุกหน้ามี Loading/Empty/Error/Success · ทุก Form มี Validation + Widget Test · Navigation Tests + Notifier/State Unit Tests · ไม่มีปุ่มที่ไม่ทำงาน (Feature ไม่พร้อม → ซ่อน) · `flutter analyze` ไม่มี Warning

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
