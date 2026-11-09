# PROJECT_PLAN.md — RiderOS AI

> Phase 0: Project Analysis & Architecture · วันที่ 2026-11-05
> สถานะ: **Phase 0 อนุมัติแล้ว (2026-11-05)** — Decisions D1–D7 อยู่ใน §4

เอกสารที่เกี่ยวข้อง:
- [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md)
- [DATABASE_DESIGN.md](DATABASE_DESIGN.md)
- [DATASET_ANALYSIS.md](DATASET_ANALYSIS.md)
- [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md)

---

## 1. Project Summary

**RiderOS AI** คือแพลตฟอร์ม Productivity สำหรับ Delivery Rider (Food/Motorcycle/Independent) ประกอบด้วย 4 Modules:

| Module | สิ่งที่ทำ | ลำดับ |
|---|---|---|
| Pickup Intelligence | ทำนายเวลาจาก Order ถึง Pickup ด้วย ML + Restaurant Analytics + บันทึกเวลารอจริง (Personal Pickup Log) | MVP #1 |
| TrueProfit AI | บันทึกรายได้และค่าใช้จ่าย → Net Profit, ต่อชั่วโมง, Trends, Work Patterns | MVP #2 |
| Shift Simulator | จำลองกะทำงานหลาย Scenario แล้วเปรียบเทียบรายได้ ต้นทุน และกำไร **ที่ประมาณการ** | MVP #3 |
| RoadContext AI | ผู้ใช้รายงานเหตุบนถนน + แผนที่ + ตรวจจับ Report ซ้ำ + CV ช่วยแนะนำหมวดหมู่ | Extension |

### Non-goals (สิ่งที่ระบบนี้ไม่ทำ)
- **ไม่ใช่** แอปรับงาน และ **ไม่เชื่อมต่อ** Grab หรือแพลตฟอร์มใด (ช่อง `source_label` เป็นข้อความที่ผู้ใช้พิมพ์เอง)
- **ไม่ทำนาย** รายได้ในอนาคตจากแพลตฟอร์ม; Shift Simulator ให้ค่าประมาณจาก Assumption หรือข้อมูลของผู้ใช้เอง
- **ไม่อ้าง** ว่าทำนายเวลาที่ Rider ต้องรอได้ จนกว่าจะมีข้อมูล Pickup Log ของผู้ใช้เพียงพอ
- **ไม่แนะนำเส้นทาง** และ **ไม่อ้าง** ว่าเป็น Real-time Traffic
- **ไม่ใช้ AI** คำนวณตัวเลขทางการเงิน

---

## 2. Phase 0 Findings

### 2.1 Workspace

| รายการ | ผล |
|---|---|
| `C:\dev\RiderOS AI` | ว่างเปล่าก่อนเริ่ม Phase 0 (ตอนนี้มีแค่ `docs/`) |
| Git repository | **ยังไม่มี** (ไม่ใช่ Git repo) |
| Parent `C:\dev` | ไม่ใช่ Git repo, ไม่มี `package.json` จึงไม่มีอะไรครอบโปรเจกต์ |
| โปรเจกต์อื่น | `C:\dev\web shoping` แยกเป็นโฟลเดอร์ต่างหาก ไม่ได้แตะ |
| Path มีเว้นวรรค | ต้อง Quote Path ในทุกสคริปต์; ชื่อ Package ใช้ `rideros_ai` / `rideros_ml` |

### 2.2 Environment

| Tool | สถานะ | หมายเหตุ |
|---|---|---|
| OS | Windows 11 Home (10.0.26300) | |
| CPU / RAM / Disk | i5-11400H · 15.8 GB · ว่าง 160.5 GB | เพียงพอ |
| GPU | **NVIDIA RTX 3060 Laptop 6 GB** | พอสำหรับ Transfer Learning ขนาดเล็ก (Phase 5) |
| Python | 3.14.6 (มีเวอร์ชันเดียว), pip 26.1.2 | ติดตั้งแล้ว: pandas, numpy, scikit-learn, fastapi · ยังไม่ติดตั้ง: xgboost, catboost, matplotlib, torch, ultralytics, sqlalchemy |
| Wheel compatibility (PyPI) | catboost 1.2.10 (cp314 win_amd64 ✅), torch 2.15.0 (cp314 ✅), xgboost 3.4.1 (py3), ultralytics 8.4.202 (py3) | ต้องยืนยันด้วยการติดตั้งจริงใน Phase 1; ส่วน torch+CUDA ใช้ Index ของ PyTorch |
| uv / conda | ไม่มี | แนะนำติดตั้ง uv (D3) |
| Flutter / Dart | 3.47.0 stable / 3.13.0 | ✅ |
| Android SDK | 36.0.0, platform android-37, build-tools 36.0.0, JDK Temurin 17, adb | ⚠️ **ยังไม่ได้ Accept Android licenses** |
| Chrome / Visual Studio | ไม่มี | ไม่จำเป็น (เป้าหมายคือ Android) |
| Docker | 29.8.2 ติดตั้งแล้ว | ⚠️ **Daemon ยังไม่รัน** (ต้องเปิด Docker Desktop ก่อน Phase 2) |
| psql | ไม่มี | ใช้ผ่าน Container แทน |
| Git / GitHub CLI | 2.55.0 / Login แล้ว (scopes: repo, workflow) | ✅ |
| Node | 24.20.0 | ไม่จำเป็นสำหรับโปรเจกต์นี้ |

