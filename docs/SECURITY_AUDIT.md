# Security Audit — RiderOS AI (Phase 6 · P6a)

> **อัปเดต 2026-11-18:** Endpoint `/pickup/*` ถูกลบแล้ว (`docs/HANDOFF.md` §4.20) ผล Audit ด้านล่างเป็นของตอนที่ยังมี Pickup

- วันที่ตรวจ: 2026-11-14 · Commit ฐาน `c15d8a6` + การแก้ใน P6a (ยังไม่ Commit)
- ขอบเขต: Backend (`backend/`), CV Service (`cv_service/`), ML Pipeline (`ml/`), Mobile (`mobile/`), Docker Compose, Git History
- เกณฑ์: Checklist ใน `SYSTEM_ARCHITECTURE.md` §5 + OWASP API Security Top 10 (2023)
- ทุกข้อต้องมีหลักฐานเป็น Test ที่รันผ่าน หรือตำแหน่งในโค้ด ถ้ายังไม่ผ่านต้องอยู่ใน "ความเสี่ยงที่ยอมรับ" (§5) พร้อมเหตุผล
- การตัดสินใจที่ใช้: HANDOFF §4.13 (แก้ High/Critical ทุกข้อ · ระดับต่ำกว่าจดเป็น Accepted risk)

## 1. สรุปผล

| เกณฑ์ | ผล |
|---|---|
| Checklist §5 (11 ด้าน) | ผ่าน 11/11 (ตรวจกับโค้ดจริง · บางข้อมีรายละเอียดต่างจากเอกสารเดิม → แก้ §5 แล้ว) |
| ช่องโหว่ Dependency (Python 3 โปรเจกต์ + Flutter) | 0 รายการ |
| ช่องโหว่ใน Docker image ระดับ Critical | 3 → **0** |
| ช่องโหว่ใน Docker image ระดับ High ที่มีแพตช์แล้ว | 57 → **0** |
| ช่องโหว่ใน Docker image ระดับ High ที่ Debian ยังไม่มีแพตช์ | 47 (Accepted · §5 R-6) |
| Secrets ใน Git History | ไม่พบ (gitleaks, 33 Commits) |
| ข้อบกพร่องที่พบและแก้ใน P6a | 3 (§4) |
| Backend tests | 476 passed (เดิม 421 · เพิ่ม 55 ใน `tests/api/test_security_audit.py`) · ruff สะอาด · Coverage `app/modules` + `app/core` 98% |

## 2. เครื่องมือสแกนอัตโนมัติ

| เครื่องมือ | เป้าหมาย | ผล |
|---|---|---|
| `pip-audit` 2.x (ผ่าน `uv tool run`) กับ `uv export --frozen` แบบมี Hash | `backend` (64 แพ็กเกจ), `ml` (40), `cv_service` (51) | No known vulnerabilities · `torch`/`torchvision` เป็น build `+cu132` ที่ไม่อยู่บน PyPI จึงตรวจเวอร์ชันฐาน `torch==2.15.0`, `torchvision==0.29.2` แยก → ไม่พบ |
| `osv-scanner` v2.2.4 (Docker) | `mobile/pubspec.lock` (159 แพ็กเกจ) | No issues found |
| `ruff --select S` (กฎของ bandit) | โค้ดที่ไม่ใช่ Test ทั้ง 3 โปรเจกต์ Python | 15 จุด · ทั้งหมดเป็น False positive หรือโค้ด Offline (§2.1) |
| `trivy` 0.67.2 (`--severity HIGH,CRITICAL`) | `rideros-backend`, `rideros-cv` | ก่อนแก้: แต่ละ Image มี Critical 3, High 104 (มีแพตช์ 57) · หลังแก้: Critical 0, High 47 (ไม่มีแพตช์ทั้งหมด) · แพ็กเกจ Python ใน `/opt/venv` = 0 |
| `gitleaks` v8.30.0 (Docker) | Git History ทั้งหมด (33 Commits, ~3.4 MB) | no leaks found |

### 2.1 ผลของ `ruff S` (ไม่ต้องแก้)

