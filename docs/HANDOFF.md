# HANDOFF — RiderOS AI

> อัปเดตล่าสุด: 2026-11-09 · สถานะ: **Phase 1 งานครบ — รอผู้ใช้อนุมัติ (ห้ามเริ่ม Phase 2 ก่อนอนุมัติ)**
> Phase 0 + Decisions D1–D7 อนุมัติแล้ว (ดู `docs/PROJECT_PLAN.md` §4)

---

## 1. เสร็จแล้วใน Phase 1

| งาน | ผลลัพธ์ / ไฟล์ |
|---|---|
| บันทึก D1–D7 ลงเอกสาร | `docs/PROJECT_PLAN.md` §4, `DATASET_ANALYSIS.md`, `SYSTEM_ARCHITECTURE.md` |
| D7: Git | `git init -b main` + `.gitignore` — **ยังไม่มี Commit** |
| D3: uv | uv 0.13.7 ติดตั้งผ่าน pip — **ไม่อยู่ใน PATH ให้ใช้ `python -m uv`** |
| ML project | `ml/pyproject.toml`, `ml/uv.lock`, `ml/.venv/` (Python 3.14.6) |
| Config | `ml/configs/pickup_o2p.yaml` (Pin Commit + SHA-256 + Target Rule + Split) |
| ดาวน์โหลด Dataset | `ml/data/raw/meituan_informs_tsl/` (gitignored) — Commit `1f9b4288…`, Hash ตรงกับที่ Pin |
| License Gate | License.txt ตรวจด้วยตาแล้ว เหมือนกับตอน Phase 0; ทั้ง 4 Clause ผ่าน |
| Validation Gate | **PASS** — `ml/reports/data_validation/VALIDATION_REPORT.md` |
| Build | `ml/data/processed/orders.parquet` — 546,226 orders |
| EDA (Train เท่านั้น) | `ml/reports/eda/EDA_REPORT.md` + รูป |
| Smoke test | `train --quick` ผ่าน (ผลอยู่ใน `quick-smoke/` — **ห้ามใช้รายงาน**, gitignored) |

### การตัดสินใจทางเทคนิคใน Phase 1 (บันทึกไว้ในโค้ดและ Config แล้ว)
1. **Ambiguous orders:** ตัด 88 Orders (0.015%) ที่ `platform_order_time` หรือพิกัดผู้รับไม่ตรงกันระหว่าง Waybills
2. **da_id:** ใช้ค่าจาก Waybill ที่ Dispatch ครั้งแรก เพราะ da_id เปลี่ยนได้เมื่อ Re-dispatch (Supplementary §2.6, 1,963 Orders)
3. **Target rule:** 1 ≤ order_to_pickup_min ≤ 120 (ตัดสินจาก Tail ของช่วง Train เท่านั้น) — ตัดไป 29 + 27 แถว
4. **Timezone:** UTC+8 ยืนยันจาก `is_weekend` ที่ตรงกัน 100% (ถ้าใช้ UTC จะตรงแค่ 98.6%)
5. **ไม่ใช้ day-of-week** (Train มีแค่ 6 วัน) ใช้ `is_weekend` แทน
6. **Feature 2 ชุด:** *Deployable* (poi_id, da_id, hour, minute sin/cos, is_weekend) ซึ่ง Backend ส่งให้ได้จริง · *Ablation* (load ร้าน/พื้นที่แบบ real-time + distance) ใช้วัดผลเท่านั้น
7. **Meituan estimate** = Benchmark ไม่ใช่ Feature
8. **ไม่ Refit บน Train+Val:** เพื่อให้ Conformal Calibration บน Val ใช้ได้; Test ประเมินครั้งเดียวหลังเลือกโมเดลแล้ว

---

## 2. เสร็จเพิ่มเมื่อ 2026-11-09

| งาน | ผลลัพธ์ / ไฟล์ |
|---|---|
| Full train (รันใหม่ทั้งหมด, ~29 นาที) | `ml/reports/pickup_o2p/1.0.0/RESULTS.md` + `metrics.json` + รูป; `ml/artifacts/pickup_o2p/1.0.0/` |
| ผล | Selected **xgboost** (Val MAE ต่ำสุด) · Test MAE 4.509 / RMSE 6.061 / R² 0.281 · Baseline POI median 4.636 · Interval 80% → Coverage จริง 81.6% |
| Stats | `ml/artifacts/restaurant_stats/1.0.0/` — 4,938 ร้าน (sufficient 2,741 · limited 1,409 · insufficient 788) |
| Tests | `ml/tests/` 8 ไฟล์ + `conftest.py` — **134 passed** (รวม `artifact`, `data`, `slow`) |
| Docs | `ml/README.md`, `ml/data/SOURCES.md`, `docs/DEVELOPMENT_ROADMAP.md` (Exit Criteria ✔) |
| แก้โค้ดเล็กน้อย | `validate.py`: `.dt.weekday` → `.dt.day_of_week` (Pandas4Warning, ผลเหมือนเดิม); `pyproject.toml`: เพิ่ม marker `slow` |

## 3. งานที่เหลือ

1. ผู้ใช้ตรวจ Phase 1 Report แล้วอนุมัติ
2. Commit แรก — **รอผู้ใช้สั่ง** (ตรวจ `git status` ว่าไม่มี data/artifacts ก่อน)
3. หลังอนุมัติ: Phase 2 ตาม `docs/DEVELOPMENT_ROADMAP.md`

## 4. คำสั่งสำหรับทำต่อ (PowerShell)

```powershell
cd "C:\dev\RiderOS AI\ml"
python -m uv sync                      # สร้าง/ซิงก์ .venv ตาม uv.lock
python -m uv run rideros-ml validate   # (ทางเลือก) ตรวจ Gate ซ้ำ
python -m uv run rideros-ml train      # ~30 นาที (รอบ 2026-11-09: 1,738 s)
python -m uv run rideros-ml stats
python -m uv run pytest                # หลังเขียน Tests แล้ว
```

ลำดับ Pipeline ทั้งหมด: `download → validate → build → eda → train → stats`

## 5. ข้อควรระวัง

- **ห้าม Commit** `ml/data/`, `ml/artifacts/`, ไฟล์ CSV/ZIP ใดๆ (CC BY-NC 4.0 + ห้ามแจกจ่าย; D1/D4)
- ยังไม่มี Git Commit — ถามผู้ใช้ก่อน Commit หรือสร้าง GitHub Repo แบบ Private (D2)
- ผู้ใช้ต้องทำเองก่อน Phase 2–3: `flutter doctor --android-licenses` และเปิด Docker Desktop
- Known data issues (ไม่กระทบโมเดล): Chronology ผิดปกติ 1 แถว (push > dispatch) และ 1 แถว (fetch > arrive); `estimate_meal_prepare_time = 0` มี 9,907 แถว
- ถ้า Shell มี `VIRTUAL_ENV` ของ `ml/.venv` ค้างอยู่ `python` จะชี้ไปที่ venv (ไม่มี uv) → ใช้ `%LOCALAPPDATA%\Python\pythoncore-3.14-64\python.exe -m uv ...` หรือเรียก `ml\.venv\Scripts\rideros-ml.exe` ตรงๆ
- Artifact 1.0.0 มี `git_commit: "no-commit"` ใน `metadata.json` เพราะยังไม่มี Commit — ถ้าต้องการให้ผูกกับ Commit ให้ Train ใหม่หลัง Commit แรก
