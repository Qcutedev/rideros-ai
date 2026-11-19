# Performance — RiderOS AI (Phase 6 · P6b)

> **อัปเดต 2026-11-19:** Endpoint `/road/*` ถูกลบแล้ว (`docs/HANDOFF.md` §4.21) และ `backend/perf/run.py` ไม่ Seed/วัดแล้ว · ผลด้านล่างเป็นผลของ Phase 6
>
> **อัปเดต 2026-11-18:** Endpoint `/pickup/*` ถูกลบแล้ว (`docs/HANDOFF.md` §4.20) และ `backend/perf/run.py` ไม่วัดแล้ว ผลด้านล่างเป็นผลของ Phase 6 ที่ยังมี Pickup

- วันที่วัด: 2026-11-14 · Commit ฐาน `8641bcc` + การแก้ใน P6b (ยังไม่ Commit)
- การตัดสินใจที่ใช้: HANDOFF §4.13 ข้อ 4–5 (สคริปต์ `httpx` async, 200 req/Endpoint ที่ Concurrency 1 และ 10, เป้า p95)
- ตัวเลขทั้งหมดมาจากการรันจริงบนเครื่องด้านล่าง ไม่ใช่ค่าประมาณ · ผลดิบ: `backend/reports/perf_p6b.json`
- เป็นค่าบน Docker ในเครื่องเดียว (Client กับ Server แย่ง CPU เดียวกัน) ไม่ใช่ค่าบน Server จริง → ใช้เทียบก่อน/หลังแก้ และเช็กว่าไม่มี Endpoint ไหนช้าผิดปกติ

## 1. สรุปผล

| เกณฑ์ | ผล |
|---|---|
| CRUD / Summary p95 < 300 ms (22 Endpoint × c=1, c=10) | ผ่านทั้งหมด · สูงสุด `GET /shift-scenarios` c=10 = 149.0 ms |
| Pickup prediction p95 < 500 ms | ผ่าน · c=1 = 32.7 ms, c=10 = 358.9 ms |
| `/profit/patterns` (Cache) p95 < 500 ms | ผ่าน · c=1 = 14.3 ms, c=10 = 110.5 ms |
| `/profit/patterns` ครั้งแรกหลังข้อมูลเปลี่ยน (รายงานแยก ไม่มีเป้า) | 621–660 ms (5 ครั้ง, median 639 ms) |
| Request ที่ไม่ได้ Status ที่คาด | 0 จาก 9,600 |
| ข้อบกพร่องที่พบและแก้ | 1 (§4: Argon2 บล็อก Event loop) |
| Mobile cold start (Profile build, Emulator) | median 1,565 ms (10 ครั้ง) |

ทุก Endpoint ผ่านเป้า จึงไม่ต้องแก้ Index/Query (การตัดสินใจข้อ 5)

## 2. วิธีวัด

### 2.1 เครื่องและ Stack

| รายการ | ค่า |
|---|---|
| Host | Windows 11 (10.0.26300) · Intel Core i5-11400H (6 Core / 12 Thread) · RAM 15.8 GB |
| Docker | Docker Desktop 29.8.2 · WSL2 kernel 6.18.58.1 · 12 CPU · 7.6 GiB |
| Backend | Image จาก `backend/Dockerfile` (Python 3.14.10) · uvicorn **1 Process** (`scripts/entrypoint.sh`) · DB pool 5 · Log JSON ทุก Request |
| DB | `postgis/postgis:18-3.6` ใน Compose เดียวกัน (Dev DB ที่มีข้อมูลร้าน Dataset อยู่แล้ว) |
| Client | `backend/perf/run.py` บน Host (Python 3.14.6, `httpx` async) → `127.0.0.1:8000` |

### 2.2 ข้อมูล

สคริปต์สร้างไรเดอร์ชั่วคราว `perf+<เวลา>@example.com` ผ่าน API จริง แล้วลบด้วย `DELETE /me` เมื่อจบ:

| ข้อมูล | จำนวน |
|---|---|
| ช่วงทำงาน (180 วันย้อนหลัง: เย็นวันธรรมดา ~75%, กลางวันวันหยุด ~70%) | 132 (+5 ตอนวัด patterns ครั้งแรก) |
| รายได้ (1 รายการต่อช่วง, ผูก Session) | 132 (+400 จาก `POST /income` ที่วัด) |
| ค่าใช้จ่าย (น้ำมันทุก 2 ช่วง + ซ่อมบำรุงเดือนละครั้ง) | 72 |
| Pickup log (ร้านของฉัน) | 30 |
| ประวัติการทำนาย | 20 (+400 จาก `POST /pickup/predictions` ที่วัด) |
| Shift scenario (assumption 2, historical 1) | 3 |
| รายงาน RoadContext (5 หมวด, 5 จุดใกล้กัน) | 5 |