### 2.3 Dataset (รายละเอียดใน DATASET_ANALYSIS.md)
- SkipTheDishes: ไฟล์ครบ 6 ไฟล์ · **ไม่มี License** · **ไม่มีข้อมูลร้านอาหาร** · มีหลักฐานว่าเป็น **ข้อมูลสังเคราะห์**
- ทางเลือก Meituan INFORMS TSL: ข้อมูลจริง 568,546 Orders, 4,962 ร้าน, 8 วัน · CC BY-NC 4.0 · ห้ามแจกจ่ายต่อ
- ทั้งสองชุด **ไม่มี** เวลาที่ Rider มาถึงร้าน → จึงเพิ่ม Personal Pickup Log เพื่อเก็บเวลารอจริง

---

## 3. Feasibility Analysis

| Module | ทำได้หรือไม่ | แหล่งข้อมูล | วิธี | ข้อจำกัดที่ต้องแสดงให้ผู้ใช้เห็น |
|---|---|---|---|---|
| **1. Pickup Intelligence** | ✅ ทำได้ (ขึ้นกับ D1) | Meituan (แนะนำ) หรือ SkipTheDishes + Pickup Log ของผู้ใช้ | Regression (LR/RF/XGB/CatBoost) เทียบกับ Baseline; Conformal Interval; Stats ระดับร้าน | Model ฝึกจากข้อมูลต่างประเทศ (จีน 2022 หรือแคนาดา 2019 แบบสังเคราะห์) จึง **ใช้แทนร้านในไทยไม่ได้**; ค่าที่ทำนายคือ Order-to-Pickup ไม่ใช่เวลารอ; ร้านที่มีข้อมูลน้อยกว่าเกณฑ์จะแสดงคำเตือน |
| **2. TrueProfit AI** | ✅ ทำได้เต็มที่ | ข้อมูลของผู้ใช้เอง | สูตรที่ตรวจสอบได้ (DATABASE_DESIGN §3.7) + Trend (Moving Average / Linear Trend) + K-Means เมื่อมี ≥ 30 Sessions | ข้อมูลไม่พอจะซ่อน Pattern Analysis; Working Hours = 0 จะแสดง "—" ไม่ใช่ 0 |
| **3. Shift Simulator** | ✅ แบบ Scenario-based · ⚠️ ML เลื่อนออกไป | Assumption ที่ผู้ใช้กรอก + ประวัติของผู้ใช้ (Revenue/h ตามช่วงเวลา) | Simulation แบบ Deterministic + ช่วง P25–P75 จากประวัติ; ML (CatBoost) เฉพาะเมื่อมีข้อมูลพอและชนะ Baseline | ทุกตัวเลขมี Label "ประมาณการ"; แยก Actual กับ Estimated; ไม่มีข้อมูลของแพลตฟอร์ม |
| **4. RoadContext AI** | ✅ Reports/Map/Dedup · ⚠️ CV มีความเสี่ยงสูง | Crowdsourced Report ของผู้ใช้; CV ใช้ Public Dataset (ต้องตรวจ License) | Rule-based Dedup + Status Machine; Transfer Learning Classifier | AI แค่ "แนะนำหมวดหมู่ + Confidence"; ไม่ใช่ Real-time; ไม่มี Dataset ภาพจากไทย |

### Shift Simulator — โมเดลการคำนวณ (Scenario-based)
```
hours              = duration_minutes / 60
est_orders         = orders_per_hour × hours
est_revenue        = est_orders × income_per_order
est_distance_km    = est_orders × km_per_order
est_fuel_cost      = est_distance_km / fuel_km_per_liter × fuel_price_per_liter
est_depreciation   = est_distance_km × depreciation_per_km
est_expenses       = est_fuel_cost + est_depreciation + other_fixed_cost
est_net_profit     = est_revenue − est_expenses
```
- โหมด `historical`: ใช้ `orders_per_hour` / `income_per_order` จาก Sessions ของผู้ใช้ในช่วงเวลาและประเภทวันที่ตรงกัน (ต้องมี ≥ 5 Sessions ที่ตรงกัน มิฉะนั้นกลับไปใช้ Assumption)
- ทุกค่าที่นำมาใช้ต้องแสดงที่มาใน UI ว่ามาจาก "ค่าที่คุณกรอก" หรือ "ค่าเฉลี่ยจาก N กะที่ผ่านมา"

---

## 4. Decision Log (อนุมัติแล้ว 2026-11-05)

