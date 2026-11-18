# Testing — RiderOS AI (Phase 6 · P6c)

> **อัปเดต 2026-11-18:** Test ของ Pickup ถูกลบไปพร้อมฟีเจอร์ (`docs/HANDOFF.md` §4.20) ตัวเลขด้านล่างที่เป็นของ Phase เก่ายังนับ Pickup อยู่

- การตัดสินใจที่ใช้: HANDOFF §4.13 ข้อ 7–8 (Regression script ในเครื่องเท่านั้น · GitHub Actions → Phase 7 · Coverage gate = ค่าปัจจุบัน − 2%)
- เอกสารนี้บอกว่ามี Test อะไรบ้าง รันอย่างไร และอะไรที่ยังต้องตรวจด้วยมือ · ผลสแกนความปลอดภัยอยู่ที่ `SECURITY_AUDIT.md` · ผลวัดความเร็วอยู่ที่ `PERFORMANCE.md`

## 1. รันทั้งหมดด้วยคำสั่งเดียว

```powershell
cd "C:\dev\RiderOS AI"
.\scripts\regression.ps1              # Backend + ML + CV + Mobile
.\scripts\regression.ps1 -Skip ml,cv  # ข้ามบางชุด (backend, ml, cv, mobile)
.\scripts\regression.ps1 -E2E         # เพิ่ม E2E บน emulator-5554 (ต้องเปิด Stack + Emulator ก่อน)
.\scripts\regression.ps1 -FailFast    # หยุดที่ขั้นแรกที่ Fail
```

- ทุกขั้นรันต่อแม้ขั้นก่อนหน้า Fail (ยกเว้น `-FailFast`) แล้วพิมพ์ตารางสรุป · Exit code 0 = ผ่านทุกขั้น, 1 = มีขั้นที่ Fail
- ต้องมี: Docker Desktop (Backend tests ใช้ Service `db` และ `valkey` ของ Compose — สคริปต์สั่ง `docker compose up -d --wait db valkey` เอง) · uv (บน PATH หรือ `python -m uv`; ถ้า `python` ชี้ venv ที่ไม่มี uv ให้ตั้ง `$env:RIDEROS_PYTHON` หรือ `-Python` เป็น Interpreter ที่มี uv) · Flutter บน PATH
- Python ทุกชุดรันด้วย `uv run --locked` → ถ้า `uv.lock` ไม่ตรง `pyproject.toml` จะ Fail แทนที่จะเขียน Lock ใหม่
- ถ้า Shell เปิด venv ค้างไว้ (เช่น `ml/.venv` ที่ไม่มี uv) สคริปต์จะเอา `Scripts` ของ venv ออกจาก `PATH` และล้าง `VIRTUAL_ENV` ระหว่างรัน (เหมือน `deactivate`) แล้วคืนค่าเดิมตอนจบ · หา uv ตามลำดับ: `uv` → `python -m uv` → `py -3 -m uv`
- Windows PowerShell 5.1 แปลง stderr ของคำสั่งภายนอก (Progress ของ docker/flutter) เป็น Error → สคริปต์ตัดสินผลจาก Exit code อย่างเดียว · Output ทุกบรรทัดออกทาง `Write-Host` จึงเก็บ Log ได้ด้วย `.\scripts\regression.ps1 *> regression.log`
- ห้ามรัน Backend pytest สองชุดพร้อมกัน: ใช้ Test DB `rideros_test` เดียวกันและ DROP ทิ้งตอนเริ่ม

### 1.1 ขั้นตอนในสคริปต์

| ชุด | ขั้น | ผ่านเมื่อ |
|---|---|---|
| backend | `ruff check .` · `ruff format --check .` | ไม่มีปัญหา |
| backend | `pytest --cov=app/modules --cov=app/core --cov-fail-under=96` | ทุก Test ผ่าน + Coverage ≥ 96% |
| ml | `ruff check .` · `ruff format --check .` · `pytest` | ไม่มีปัญหา + ทุก Test ผ่าน |
| cv | `ruff check .` · `ruff format --check .` · `pytest` | ไม่มีปัญหา + ทุก Test ผ่าน |
| mobile | `flutter analyze` | No issues |
| mobile | `dart format --output=none --set-exit-if-changed lib test integration_test test_driver` | ไม่มีไฟล์ที่ต้องจัดรูปแบบ |
| mobile | `flutter test --coverage` | ทุก Test ผ่าน |
| mobile | Coverage gate (คำนวณจาก `coverage/lcov.info`) | Line coverage ของ `lib/` ≥ 94.7% |
| e2e (`-E2E`) | `flutter drive … app_journey_test.dart -d emulator-5554` | Journey + SQL checks ผ่าน |