`random.Random(42)` ทำให้ข้อมูลเหมือนกันทุกรอบ ยกเว้นช่วงทำงานที่ใช้วัด patterns ครั้งแรก (สุ่มนาทีเพื่อไม่ให้โดน Cache ของรอบก่อน · §3.2)

### 2.3 ขั้นตอน

```powershell
cd "C:\dev\RiderOS AI"
docker compose -f docker-compose.yml -f backend/perf/compose.perf.yml up -d backend   # RATE_LIMIT_ENABLED=false
cd backend
python -m uv run python -m perf.run --out reports/perf_p6b.json                    # ~3 นาที
cd ..; docker compose up -d backend                                                # กลับเป็นค่าปกติ
```

- ปิด Rate limit (60/นาที/User) เฉพาะรอบวัด ผ่าน `backend/perf/compose.perf.yml` ที่ตั้งแค่ `RATE_LIMIT_ENABLED=false` · ระหว่างวัดถ้าได้ 429 สคริปต์ถือว่า Fail (ไม่ Retry เพราะจะบังค่าจริง) · ตอน Seed Retry 429 ตาม `Retry-After`
- ต่อ Endpoint: Warm-up 10 Request (ไม่นับ) → วัด 200 Request ที่ c=1 → Warm-up 10 → วัด 200 ที่ c=10 · Login ใหม่ก่อนแต่ละ Endpoint เพราะ Access token อยู่ 15 นาที
- Latency วัดที่ Client (`time.perf_counter` รอบ `client.request`) จึงรวม Network ใน localhost และการอ่าน Response · Percentile = `statistics.quantiles(n=100, method="inclusive")`
- ลำดับ: อ่านทั้งหมดก่อน → patterns (Cache) → การทำนาย → `POST /income` → Login → patterns ครั้งแรก 5 ครั้ง (เพิ่มช่วงทำงานสั้นๆ 1 ช่วงก่อนแต่ละครั้งให้ Cache miss)
- สคริปต์จบด้วย Exit code 1 ถ้ามี Error หรือ p95 เกินเป้า

## 3. ผล API

### 3.1 Latency (ms) ต่อ Endpoint