| ID | หัวข้อ | การตัดสินใจที่อนุมัติ | เงื่อนไขที่ต้องปฏิบัติ |
|---|---|---|---|
| **D1** | Dataset ของ Pickup Intelligence | **(ก) Meituan INFORMS TSL + Personal Pickup Log** | ต้องตรวจ Schema, Target Definition, Data Quality และ License **ก่อนเริ่มพัฒนา** (Phase 1 Gate); ห้ามเผยแพร่ Dataset; ปฏิบัติตาม CC BY-NC 4.0 (Non-commercial, Attribution, Acknowledgement "This research was supported by data provided by Meituan.") |
| **D2** | GitHub Repository | เริ่มแบบ **Private** แล้วเปิด Public ใน Phase 7 | ก่อนเปิด Public ต้องตรวจ Secrets, Dataset, Model Artifacts และ License |
| **D3** | Python env | ใช้ **uv** จัดการ Environment และ Dependencies (lockfile) | — |
| **D4** | Model Artifacts | **ไม่เผยแพร่** ใน Public Repository | จนกว่าจะยืนยันสิทธิ์การเผยแพร่ได้; `ml/artifacts/` อยู่ใน `.gitignore` |
| **D5** | Forgot Password | โหมด **Development**: แสดง Reset Link ใน Development Log เท่านั้น | Token เก็บเป็น Hash, มี Expiration, ใช้ได้ครั้งเดียว (Single-use); **ห้ามใช้วิธีนี้ใน Production** (บังคับด้วย Config: ถ้า `ENV=production` แล้วไม่ได้ตั้ง Email Provider ให้ปิด Endpoint) |
| **D6** | CV Library | ใช้ **torchvision** แทน Ultralytics | ตรวจ License แยก 3 ส่วน: Library, Pretrained Weights และ Dependencies |
| **D7** | Git | `git init` + `.gitignore` เป็นงานแรกของ Phase 1 | — |

---

## 5. Risk Register

| # | ความเสี่ยง | โอกาส | ผลกระทบ | การรับมือ |
|---|---|---|---|---|
| R1 | License ของ SkipTheDishes ไม่ชัดเจน | สูง (ยืนยันแล้วว่าไม่มี) | กลาง | ไม่ Commit Data; เสนอ Meituan; หรือขออนุญาตจากเจ้าของ |
| R2 | Synthetic Data ทำให้ Metrics ดูดีเกินจริง | สูง | สูง (ความน่าเชื่อถือของ Portfolio) | ระบุใน Model Card; ใช้ Meituan เป็นหลัก |
| R3 | Domain Shift (จีน/แคนาดา → ไทย) | แน่นอน | กลาง | แสดงข้อจำกัดใน UI; Pickup Log ของผู้ใช้เป็นข้อมูลจริงในบริบทไทย |
| R4 | Data Leakage ใน Pickup Features | กลาง | สูง | Feature Audit ณ t₀; Temporal Split; สถิติย้อนหลังจาก Order ที่ fetch ก่อน t₀ เท่านั้น |
| R5 | Scope 18 หน้า + 4 Modules ใน 13 สัปดาห์ (ทำคนเดียว) | สูง | สูง | Priority + ลำดับการตัด Scope (ROADMAP §3); MVP Freeze ที่ W9 |
| R6 | Docker/Windows: Path มีเว้นวรรค, Daemon ไม่รัน | กลาง | ต่ำ | Quote Path; ตรวจตอนเริ่ม Phase 2 |
| R7 | Python 3.14 กับ Library บางตัว | ต่ำ (มี Wheel แล้ว) | กลาง | ติดตั้งจริงใน W1; ถ้าไม่ได้จะใช้ 3.13 ผ่าน uv |
| R8 | AGPL ของ Ultralytics | กลาง | กลาง | D6 |
| R9 | OSM Tile Usage Policy ใน Production | กลาง | ต่ำ | เปลี่ยน Tile Provider ตอน Deploy |
| R10 | ความเป็นส่วนตัว (พิกัด, รูป, ข้อมูลการเงิน) | กลาง | สูง | ลบ EXIF, ซ่อนผู้รายงาน, มี `DELETE /me`, Log ไม่มีข้อมูลอ่อนไหว |

---

## 6. Definition of Done (ทุก Feature)

- [ ] มี Business Logic จริง (ไม่ใช่ UI เปล่าหรือ Mock)
- [ ] Input Validation ทั้งฝั่ง Client และ Server
- [ ] Error handling + HTTP Status ถูกต้อง
- [ ] Tests (Unit + API/Widget) ผ่าน
- [ ] ไม่มี Secret หรือ Hardcoded Credential
- [ ] ถ้ามีข้อมูลจำลองต้องมี Label "DEMO" ทั้งใน UI และ Docs
- [ ] ทุก Metrics ที่อ้างถึงต้องมาจากการรันจริง และมี Report อ้างอิง
- [ ] เอกสารอัปเดตแล้ว

---

## 7. Next Steps

1. ~~ตัดสินใจ D1–D7~~ (อนุมัติแล้ว 2026-11-05)
2. ผู้ใช้ทำเอง (ต้อง Interactive): `flutter doctor --android-licenses` และเปิด Docker Desktop (ก่อน Phase 2–3)
3. Phase 1 ตาม DEVELOPMENT_ROADMAP.md โดยเริ่มจาก Dataset & License Verification Gate