| กฎ | จุด | เหตุผล |
|---|---|---|
| S105 hardcoded password | `config.py` (`password_reset_url_base`, `rate_limit_password_reset`), `security.py` (`ACCESS_TOKEN_TYPE`), `auth/schemas.py` (`token_type`) | เป็นชื่อตัวแปรที่มีคำว่า password/token ไม่ใช่ Secret |
| S311 random ไม่ใช่ Crypto | `scripts/evaluate_work_patterns.py`, `cv_service/training/build.py` | ใช้สร้างข้อมูลสังเคราะห์และแบ่งชุดข้อมูล ไม่ใช่งานด้าน Security · Token ทั้งหมดใช้ `secrets` |
| S101 assert | `cv_service/app/model.py`, `training/build.py` | ตรวจชนิดของ Layer ใน MobileNetV3 ตอนสร้างโมเดล · ไม่ได้ใช้ตรวจ Input จากผู้ใช้ |
| S310 urlopen | `ml/.../download.py`, `cv_service/training/download.py` | URL เป็น HTTPS ที่กำหนดในโค้ด + ตรวจ SHA-256 · รันเฉพาะตอนเตรียมข้อมูล |
| S314 XML | `cv_service/training/build.py` | อ่าน Annotation ของ RDD2022 ที่ Pin SHA-256 แล้ว (ข้อมูลที่เชื่อถือได้ · Offline) |
| S607 partial path | `ml/.../train.py`, `cv_service/training/train.py` | เรียก `git rev-parse` เพื่อบันทึก Commit ลง Metadata · Offline |

## 3. Checklist `SYSTEM_ARCHITECTURE.md` §5

| ด้าน | สิ่งที่ตรวจในโค้ด | หลักฐาน (Test) | ผล |
|---|---|---|---|
| Password | Argon2id (`pwdlib` Argon2Hasher) · 8–128 ตัวอักษร · ตรวจกับ Deny-list (ขยายใน P6a เป็น 2,114 รายการ) · ห้ามซ้ำกับชื่อ E-mail · Login กับ E-mail ที่ไม่มีอยู่ก็ Verify กับ Hash หลอก เวลาตอบจึงใกล้กัน (`app/core/security.py`) | `unit/test_security.py::test_password_problem` · `test_auth.py::test_register_rejects_weak_passwords`, `test_login_wrong_password_and_unknown_email_look_the_same` | ✅ |
| Tokens | Access JWT HS256 15 นาที ต้องมี `sub`/`type`/`iat`/`exp`/`jti` · Secret ≥ 32 ตัวอักษร และ Production ปฏิเสธค่าที่ดูเหมือน Placeholder · Refresh 256-bit เก็บเฉพาะ SHA-256 · Rotation + Reuse detection เพิกถอนทั้ง Family | `test_tokens.py` (14 tests: expired/forged/unknown user/rotation/hash/reuse/logout) · `unit/test_config.py` | ✅ |
| Authorization | Query ทุกตัวกรองด้วย `user_id` · Role `rider`/`admin` (เปลี่ยนสถานะเหตุได้เฉพาะ admin) · **ใหม่:** Inventory ของ Endpoint ทั้ง 56 ตัว + Test ว่าทุก Endpoint ที่ไม่ใช่ Public ตอบ 401 เมื่อไม่มี Token | `test_cross_user.py` · `test_road.py::test_admin_can_reject_and_riders_cannot` · `test_security_audit.py::test_every_route_is_classified`, `test_route_requires_a_token` (48 Endpoints) | ✅ |
| SQL Injection | ใช้ ORM/Bound parameters ทั้งหมด · `text()` ทุกจุดเป็นข้อความคงที่ (Index, Server default, `SELECT 1`) · ไม่มีการต่อ String เป็น SQL | ตรวจด้วย `grep` (`text(`, `exec_driver_sql`, f-string SQL) | ✅ |
| Validation | Pydantic: `extra="forbid"` ทุก Request body (ส่ง `user_id`/`role` มาจะได้ 422) · กำหนดช่วงค่าและความยาว · Pagination ≤ `MAX_PAGE_SIZE` · ไม่ได้ใช้ Strict mode ของ Pydantic (มีการแปลงชนิด เช่น `"500"` → Decimal) | `test_auth.py::test_register_validation_errors` · `test_trueprofit_crud.py` · `test_platform.py::test_malformed_json_is_422` | ✅ (ปรับคำใน §5) |
| Rate limiting | ใช้ `limits` (Moving window ใน Memory) ไม่ใช่ slowapi · register 3/นาที/IP · login 5/นาที ต่อ IP และต่อ E-mail · forgot 3/นาที ต่อ IP และต่อ E-mail · reset 3/นาที/IP · รายงานเหตุ 10/นาที/User · ทั่วไป 60/นาที/User | `test_rate_limits.py` (7 tests) | ✅ (ปรับคำใน §5) |
| CORS | เปิดเฉพาะเมื่อมี `CORS_ORIGINS` (ค่าเริ่มต้นว่าง = ไม่มี CORS Middleware) | `app/main.py` | ✅ |
| File upload | ตรวจ Magic bytes · ≤ 5 MB · ≤ 40 MP · Re-encode เป็น JPEG ใหม่ (ลบ EXIF/GPS/ICC/XMP) · ชื่อไฟล์เป็น UUID · Path ต้องตรง Regex · **ใหม่:** จำกัดขนาด Body ตอนกำลังรับข้อมูล (§4 F-1) | `test_road.py::test_photo_is_reencoded_without_exif_and_kept_upright`, `test_non_images_are_415`, `test_photo_over_5_mb_is_413` · `test_security_audit.py::test_streamed_upload_over_cap_is_413_before_authentication` | ✅ |
| Secrets | `.env` อยู่ใน `.gitignore` · มี `.env.example` · Compose บังคับให้ตั้ง `POSTGRES_PASSWORD`/`JWT_SECRET` · gitleaks ไม่พบ · Keystore ไม่อยู่ใน Repo · ยังไม่มี gitleaks ใน CI (CI ทำใน Phase 7) | gitleaks (§2) · `unit/test_config.py` | ✅ (CI → Phase 7) |
| Privacy | Incident ไม่เปิดเผยผู้รายงาน · `DELETE /me` ลบข้อมูล รูป และปรับตัวนับ · Access log บันทึก Path โดยไม่มี Query string · **ใหม่:** Test ว่า Log ระดับ INFO ไม่มี Password, Token หรือพิกัด | `test_road.py::test_incidents_never_expose_reporters_and_reports_stay_private`, `test_account_deletion_removes_reports_photos_and_fixes_counters` · `test_profile.py::test_delete_me_removes_account_and_all_data` · `test_security_audit.py::test_logs_hold_no_password_token_or_position` | ✅ |
| Forgot Password (D5) | เก็บเฉพาะ SHA-256 · อายุ 30 นาที · ใช้ได้ครั้งเดียว · คำขอใหม่ยกเลิก Token เดิม · Reset แล้ว Logout ทุกเครื่อง · Production ที่ไม่มี Provider ปิด Endpoint และไม่ Log Link | `test_password_reset.py` (11 tests) | ✅ |