### 1.2 Coverage gate

| ชุด | ขอบเขต | ค่าที่วัดตอนจบ P6b | Gate |
|---|---|---|---|
| Backend | `app/modules` + `app/core` (Line + Branch ตาม `coverage.py`) | 98% | 96% (`-BackendCoverageGate`) |
| Mobile | `lib/` ไม่รวม `*.g.dart`, `*.freezed.dart`, `lib/l10n/` (Line) | 96.7% (6,524/6,748) | 94.7% (`-MobileCoverageGate`) |

- ไม่รวม Generated code (json_serializable, freezed, gen-l10n) เพราะไม่ได้เขียนเอง
- ML และ CV ไม่มี Coverage gate: Test ส่วนใหญ่ตรวจ Pipeline กับข้อมูล/โมเดลจริง และบางตัว Skip เมื่อไม่มีไฟล์ (§2.2–2.3) ตัวเลข Coverage จึงขึ้นกับเครื่องที่รัน
- ขึ้น Gate ได้เมื่อ Coverage สูงขึ้น · ห้ามลด Gate เพื่อให้ผ่าน

### 1.3 ผลล่าสุด (2026-11-18, Windows 11 · Docker Desktop จำกัด WSL 4 GB ด้วย `.wslconfig` · Branch `chore/remove-pickup` ต่อจาก `3f71bf2`)

| ชุด | ผล | เวลา |
|---|---|---|
| Backend | ruff สะอาด (102 ไฟล์) · **463 passed** · Coverage 98.23% (Gate 96%) | ~148 s |
| ML | ruff สะอาด (45 ไฟล์) · **134 passed** (มี Dataset + Artifact ในเครื่อง จึงไม่ Skip) | ~161 s |
| CV | ruff สะอาด (21 ไฟล์) · **38 passed** · Warning 1 ตัวจาก Library (`fastapi.testclient` → Starlette เตือนเรื่อง `httpx`) | ~24 s |
| Mobile | `flutter analyze` No issues · `dart format` 183 ไฟล์ไม่เปลี่ยน · **522 passed** · Coverage 96.86% (7,321/7,558, Gate 94.7%) | ~166 s |
| รวม | **REGRESSION PASSED: 14 step(s)** | ~8.5 นาที |

- Test ลดลงเพราะเอา Pickup ออก (HANDOFF §4.20): Backend 523 → 463, Mobile 591 → 522
- รอบก่อน (2026-11-18, Branch `feat/profit-heatmap`): Backend 523 · ML 134 · CV 38 · Mobile 591 (Coverage 97.09%) · ~8 นาที
- รอบก่อนนั้น (2026-11-18, Commit `52d8ab3`): Backend 504 · ML 134 · CV 38 · Mobile 571 (Coverage 96.95%) · ~9 นาที
- รอบก่อนนั้น (2026-11-14): Backend 478 · ML 134 · CV 38 · Mobile 495 (Coverage 96.68%) · ~4.5 นาที · รอบ 2026-11-18 นานขึ้นเพราะ Test เพิ่มและเครื่องเปิด VS Code + Docker ไว้ด้วย
- แรมเครื่องไม่พอ (Emulator ~3.7 GB + Android Studio ~1 GB เปิดค้าง) ทำให้รอบ 2026-11-17 ถูกหยุดกลาง Backend pytest → ปิด Emulator/Android Studio ก่อนรัน · รอบแรกของงาน Heatmap (2026-11-18) ก็ถูกหยุดแบบเดียวกันเพราะ Gradle daemon (`java` ~1.9 GB หลัง `flutter build apk`) ค้างอยู่ → `cd mobile\android; .\gradlew --stop` ก่อนรัน (แรมว่าง ≥ 5 GB)

- ตรวจว่า Gate Fail ได้จริง: `-Skip backend,ml,cv -MobileCoverageGate 99` → ขั้น `coverage gate` FAIL + Exit code 1

## 2. ชุด Test

### 2.1 Backend (`backend/tests/`, pytest + pytest-asyncio)

