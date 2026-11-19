# Portfolio — RiderOS AI

> **อัปเดต 2026-11-19:** เปลี่ยนแนวแอป: Grab/LINE MAN ช่วยไรเดอร์รับงานและส่งอาหาร ส่วน RiderOS ช่วยให้ไรเดอร์เข้าใจการทำงานของตัวเอง วิเคราะห์รายได้ และตัดสินใจได้ดีขึ้น · เอา RoadContext (แผนที่เหตุบนถนน + โมเดลจัดประเภทรูป) และ `ml/` (โมเดล Meituan) ออกแล้ว (`docs/HANDOFF.md` §4.21) · Pickup ออกไปก่อนหน้า (§4.20)

Resume bullets and an interview summary. Every number comes from a recorded run (sources in the right
column). Do not round them up and do not add numbers that are not in a report.

## Resume bullets (English)

- Built **RiderOS AI**, a work-analytics app for food-delivery riders: Grab and LINE MAN handle orders and
  delivery, RiderOS tells riders what their own work earns and when it pays best. Flutter (Android) client,
  FastAPI + PostgreSQL modular-monolith backend; 893 automated tests and CI on GitHub Actions.
- Turned the rider's own records into decisions: net profit after fuel and wear, a profit-per-hour heat map by
  weekday × 2-hour slot (money placed through work sessions), a significance-gated trend (OLS, p < 0.05), and a
  Shift Simulator that estimates a planned shift from the rider's history (P25–P75 range).
- Designed statistically gated K-Means "work patterns" (silhouette + 39-shuffle permutation test + bootstrap
  ARI) that cut false patterns to 1.7% while detecting 99.2% of real ones on a synthetic benchmark.
- Cut logging to one tap: a start/stop shift timer that fills in the work session and chains straight into
  the income form linked to it.
- Hardened the API against the OWASP API Top 10: Argon2id, rotating refresh tokens with reuse detection,
  shared Redis/Valkey rate limiting that fails closed, a streaming request-size cap; 0 known dependency
  vulnerabilities.
- Met all p95 latency targets under load (CRUD/summary < 300 ms, cached work patterns 110.5 ms at concurrency 10,
  0 errors in 5,600 requests); built a Caddy + Docker production stack with daily backups and a tested restore drill.
- Product judgment: removed two trained models (an XGBoost pickup-time regressor and a MobileNetV3 road-photo
  classifier) once it was clear they did not help riders, and refocused the app on the rider's own data.

## Resume bullets (ไทย)

- พัฒนา **RiderOS AI** แอปวิเคราะห์การทำงานของไรเดอร์ส่งอาหาร: Grab/LINE MAN ช่วยรับงานและส่งอาหาร ส่วน RiderOS
  ช่วยให้ไรเดอร์เข้าใจงานของตัวเอง วิเคราะห์รายได้ และตัดสินใจได้ดีขึ้น · Flutter (Android) + FastAPI + PostgreSQL ·
  มี Test อัตโนมัติ 893 รายการ + CI บน GitHub Actions
- เปลี่ยนข้อมูลที่ไรเดอร์บันทึกเองเป็นข้อมูลช่วยตัดสินใจ: กำไรสุทธิหลังหักค่าน้ำมันและค่าเสื่อม, Heatmap กำไร/ชม.
  ตามวัน × ช่วง 2 ชม., แนวโน้มที่แสดงเฉพาะเมื่อมีนัยสำคัญ (p < 0.05) และ Shift Simulator ที่ประมาณจากประวัติจริง
- ออกแบบ K-Means "รูปแบบการทำงาน" ที่ผ่านด่านสถิติ 3 ชั้น ลดกลุ่มหลอกเหลือ 1.7% และตรวจพบกลุ่มจริง 99.2% (Benchmark ข้อมูลสังเคราะห์)
- ทำให้การบันทึกเหลือแตะเดียว: ตัวจับเวลาเริ่ม/หยุดงาน → บันทึกช่วงทำงาน → ฟอร์มรายได้ที่ผูกกับช่วงนั้นต่อทันที
- ทำ Security ตาม OWASP API Top 10 และวัด Performance ผ่านเป้า p95 ทุก Endpoint (0 Error จาก 5,600 Request)
- ตัดสินใจเชิงผลิตภัณฑ์: เอาโมเดลที่เทรนเอง 2 ตัว (XGBoost ทำนายเวลารับอาหาร, MobileNetV3 จัดประเภทรูปถนน) ออก
  เมื่อเห็นว่าไม่ช่วยไรเดอร์จริง แล้วโฟกัสแอปที่ข้อมูลของไรเดอร์เอง

## Interview notes

- **Why the app is about the rider's own data:** the platforms already own orders, routing and preparation
  times. What riders lack is an honest view of their own work: real profit after costs, which hours pay, and
  what a planned shift is likely to bring. Every analysis reads only the signed-in rider's records.
- **Why I removed Pickup (2026-11-18):** a working model is not the same as a useful feature. Riders already
  see prep-time estimates in Grab/LINE MAN, the model (trained on one Chinese city) knew nothing about Thai
  restaurants, and there was no Thai data to retrain it on.
- **Why I removed RoadContext (2026-11-19):** road warnings for other riders did not fit an app about the
  rider's own work, and without platform integration the app cannot know the destination, so it could not
  route around incidents. Both removals kept the database migrations reversible.
- **Why Silhouette alone was not enough:** on random data the weekend flag always split the riders, so
  silhouette "found" groups. The permutation test fixed that (benchmark in `backend/reports/`).
- **What I did not build, and why:** no shift-earnings ML (no per-shift data), no LLM chat (no paid API), and
  no public deployment yet. See README → What I chose not to build, and Limitations.

## Sources

| Number | Source |
|---|---|
| 893 tests (backend 402, mobile 491) | `scripts/regression.ps1` run 2026-11-19 (HANDOFF §4.23) |
| 1.7% / 99.2% | `backend/reports/work_patterns_benchmark.json`, HANDOFF §4.12 |
| p95 and 5,600 requests (9,600 minus the removed Pickup and Road endpoints) | `docs/PERFORMANCE.md`, `backend/reports/perf_p6b.json` |
| 0 known vulnerabilities | `docs/SECURITY_AUDIT.md` |