### 3.1 Mobile

| ด้าน | สิ่งที่ตรวจ | ผล |
|---|---|---|
| เก็บ Token | Refresh token อยู่ใน `flutter_secure_storage` (`lib/core/storage/refresh_token_store.dart`) · Access token อยู่ใน Memory เท่านั้น (`session_token_manager.dart`) | ✅ |
| Transport | Release build ต้องใช้ `API_BASE_URL` แบบ https มิฉะนั้นจะ Throw (`lib/core/config/app_config.dart`) · Cleartext อนุญาตเฉพาะ `10.0.2.2`/`127.0.0.1`/`localhost` ใน `src/debug` | ✅ |
| Backup | `android:allowBackup="false"`, `fullBackupContent="false"` | ✅ |
| Log | ไม่มี `LogInterceptor`/`print` ที่พิมพ์ Request หรือ Token | ✅ |
| สิทธิ์ | ขอตำแหน่งเฉพาะตอนใช้งาน (ไม่มี Background location) | ✅ |
| Deep link | `rideros://reset-password?token=…` เป็น Custom scheme | ⚠️ R-4 |
| Release signing | `build.gradle.kts` ของ Release ยังเซ็นด้วย Debug key | ✅ แก้แล้วใน P7a (R-7) |

## 4. ข้อบกพร่องที่พบและแก้ใน P6a