- Test DB: สร้าง `rideros_test` ใหม่จาก `TEST_DATABASE_URL` ใน `.env` ทุกครั้งที่รัน (ชื่อต้องลงท้าย `_test` ไม่งั้นหยุด) · ใช้ PostGIS ของ Compose `db`
- API tests ใช้ Artifact ปลอมขนาดเล็ก (`tests/fake_artifact.py`) · `tests/api/test_real_artifact.py` โหลด `ml/artifacts/pickup_o2p/1.0.0` จริงและ Skip ถ้าไม่มี
- Rate limit ปิดใน Test settings ยกเว้น `tests/api/test_rate_limits.py`

| กลุ่ม | ไฟล์ | ตรวจอะไร |
|---|---|---|
| Unit | `unit/test_config.py`, `test_security.py` | Settings, Argon2id, JWT |
| Unit | `unit/test_profit_calculator.py`, `test_shift_estimator.py`, `test_work_patterns.py` | สูตร TrueProfit, Shift estimator, K-Means work patterns (ข้อมูลสังเคราะห์: 2 กลุ่มชัด → เจอ 2, สุ่ม → ไม่ชัดเจน) |
| Unit | `unit/test_registry.py` | Model registry: Hash, Schema, Library version ก่อนโหลด |
| API | `test_auth.py`, `test_tokens.py`, `test_password_reset.py`, `test_profile.py` | Register/Login/Refresh rotation/Logout/Reset/ลบบัญชี |
| API | `test_trueprofit_crud.py`, `test_profit_reports.py`, `test_profit_patterns.py`, `test_shifts.py` | CRUD + Summary + Patterns + Scenario |
| API | `test_pickup.py`, `test_real_artifact.py` | Restaurant analytics, Prediction (ช่วง + คำเตือน), Pickup log, Model card |
| API | `test_road.py`, `test_road_classify.py` | RoadContext report/confirm/nearby/bbox, รูป, Background classify (CV ล่ม → `failed`) |
| ความปลอดภัย | `test_cross_user.py` | ผู้ใช้ A อ่าน/แก้/ลบข้อมูลของ B ไม่ได้ทุก Endpoint |
| ความปลอดภัย | `test_security_audit.py` | Inventory ทุก Route (Public/ต้อง Login) + 401 · Body limit · Log ไม่มี Password/Token/พิกัด |
| ความปลอดภัย | `test_rate_limits.py` | Register/Login/Forgot/Token เสีย ต่อ IP (Login ต่ออีเมลด้วย) · ค่าเริ่มต้นต่อ User · `/health` ไม่ถูกจำกัด |
| ความปลอดภัย | `test_rate_limit_storage.py` (P7a) | 2 App บน Valkey เดียวกัน (= 2 Worker) นับรวมกัน · Store ล่ม → 503 + `/ready` 503 · Production ไม่ยอม `memory://` กับหลาย Worker · `X-Forwarded-For` ใช้เฉพาะจาก Caddy (ต้องมี Compose `valkey`, `TEST_REDIS_URL` ค่าเริ่มต้น `redis://127.0.0.1:6379/15`) |
| Platform | `test_platform.py`, `test_migrations.py` | `/health`, `/ready`, Error envelope, 500 ไม่รั่วรายละเอียด, Request ID, Migration ตรง ORM (ไม่มี Drift) |

### 2.2 ML Pipeline (`ml/tests/`)

- ตรวจ Download/License, Validate, Build features, Conformal interval, Metrics, Artifact และ Reproducibility
- Marker: `data` (ต้องมี `ml/data/raw`), `artifact` (ต้องมี `ml/artifacts/pickup_o2p/1.0.0`) → Skip เมื่อไม่มีไฟล์ · `slow` = Reproducibility end-to-end (~1–2 นาที; ข้ามได้ด้วย `-m "not slow"`)
- Dataset และ Artifact ไม่อยู่ใน Git (License D1/D4) → เครื่องที่ Clone ใหม่จะ Skip ส่วนนี้ ต้องรัน `rideros-ml download` + `train` ก่อนถึงจะครบ

### 2.3 CV Service (`cv_service/tests/`)

- `test_api.py` (`/classify`, `/health`, `/model`, ไม่มีโมเดล → 503, ไม่ใช่รูป → 415, ใหญ่เกิน → 413, ปิด Docs) · `test_classifier.py` · `test_training.py` (หารูปซ้ำด้วย dHash, Group split 70/15/15 คงที่, Quota ต่อแหล่ง, Alley val, ไฟล์ที่ไม่ Pin hash → Fail)
- Marker `artifact`: ต้องมีโมเดลใน `cv_service/artifacts/` → Skip ถ้าไม่มี (Weights ไม่อยู่ใน Git)