| Endpoint | กลุ่ม | เป้า p95 | c=1 p50 / p95 / p99 | c=10 p50 / p95 / p99 | c=10 req/s | ผล |
|---|---|---|---|---|---|---|
| `GET /me` | crud | < 300 ms | 6.0 / 8.5 / 9.3 | 23.7 / 137.1 / 276.0 | 217.1 | ✅ |
| `GET /work-sessions` | crud | < 300 ms | 8.2 / 10.7 / 12.0 | 44.1 / 102.2 / 184.5 | 202.0 | ✅ |
| `GET /income` | crud | < 300 ms | 8.3 / 11.1 / 16.3 | 43.1 / 53.0 / 199.8 | 210.9 | ✅ |
| `GET /expenses` | crud | < 300 ms | 8.2 / 10.7 / 11.7 | 46.3 / 59.5 / 118.3 | 203.9 | ✅ |
| `GET /pickup/restaurants?q=` | crud | < 300 ms | 14.5 / 17.5 / 22.5 | 50.0 / 108.4 / 219.8 | 158.4 | ✅ |
| `GET /pickup/restaurants/{id}/analytics` | crud | < 300 ms | 9.0 / 11.7 / 12.4 | 50.3 / 86.2 / 110.8 | 182.1 | ✅ |
| `GET /pickup/restaurants/{id}/wait-stats` | crud | < 300 ms | 8.0 / 10.7 / 12.3 | 40.9 / 104.7 / 173.3 | 210.5 | ✅ |
| `GET /pickup/predictions` | crud | < 300 ms | 8.2 / 10.7 / 11.4 | 45.3 / 82.2 / 150.3 | 191.7 | ✅ |
| `GET /pickup/logs` | crud | < 300 ms | 8.0 / 10.5 / 10.7 | 43.2 / 74.6 / 133.6 | 210.2 | ✅ |
| `GET /shift-scenarios` | crud | < 300 ms | 8.0 / 11.3 / 17.2 | 26.4 / 149.0 / 242.4 | 214.8 | ✅ |
| `GET /road/incidents?bbox=` | crud | < 300 ms | 8.2 / 10.9 / 11.3 | 48.1 / 90.4 / 147.0 | 189.9 | ✅ |
| `GET /road/incidents/nearby` | crud | < 300 ms | 8.1 / 10.9 / 14.3 | 44.6 / 95.6 / 114.3 | 198.6 | ✅ |
| `GET /road/incidents/{id}` | crud | < 300 ms | 9.0 / 11.5 / 12.4 | 51.9 / 90.1 / 102.3 | 173.0 | ✅ |
| `GET /road/reports` | crud | < 300 ms | 7.8 / 10.3 / 11.7 | 40.2 / 85.5 / 121.2 | 211.7 | ✅ |
| `GET /profit/summary?period=week` | summary | < 300 ms | 10.1 / 13.2 / 18.2 | 61.8 / 71.1 / 136.0 | 156.8 | ✅ |
| `GET /profit/summary?period=month` | summary | < 300 ms | 10.2 / 12.8 / 14.1 | 65.4 / 79.0 / 143.3 | 146.5 | ✅ |
| `GET /profit/trends` (90 วัน รายวัน) | summary | < 300 ms | 12.8 / 17.6 / 20.5 | 87.7 / 106.1 / 168.1 | 109.6 | ✅ |
| `GET /profit/trends` (180 วัน รายสัปดาห์) | summary | < 300 ms | 12.4 / 16.1 / 22.8 | 83.6 / 105.3 / 162.4 | 113.8 | ✅ |
| `POST /shift-scenarios/{id}/estimate` (historical) | summary | < 300 ms | 14.0 / 17.5 / 18.6 | 90.0 / 142.8 / 216.7 | 100.1 | ✅ |
| `POST /shift-scenarios/compare` (3 รายการ) | summary | < 300 ms | 8.5 / 10.7 / 12.2 | 46.8 / 73.5 / 134.4 | 199.6 | ✅ |
| `GET /profit/patterns` (Cache) | patterns | < 500 ms | 11.5 / 14.3 / 15.2 | 73.1 / 110.5 / 133.7 | 128.7 | ✅ |
| `POST /pickup/predictions` | prediction | < 500 ms | 27.5 / 32.7 / 42.0 | 282.0 / 358.9 / 423.6 | 35.9 | ✅ |
| `POST /income` | crud | < 300 ms | 9.0 / 11.5 / 12.4 | 47.5 / 77.5 / 119.7 | 193.4 | ✅ |
| `POST /auth/login` | auth | — | 69.0 / 78.9 / 95.6 | 578.5 / 691.4 / 773.6 | 17.8 | — |

- ที่ c=10 Request ต่อคิวกันใน Process เดียว p50 จึงประมาณ 10 × เวลาที่ c=1 · Endpoint ทั่วไปรับได้ ~100–215 req/s
- Login ไม่มีเป้า: Argon2id ตั้งใจให้ช้า (~70 ms ต่อครั้ง) เพื่อกัน Brute force · ได้ ~14–18 req/s ต่อ Process ร่วมกับ Rate limit 5/นาที ต่อ IP และต่ออีเมล

### 3.2 `/profit/patterns` ครั้งแรกหลังข้อมูลเปลี่ยน

| ครั้งที่ | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| ms | 639.2 | 628.6 | 621.1 | 659.5 | 653.8 |
| status | ok | ok | ok | ok | ok |

ตรงกับที่บันทึกไว้ตอนทำ K-Means (§7 Known issues: 0.6–1 s) · ทำงานใน Threadpool จึงไม่บล็อก Request อื่น · ครั้งถัดไปที่ข้อมูลเท่าเดิมได้จาก Cache (~14 ms)

พบตอนวัด: Cache (`find_patterns_cached`) ใช้ข้อมูลช่วงทำงานเป็น Key ไม่ใช่ User · รอบทดลองแรกได้ "ครั้งแรก" 12 ms เพราะข้อมูลที่ Seed ซ้ำกับรอบก่อนพอดี → แก้สคริปต์ให้สุ่มนาทีของช่วงที่เพิ่ม (ไม่ใช่ปัญหาความเป็นส่วนตัว: ผลจาก Cache ได้เฉพาะคนที่มีข้อมูลเหมือนกันทุกแถวอยู่แล้ว)

### 3.3 ทำไม Pickup prediction ที่ c=10 ช้ากว่าตัวอื่น