| ID | ระดับ | ปัญหา | การแก้ | หลักฐาน |
|---|---|---|---|---|
| F-1 | Medium (OWASP API4) | FastAPI อ่าน Multipart form และเขียนไฟล์ลงดิสก์ **ก่อน** รัน Dependency ของ Auth และก่อนเข้า Endpoint ส่วนการตรวจ `Content-Length` อยู่ใน Endpoint จึงช้าเกินไป ผู้ใช้ที่ไม่ได้ Login สามารถส่ง Body แบบ Chunked (ไม่มี Content-Length) ขนาดเท่าใดก็ได้ไปที่ `POST /road/reports` และ JSON body ก็ไม่มีขนาดสูงสุด | `app/core/body_limit.py` `BodySizeLimitMiddleware`: Multipart ≤ 5 MB + 64 KiB, Body อื่น ≤ 256 KiB (`MAX_JSON_BODY_BYTES`) · ตรวจทั้ง Content-Length ที่ประกาศมาและจำนวนไบต์ที่รับจริง → 413 `payload_too_large` | `test_security_audit.py` 5 tests (ตรวจแล้วว่า **Fail** เมื่อถอด Middleware ออก) · ยิงจริงกับ Container: Body 300 KB → 413 |
| F-2 | High/Critical (Container) | Base image `python:3.14.6-slim-trixie` (ส.ค. 2026) มี Critical 3 และ High ที่มีแพตช์ 57 รายการ · Python ระบบมี `pip` ที่ Vendor `urllib3`/`msgpack`/`setuptools` เวอร์ชันมีช่องโหว่ | ใช้ `python:3.14.10-slim-trixie` + `apt-get upgrade` ใน Runtime stage + ลบ `pip` ของระบบ (แอปรันจาก `/opt/venv`) ทั้ง `backend/Dockerfile` และ `cv_service/Dockerfile` · Model check ใช้ Major.Minor (3.14) ยังโหลดได้ | trivy หลังแก้: Critical 0, High ที่มีแพตช์ 0 · Stack ขึ้น `healthy`, `/ready` → `model: ok (pickup_o2p/1.0.0)`, cv `/health` ok |
| F-3 | Low | Deny-list รหัสผ่านมีแค่ 84 รายการ | รวม SecLists `10k-most-common.txt` (MIT, Pin Commit `a252ee44…` + SHA-256 ไว้ในหัวไฟล์) โดยเก็บเฉพาะรายการที่ยาว 8–128 ตัวอักษร (สั้นกว่านี้ไม่ผ่านกฎความยาวอยู่แล้ว) → 2,114 รายการ | `unit/test_security.py` · `test_password_reset.py::test_weak_new_password_does_not_consume_token` |

## 5. ความเสี่ยงที่ยอมรับ (Accepted risks)

