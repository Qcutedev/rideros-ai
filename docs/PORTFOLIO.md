# Portfolio — RiderOS AI

Resume bullets and an interview summary. Every number comes from a recorded run (sources in the right
column). Do not round them up and do not add numbers that are not in a report.

## Resume bullets (English)

- Built **RiderOS AI**, an end-to-end rider productivity app: Flutter (Android) client, FastAPI + PostgreSQL/PostGIS
  modular-monolith backend, and three models I trained myself; 1,286 automated tests and CI on GitHub Actions.
- Trained an order-to-pickup regressor on 568K real Meituan orders with leakage controls and a temporal split;
  XGBoost reached test MAE 4.51 min vs 4.64 for the per-restaurant baseline (reported honestly as a 2.7% gain),
  with a split-conformal 80% interval covering 81.6% of test orders.
- Fine-tuned MobileNetV3 (PyTorch) for road-photo triage (flood / road damage / other): 0.880 accuracy,
  0.876 macro-F1 on a leakage-aware test split, 16.5 ms median CPU latency, served as a separate async service.
- Designed statistically gated K-Means "work patterns" (silhouette + 39-shuffle permutation test + bootstrap
  ARI) that cut false patterns to 1.7% while detecting 99.2% of real ones on a synthetic benchmark.
- Hardened the API against the OWASP API Top 10: Argon2id, rotating refresh tokens with reuse detection,
  shared Redis/Valkey rate limiting that fails closed, EXIF-stripped uploads; 0 known dependency vulnerabilities.
- Met all p95 latency targets under load (CRUD < 300 ms, prediction 358.9 ms at concurrency 10, 0 errors in
  9,600 requests); built a Caddy + Docker production stack with daily backups and a tested restore drill.

## Resume bullets (ไทย)

- พัฒนา **RiderOS AI** แอปช่วยไรเดอร์ส่งอาหารแบบครบวงจร: Flutter (Android) + FastAPI + PostgreSQL/PostGIS
  และโมเดล AI 3 ตัวที่เทรนเอง · มี Test อัตโนมัติ 1,286 รายการ + CI บน GitHub Actions
- เทรนโมเดลทำนายเวลาจากสั่งถึงรับอาหารจากออเดอร์จริงของ Meituan 568K รายการ ป้องกัน Data leakage และแบ่งข้อมูลตามเวลา ·
  XGBoost ได้ MAE 4.51 นาที เทียบ Baseline 4.64 (ดีขึ้น 2.7%) · ช่วงความเชื่อมั่น 80% แบบ Conformal ครอบคลุมจริง 81.6%
- Fine-tune MobileNetV3 (PyTorch) จัดประเภทรูปเหตุบนถนน: Accuracy 0.880, Macro-F1 0.876, Latency median 16.5 ms บน CPU
- ออกแบบ K-Means "รูปแบบการทำงาน" ที่ผ่านด่านสถิติ 3 ชั้น ลดกลุ่มหลอกเหลือ 1.7% และตรวจพบกลุ่มจริง 99.2% (Benchmark ข้อมูลสังเคราะห์)
- ทำ Security ตาม OWASP API Top 10 และวัด Performance ผ่านเป้า p95 ทุก Endpoint (0 Error จาก 9,600 Request)

## Interview notes

- **Why the pickup gain is small:** the dataset has no rider-arrival time, so a large part of order-to-pickup
  variance is invisible to any model. An ablation with real-time load features only reaches MAE 4.48. I chose
  to report the modest gain and show a domain-shift warning instead of tuning on the test day.
- **Why Silhouette alone was not enough:** on random data the weekend flag always split the riders, so
  silhouette "found" groups. The permutation test fixed that (benchmark in `backend/reports/`).
- **What I did not build, and why:** no shift-earnings ML (no per-shift data), no object detection, and no
  public deployment yet. See README → Limitations.

## Sources

| Number | Source |
|---|---|
| 1,286 tests (backend 523, ML 134, CV 38, mobile 591) | `scripts/regression.ps1` run 2026-11-18 (HANDOFF §4.19) |
| 568,546 orders | `docs/DATASET_ANALYSIS.md` |
| MAE 4.509 / 4.636 / 4.479, coverage 81.6% | `ml/README.md` → `ml/reports/pickup_o2p/` |
| CV 0.8804 / 0.8755, 16.5 ms | `cv_service/reports/1.0.0/model_card.md`, HANDOFF §4.11 |
| 1.7% / 99.2% | `backend/reports/work_patterns_benchmark.json`, HANDOFF §4.12 |
| p95 and 9,600 requests | `docs/PERFORMANCE.md`, `backend/reports/perf_p6b.json` |
| 0 known vulnerabilities | `docs/SECURITY_AUDIT.md` |