- Throughput คงที่ ~36 req/s ทั้ง c=1 และ c=10 → ถูกจำกัดด้วย CPU ของ Process เดียว ไม่ใช่ DB
- Profile ใน Container (1 แถว, median 50 ครั้ง): Pipeline ทั้งหมด 14.6 ms · `ColumnTransformer` (`pre`: TargetEncoder + CountEncoder + OrdinalEncoder + FunctionTransformer บน pandas) **11.2 ms** · `FeatureFrame` 1.0 ms · XGBoost 0.4 ms (`n_jobs=1`) · 10 Thread พร้อมกันได้ 200 ครั้งใน 4.27 s (ติด GIL)
- ยังผ่านเป้า (358.9 < 500 ms) จึงไม่แก้ในตอนนี้ · ถ้าต้องรับโหลดมากขึ้น (Phase 7): เพิ่ม uvicorn worker (ต้องย้าย Rate limiter ไป Redis ก่อน เพราะตอนนี้นับแยกต่อ Process) หรือ Export ส่วน Preprocess ให้ไม่ผ่าน pandas (ต้อง Train/ตรวจ Hash ของ Artifact ใหม่)

## 4. ข้อบกพร่องที่พบและแก้

### F-P1: Argon2 รันบน Event loop (แก้แล้ว)

- พบ: `hash_password`/`verify_password` ถูกเรียกตรงๆ ใน `async def` ของ Register, Login, Reset password และ `DELETE /me` → ทุกครั้งที่มีคน Login, Event loop หยุด ~70 ms และทุก Request อื่นใน Process ต้องรอ
- แก้: `app/core/security.py` เพิ่ม `hash_password_async`/`verify_password_async` (`run_in_threadpool`; argon2-cffi ปล่อย GIL ระหว่าง Hash) · `auth/service.py` และ `users/service.py` ใช้ตัว Async ทั้ง 4 จุด · เวลาคงที่สำหรับอีเมลที่ไม่มีอยู่ยังเหมือนเดิม (ยัง Verify กับ Dummy hash)
- Test: `tests/api/test_auth.py::test_login_does_not_block_other_requests` (ระหว่างที่ Verify ถูกทำให้ช้า 0.6 s, `GET /health` ต้องตอบภายใน 0.45 s · **Fail เมื่อถอดการแก้**: 0.68 s) · `tests/unit/test_security.py::test_async_password_helpers_run_off_the_event_loop_thread`
- ผลวัด Login ก่อน/หลัง (รอบละครั้งเดียว): c=10 p95 920.4 → 691.4 ms, 13.9 → 17.8 req/s · ยังไม่ได้วัดผลกับ Endpoint อื่นระหว่างมีคน Login (โหลดผสม) แยก หลักฐานหลักคือ Test ด้านบน

## 5. Mobile cold start

- วิธี: `flutter build apk --profile` → `adb install -r` → 11 รอบของ `am force-stop` → `am start -W -n com.rideros.rideros_ai/.MainActivity` (ตัด TotalTime รอบแรกหลังติดตั้ง ซึ่งรายงาน 0 ms) · บัญชีที่ Login อยู่แล้ว (เปิดแล้วเข้าหน้าหลักเลย)
- เครื่อง: Android Emulator `Pixel_9_Pro` (API 37, x86_64) บน Host เดียวกับ §2.1 · **ไม่ใช่มือถือจริง**
- `TotalTime` (ถึง Frame แรก, ms): 1549, 1558, 1969, 1591, 1625, 1558, 1571, 1630, 1552, 1434 → **median 1,565 · mean 1,604 · min 1,434 · max 1,969**
- Build ก่อนแก้ Bug ของ P6b วัดได้ใกล้เคียงกัน (median 1,559 ms, 10 รอบ; รอบแรกหลังติดตั้ง 4,024 ms ตอนระบบ Compile)
- Intro ขี่รถ (§4.8) เล่นหลัง Frame แรก จึงไม่รวมในตัวเลขนี้

## 6. ข้อจำกัดของการวัด

- Client และ Server อยู่เครื่องเดียวกัน (Docker Desktop/WSL2) · ไม่มี Network จริง, TLS หรือ Reverse proxy
- ไรเดอร์ 1 คนกับข้อมูล ~6 เดือน · ยังไม่ได้วัดกับตารางที่มีผู้ใช้หลายพันคน (Index ที่มีอยู่: `DATABASE_DESIGN.md`)
- ไม่ได้วัด `POST /road/reports` (สร้างเหตุซ้ำจะได้ 409 `already_reported` และมี Rate limit แยก 10/นาที) และ Endpoint ที่เขียน/ลบอื่นๆ นอกจาก `POST /income`
- รันครั้งเดียวต่อ Build · ค่า p99 ที่ c=10 แกว่งได้ระหว่างรอบ (เช่น `GET /me` 254–276 ms ใน 2 รอบ)