### 2.4 Mobile (`mobile/test/`, flutter_test)

| กลุ่ม | ที่อยู่ | ตรวจอะไร |
|---|---|---|
| Unit | `test/unit/app/` | Router redirect (Guard), Brand logo |
| Unit | `test/unit/core/` | Config, Auth interceptor (Refresh single-flight), Failure mapper, Validators, Formatters/วันที่, Token manager |
| Unit | `test/unit/features/` | Repository + Notifier ของ Auth, Profile, Profit, Pickup, Shift, Road |
| Widget | `test/widget/*_screen(s)_test.dart`, `*_form_test.dart` | ทุกหน้ามี Loading/Empty/Error/Success · ทุก Form มี Validation |
| Navigation | `test/widget/navigation_test.dart` | Router จริง + Guard + dio เต็มชุดกับ Fake HTTP adapter |
| Helper | `test/helpers/` | `pump.dart` (`pumpScreen`, `scrollAndTap`, `t` = ข้อความไทย), Fake repositories ต่อ Feature, `fake_http_adapter.dart` |

- Test ที่ใช้ `RiderOsApp` ต้อง Override `brandIntroEnabledProvider` เป็น `false` ไม่งั้น Intro บังการแตะ

### 2.5 End-to-end (`mobile/integration_test/` + `mobile/test_driver/`)

- Journey: Register → Onboarding → Logout → Login → Dashboard → Pickup prediction `POI-203` → เพิ่มรายได้ → เพิ่มค่าใช้จ่าย → TrueProfit → 2 Scenario → Compare
- Host driver เทียบตัวเลขบนจอกับ SQL ผ่าน `docker compose exec db psql` แล้วลบบัญชี `e2e+<timestamp>@example.com` ด้วย `DELETE /me` · `$env:E2E_KEEP = "1"` เก็บบัญชีไว้
- ต้องมี: `docker compose up -d` (`/api/v1/ready` model ok) + `emulator-5554` · ใช้เวลา ~40 s หลัง Build · ไม่อยู่ในชุดปกติเพราะต้องมี Emulator (เปิดด้วย `-E2E`)

## 3. สิ่งที่ไม่อยู่ในสคริปต์ (รันแยก)

| งาน | ทำเมื่อ | วิธี |
|---|---|---|
| สแกนความปลอดภัย (pip-audit, osv-scanner, trivy, gitleaks, ruff `S`) | ก่อน Release / เปลี่ยน Dependency หรือ Base image | `SECURITY_AUDIT.md` §7 |
| gitleaks ก่อน Commit | ทุก Commit | `SECURITY_AUDIT.md` §7 (`dir` + `git`) |
| วัด Performance API | หลังแก้ Query/Index หรือ Endpoint ใหม่ | `PERFORMANCE.md` §2.3 (สคริปต์ Exit 1 ถ้า p95 เกินเป้า · อย่าลืมเปิด Rate limit กลับ) |
| Mobile cold start | ก่อน Release | `PERFORMANCE.md` §5 |
| ML train/evaluate | เปลี่ยน Feature/โมเดล | `ml/README.md` (`rideros-ml train` ~29 นาที) |
| CV train/evaluate | เปลี่ยนโมเดล CV | `cv_service/README.md` |

## 4. สิ่งที่ยังตรวจด้วยมือ

- ดูหน้าจอบน Emulator หลังแก้ UI (Light/Dark mode) · วิธีขับ Emulator ด้วย adb: HANDOFF §4.2 (ข้อ 4)
- แผนที่ RoadContext: Marker ซ้อน, Tile ไม่มีโหมดมืด (Known issues → Phase 7)
- Animation ของ Intro ต้องดูบน Profile build (Debug build กระตุกและช้า ~10 s)
- กล้อง/คลังภาพ (`image_picker`) และสิทธิ์ตำแหน่งบนเครื่องจริง

## 5. CI

- ยังไม่มี: Repo ยังไม่มี Remote (D2) · GitHub Actions ย้ายไป Phase 7 ตอนสร้าง Repo (HANDOFF §4.13 ข้อ 7)
- ตอนทำ CI: ขั้นใน §1.1 ใช้ได้ตรงๆ ยกเว้น Test ที่ต้องมี Dataset/Artifact ที่ไม่อยู่ใน Git (จะ Skip) และ E2E (ต้องมี Emulator)