| ID | ระดับ | เรื่อง | เหตุผล / แผน |
|---|---|---|---|
| R-1 | Low | `POST /auth/register` ตอบ 409 `email_taken` → รู้ได้ว่า E-mail มีบัญชีหรือไม่ · `forgot-password` ตอบเหมือนกันทุกกรณี แต่กรณีมีบัญชีจะเขียน DB ด้วย จึงใช้เวลาต่างกันเล็กน้อย | UX ของการสมัครต้องบอกผู้ใช้ · จำกัด 3/นาที/IP · ค่า Login ใช้ Hash หลอกให้เวลาตอบใกล้กัน |
| R-2 | Low | Access token ที่ออกไปแล้วยังใช้ได้จนหมดอายุ (≤ 15 นาที) หลัง Logout หรือ Reset password | เป็นข้อแลกเปลี่ยนปกติของ JWT แบบ Stateless · ส่วน Refresh token ถูกเพิกถอนทันที |
| ~~R-3~~ | — | ~~Rate limiter อยู่ใน Memory ต่อ Process และยังไม่เชื่อ `X-Forwarded-For`~~ | **แก้แล้วใน P7a (HANDOFF §4.15):** Production ใช้ Valkey ร่วมทุก Worker (Settings ไม่ยอมให้ `WEB_CONCURRENCY` > 1 กับ `memory://`) · Store ล่ม → 503 · uvicorn เชื่อ `X-Forwarded-For` เฉพาะจาก IP คงที่ของ Caddy · Test: `tests/api/test_rate_limit_storage.py` · ตรวจกับ Stack จริงในเครื่อง: XFF ปลอม 7 ครั้ง → ครั้งที่ 6 ได้ 429 และ Key เป็น IP จริง |
| R-4 | Low | Deep link แบบ Custom scheme: แอปอื่นลงทะเบียน `rideros://` ซ้ำได้ จึงอาจดัก Reset token | ตอนนี้ Reset link มีเฉพาะใน Dev log (D5) · Token ใช้ครั้งเดียว อายุ 30 นาที · **Phase 7:** ถ้ามี Email provider ให้ใช้ Android App Links (https + `assetlinks.json`) |
| R-5 | Low | CV Service (`/classify`) ไม่มี Body limit แบบ Streaming | ไม่มี Port ที่เปิดออกนอก Docker network · มีแค่ Backend เรียก และส่งรูปที่ Re-encode แล้ว (≤ 1600 px) |
| R-6 | Medium | 47 High ใน Debian base (util-linux, ncurses, perl-base, sqlite, systemd libs) ยังไม่มีแพตช์จาก Debian | แอปไม่เรียกใช้โปรแกรมเหล่านี้กับ Input ของผู้ใช้ · Container รันเป็น User `app` (UID 10001) · **Phase 7:** สแกนซ้ำก่อน Deploy |
| ~~R-7~~ | — | ~~Release APK ยังเซ็นด้วย Debug key~~ | **แก้แล้วใน P7a:** `android/key.properties` (gitignored) → Keystore ที่ `%USERPROFILE%\.rideros\` · ไม่มีไฟล์ → Release build ไม่ถูกเซ็น (ติดตั้งไม่ได้) แทนการใช้ Debug key |
| ~~R-8~~ | — | ~~ไม่มี Security headers (HSTS ฯลฯ)~~ | **แก้แล้วใน P7a:** Caddy (`deploy/Caddyfile`) ทำ TLS อัตโนมัติ, HTTP → 308 HTTPS, ส่ง `Strict-Transport-Security`, `X-Content-Type-Options`, `Referrer-Policy`, ตัด `Server` · เปิดเฉพาะ `/api/v1/*` |
| R-9 | Info | Dev compose เปิด DB/API ที่ `127.0.0.1` เท่านั้น · `/docs` เปิดเมื่อไม่ใช่ Production | Production ปิด `/docs` และ `/openapi.json` (`test_production_hides_openapi_docs`) |

## 6. OWASP API Security Top 10 (2023)

| ข้อ | สถานะ | อ้างอิง |
|---|---|---|
| API1 Broken Object Level Authorization | ✅ | Filter `user_id` ใน Repository · `test_cross_user.py` (คำตอบ 404 เหมือนกับ ID ที่ไม่มีอยู่) |
| API2 Broken Authentication | ✅ | §3 Tokens/Password · Inventory + 401 ทุก Endpoint ที่ต้อง Login · Rate limit ต่อ E-mail |
| API3 Broken Object Property Level Authorization | ✅ | `extra="forbid"` (ส่ง `role`/`user_id`/`is_demo` มาจะถูกปฏิเสธ) · Response model ไม่มี `password_hash`/ผู้รายงาน |
| API4 Unrestricted Resource Consumption | ✅ (แก้ F-1) | Body limit · Page size สูงสุด · Rate limits · รูป ≤ 40 MP · รหัสผ่าน ≤ 128 ตัวอักษร (จำกัดงานของ Argon2) |
| API5 Broken Function Level Authorization | ✅ | `PATCH /road/incidents/{id}/status` ต้องเป็น admin (`admin_only`) · ไม่มี Endpoint ให้เปลี่ยน Role |
| API6 Unrestricted Access to Sensitive Business Flows | ✅ | รายงานเหตุ 10/นาที/User · รายงานซ้ำในเหตุเดิมไม่ได้ · ยืนยัน/คลี่คลายต้องมีผู้ใช้ ≥ 2 คน |
| API7 Server Side Request Forgery | ✅ | Backend เรียกเฉพาะ `CV_SERVICE_URL` จาก ENV · ไม่มี URL จากผู้ใช้ |
| API8 Security Misconfiguration | ✅ / R-8 | Production guard (JWT placeholder, `DB_ECHO`) · Error 500 ไม่เปิดเผยรายละเอียด (`test_unhandled_error_is_500_without_leaking_details`) · `/docs` ปิดใน Production · Container ไม่ใช่ root |
| API9 Improper Inventory Management | ✅ (ใหม่) | `test_every_route_is_classified`: Endpoint ใหม่จะทำให้ Test Fail จนกว่าจะระบุว่าเป็น Public หรือต้อง Login |
| API10 Unsafe Consumption of APIs | ✅ | ผลจาก CV Service ถูก Validate ด้วย Schema · ถ้า CV ล่ม/Timeout รายงานยังบันทึกได้ (`ai_status` = `failed`) |

## 7. วิธีรันซ้ำ

```bash
# Python dependencies (ทำแต่ละโปรเจกต์: backend / ml / cv_service)
python -m uv export --format requirements-txt --no-emit-project --all-groups --frozen > req.txt
#   backend: ลบบรรทัด "../ml" (Path dependency) ออกก่อน
python -m uv tool run pip-audit -r req.txt --require-hashes --disable-pip
# Flutter
MSYS_NO_PATHCONV=1 docker run --rm -v "C:/dev/RiderOS AI/mobile:/src:ro" ghcr.io/google/osv-scanner:v2.2.4 scan source --lockfile /src/pubspec.lock
# Docker images (หลัง docker compose build)
MSYS_NO_PATHCONV=1 docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.67.2 image --scanners vuln --severity HIGH,CRITICAL rideros-backend:latest
# Secrets
MSYS_NO_PATHCONV=1 docker run --rm -v "C:/dev/RiderOS AI:/repo:ro" zricethezav/gitleaks:v8.30.0 git /repo
# กฎ bandit
python -m uv run ruff check --select S --exclude tests .
```
