# DATASET_ANALYSIS.md — RiderOS AI (Phase 0)

> วันที่ตรวจสอบ: 2026-11-05
> สถานะ: **D1 อนุมัติแล้ว (2026-11-05): ใช้ Meituan INFORMS TSL + Personal Pickup Log** — SkipTheDishes ไม่ถูกใช้ในโปรเจกต์ (เก็บผลการวิเคราะห์ไว้เป็นหลักฐานการตัดสินใจ)
> ตัวเลขทั้งหมดในเอกสารนี้ได้จากการรันสคริปต์ใน `docs/phase0/` กับไฟล์จริง ไม่ได้ยกมาจาก README ของ Repository ต้นทาง (ยกเว้นที่ระบุว่าเป็น "คำอ้างของผู้เขียน Repository")

---

## 1. สรุปผล (TL;DR)

| ประเด็น | SkipTheDishes (Dataset ที่กำหนดใน Prompt) | Meituan INFORMS TSL (ทางเลือกที่เสนอ) |
|---|---|---|
| ไฟล์ 6 ไฟล์ที่ Prompt ระบุ | **มีครบทั้ง 6 ไฟล์** | — |
| License | **ไม่มี License** (GitHub API: `license: null`, ไม่มีไฟล์ LICENSE) | **CC BY-NC 4.0** + ห้ามแจกจ่ายต่อ + ต้องใส่ Acknowledgement |
| ข้อมูลจริงหรือสังเคราะห์ | **มีหลักฐานชัดเจนว่าน่าจะเป็นข้อมูลสังเคราะห์** (ดูหัวข้อ 3.6) | ข้อมูล Operational จริง (Anonymized + พิกัดถูกเลื่อน) |
| ขนาด | Train 80,000 / Test 20,000 orders | 654,343 waybills / 568,546 orders ที่ถูกรับจริง |
| ระยะเวลา | 7 วัน (2019-09-01 ถึง 2019-09-07) | 8 วัน (2022-10-17 ถึง 2022-10-24) |
| ข้อมูลร้านอาหาร | **ไม่มีเลย** (ไม่มี restaurant_id) | มี `poi_id` 4,962 ร้าน (Anonymized ไม่มีชื่อร้าน) |
| ข้อมูลรายการอาหาร | มี 90 เมนู + จำนวน | ไม่มี |
| Target ที่ใช้ได้ | `food_prep_time_minutes` (นาที, จำนวนเต็ม 3–49) | Order-to-Pickup Time (`fetch_time − platform_order_time`) — **ไม่ใช่** Prep Time จริง |
| Rider Arrival Time | ไม่มี | ไม่มี (มีแค่เวลารับงานและเวลารับอาหาร) |
| รองรับ Restaurant Analytics | **ไม่ได้** | **ได้** (ระดับ POI ID) |

**ข้อสรุปหลัก**

1. SkipTheDishes ใช้ฝึก Model "Order Composition → Prep Time" ได้ แต่ **ไม่รองรับ** Feature ฝั่งร้านอาหารใน Module 1 (Restaurant Analytics, Restaurant Behavior, Restaurant Comparison) เพราะไม่มีข้อมูลร้านเลย
2. SkipTheDishes **ไม่มี License** ตามกฎหมายลิขสิทธิ์จึงถือว่าสงวนสิทธิ์ทั้งหมด ห้ามเผยแพร่ข้อมูลนี้ใน Repository ของเรา และการนำมาใช้ก็ยังมีความเสี่ยงอยู่
3. มีหลักฐานหลายข้อว่า SkipTheDishes เป็นข้อมูลสังเคราะห์สำหรับการแข่งขัน ค่า R² สูงๆ ที่ได้จากข้อมูลนี้จึงไม่ได้บอกว่าโมเดลจะใช้ได้กับร้านอาหารจริง
4. Dataset ทั้งสองชุด **ไม่สามารถ** ใช้ทำนาย "เวลาที่ Rider ต้องรอจริง" ได้ เพราะไม่มีเวลาที่ Rider มาถึงร้าน ข้อนี้ตรงกับข้อจำกัดใน Prompt
5. **ข้อเสนอ:** ใช้ Meituan เป็น Dataset หลักของ Module 1 แล้วเพิ่ม **Personal Pickup Log** (Rider บันทึกเวลามาถึงร้านและเวลารับอาหารเอง) เพื่อเก็บข้อมูลเวลารอจริงของผู้ใช้ — **รอการตัดสินใจ (Decision D1)**

---

## 2. วิธีการตรวจสอบ

- ตรวจ Metadata และ License ผ่าน GitHub API (`gh api repos/...`)
- Clone แบบ `--depth 1` ไปที่ Temporary Directory **นอกโปรเจกต์** (ไม่ได้คัดลอกข้อมูลเข้ามาในโปรเจกต์)
- **ไม่ได้รัน Notebook หรือโค้ดใดๆ จาก Repository ต้นทาง** อ่านเฉพาะ CSV/PDF
- Profiling ด้วย Python 3.14.6 + pandas (สคริปต์อยู่ที่ `docs/phase0/`)
- Phase 0 **ยังไม่ได้ Train Model** มีแค่ Descriptive Statistics และ Correlation เพื่อประเมินความเป็นไปได้

ทำซ้ำได้ด้วยคำสั่ง:

```bash
python -I docs/phase0/profile_skipthedishes.py <path-to-cloned-skipthedishes-repo>
python -I docs/phase0/skipthedishes_synthetic_check.py <path-to-cloned-skipthedishes-repo>
python -I docs/phase0/profile_meituan.py <path>/all_waybill_info_meituan_0322.csv
python -I docs/phase0/meituan_coverage.py <path>/all_waybill_info_meituan_0322.csv
```

---

## 3. Dataset A — SkipTheDishes Food Preparation Dataset

### 3.1 Source & License

| รายการ | ค่า |
|---|---|
| Repository | https://github.com/SehajS/food-preparation-time-prediction |
| เจ้าของ | SehajS |
| สร้าง / Push ล่าสุด | 2019-11-16 / 2019-11-21 (ไม่มีการอัปเดตตั้งแต่ปี 2019) |
| Stars | 6 |
| **License** | **ไม่มี** — GitHub API คืนค่า `license: null` และไม่มีไฟล์ LICENSE |
| แหล่งข้อมูลต้นทาง (ตาม README) | ข้อมูลจาก SkipTheDishes สำหรับงาน 2019 Nexus Data Science Competition, University of Manitoba (แคนาดา) |
| เงื่อนไขการใช้ข้อมูลของงานแข่งขัน | **ไม่พบเอกสาร** |

**ผลทางกฎหมาย:** เมื่อไม่มี License ข้อมูลจะอยู่ภายใต้ลิขสิทธิ์ปกติ (All Rights Reserved) และเจ้าของข้อมูลจริงอาจเป็น SkipTheDishes ไม่ใช่เจ้าของ Repository
- **ห้าม** Commit ไฟล์ CSV ใดๆ ของ Dataset นี้ขึ้น GitHub
- ถ้าเลือกใช้ ต้องดาวน์โหลดด้วยสคริปต์จากแหล่งต้นทาง ใช้เพื่อการศึกษาเท่านั้น และระบุข้อจำกัดนี้ใน README
- ทางที่ปลอดภัยที่สุดคือติดต่อเจ้าของ Repository เพื่อขออนุญาต

### 3.2 รายการไฟล์ (ตรวจสอบจาก Git Tree จริง)

| ไฟล์ | ขนาด | แถว × คอลัมน์ | หมายเหตุ |
|---|---|---|---|
| `train_orders_data_with_targets.csv` | 23.4 MB | 80,000 × 23 | ข้อมูลดิบ + Target |
| `test_orders_data_without_targets.csv` | 5.8 MB | 20,000 × 22 | ข้อมูลดิบ ไม่มี Target |
| `test_orders_target.csv` | 0.8 MB | 20,000 × 2 | Target ของ Test ซึ่งให้มาภายหลังการแข่งขัน |
| `menu_items_details_complete.csv` | 33 KB | 90 × 4 | ไฟล์มี 137 บรรทัด เพราะข้อความ `directions` ขึ้นบรรทัดใหม่ |
| `train_clean.csv` | 44.6 MB | 80,000 × 134 | **ผู้เขียน Repository สร้างขึ้นเอง** |
| `test_clean.csv` | 11.1 MB | 20,000 × 133 | **ผู้เขียน Repository สร้างขึ้นเอง** |
| `menu_clean.csv` | 34 KB | 90 × 5 | ผู้เขียน Impute หมวดหมู่ด้วยมือ |
| `final_predictions.csv` | 1.1 MB | 20,000 × 2 | ผลทำนายของผู้เขียน — **ไม่ใช่ผลของเรา** |
| `All_Test_Train_Clean.ipynb`, `model-v1.ipynb`, `prediction_vs_actual_comparison.ipynb` | — | — | Notebook ของผู้เขียน (ไม่ได้รัน) |
| `Poster.pdf`, `prediction_vs_actual.png`, `README.md` | — | — | — |

ไฟล์ทั้ง 6 ไฟล์ที่ Prompt ระบุมีอยู่จริง ส่วน README มีจุดผิด: ระบุชื่อ `train_orders_data_with_targets.csv` สองครั้ง ครั้งที่สองควรเป็นไฟล์ Test

### 3.3 Schema (ข้อมูลดิบ)

| คอลัมน์ | Type | ความหมาย |
|---|---|---|
| `order_id` | string (UUID) | ไม่ซ้ำ (0 duplicates) |
| `item_1` … `item_10` | string (UUID) | รหัสเมนู ช่องที่ไม่ได้ใช้เป็น NaN |
| `quantity_1` … `quantity_10` | int/float | จำนวน มีแค่ค่า 1, 2, 3 |
| `datetime` | string → datetime | เวลาสั่ง (Parse ได้ทุกแถว) |
| `food_prep_time_minutes` | int | **Target** (เฉพาะไฟล์ Train) |

Menu: `menu_item_id`, `title`, `directions`, `category`

### 3.4 Data Quality

| ตรวจสอบ | ผล |
|---|---|
| Duplicate rows / order_id | 0 / 0 (ทั้ง Train และ Test) |
| Train/Test order_id ซ้ำกัน | 0 |
| Test IDs ตรงกับ Target IDs | ตรงกันทั้งหมด |
| Missing ใน `item_k`/`quantity_k` | เป็น **Structural Missing** (Order มีน้อยกว่า k รายการ) ไม่ใช่ข้อมูลเสีย — `item_2` 8,187 → `item_10` 72,063 |
| Menu `category` | Missing 43/90 (47.8%) |
| Menu `title` / `directions` | Missing 1 / 3 |
| Item IDs ใน Orders ที่ไม่อยู่ใน Menu | 0 (Train และ Test) |
| Item ใน Test ที่ไม่เคยเห็นใน Train | 0 |
| ขอบเขตเวลา | Train และ Test อยู่ในสัปดาห์เดียวกัน (2019-09-01 ถึง 09-07) จึงเป็น **Random Split ไม่ใช่ Temporal Split** |

### 3.5 Target: `food_prep_time_minutes`

| สถิติ | Train | Test |
|---|---|---|
| count | 80,000 | 20,000 |
| mean | 25.24 | 25.19 |
| std | 11.06 | 11.01 |
| min / max | 3 / 49 | 3 / 49 |
| median | 25 | 25 |
| p1 / p99 | 6 / 47 | — |
| ค่าที่ไม่ซ้ำกัน | 47 (จำนวนเต็มทั้งหมด) | — |

ไม่มีค่า ≤ 0 และไม่มี Outlier เกิน 49 นาที

Signal เบื้องต้นจาก Train เท่านั้น (ยังไม่ได้ Train Model):
- corr(target, total_quantity) = 0.637
- corr(target, n_items) = 0.458
- ค่าเฉลี่ยตามจำนวนรายการ: 1 รายการ = 14.52 นาที → 10 รายการ = 31.46 นาที (เพิ่มขึ้นแบบ Monotonic)

### 3.6 หลักฐานว่าเป็นข้อมูลสังเคราะห์ (Synthetic)

| # | ข้อสังเกต | ทำไมผิดปกติ |
|---|---|---|
| 1 | จำนวนรายการต่อ Order กระจาย **เท่ากันเกือบพอดี** ตั้งแต่ 1 ถึง 10 (≈8,000 orders ต่อค่า) | Order จริงส่วนใหญ่มี 1–3 รายการ |
| 2 | จำนวน Order ต่อชั่วโมง **คงที่ภายในแต่ละช่วง 3 ชั่วโมง** เช่น 00:00/01:00/02:00 = 1,358/1,301/1,312 และ 18:00/19:00/20:00 = 7,448/7,494/7,633 | ข้อมูลจริงจะมีการเปลี่ยนแปลงต่อเนื่อง ไม่ใช่เป็นขั้นบันได |
| 3 | ค่าเฉลี่ย Target ก็เปลี่ยนเป็นขั้นบันไดทุก 3 ชั่วโมงเช่นกัน | เหมือนถูกสร้างจากกฎตามช่วงเวลา |
| 4 | วันในสัปดาห์ไม่มีผลต่อ Target (25.09–25.37) ทั้งที่ปริมาณ Order ต่างกันถึง 3 เท่า (พฤหัสบดี 20,752 / อาทิตย์ 6,407) | ร้านจริงที่ยุ่งขึ้นควรช้าลง |
| 5 | "เมนู" เป็น **สูตรอาหาร** (title + วิธีทำ เช่น "Teriyaki Steak — Marinate for at least 1 hour...") | ไม่ใช่เมนูของร้านอาหาร |
| 6 | Order ที่มีรายการเดียว: ใน (item, quantity) เดียวกัน Target มี std เพียง ≈1.6–1.9 นาที (median 1.86) | Target ≈ ฟังก์ชันตายตัว + Noise เล็กน้อย |
| 7 | ไม่มีร้านอาหาร ราคา หรือพิกัดเลย | Dataset Operational จริงมักมีข้อมูลเหล่านี้ |

**ข้อสรุป:** ข้อมูลน่าจะถูกสร้างขึ้นสำหรับการแข่งขัน (ยืนยัน 100% ไม่ได้ เพราะไม่มีเอกสารจากผู้จัดงาน) ข้อมูลยังใช้สาธิต ML Pipeline ได้ แต่ห้ามอ้างว่าโมเดลเรียนรู้พฤติกรรมร้านอาหารจริง

> README ของ Repository อ้างว่าได้ R² = 0.96 และ RMSE = 2.24 — นี่เป็น **คำอ้างของผู้เขียน Repository ที่เรายังไม่ได้ตรวจสอบ** และห้ามนำมาใช้เป็นผลการทดลองของเรา ค่านี้สอดคล้องกับข้อ 6 ที่ Noise ต่ำมาก

### 3.7 Feature ที่ Prompt ต้องการ เทียบกับข้อมูลที่มีจริง

| Feature ที่ Prompt พิจารณา | มีข้อมูลหรือไม่ | หมายเหตุ |
|---|---|---|
| Total Items | ✅ | นับ `item_k` ที่ไม่เป็น NaN |
| Total Quantity | ✅ | ผลรวม `quantity_k` |
| Number of Categories | ⚠️ | ต้องใช้ Menu category ซึ่ง Missing 47.8% ส่วนฉบับ Clean ผู้เขียน Impute ด้วยมือ (ต้องตรวจสอบหรือทำใหม่เอง) |
| Restaurant Information | ❌ | ไม่มี |
| Order Information | ✅ | รายการ + จำนวน |
| Order Value | ❌ | ไม่มีราคา |
| Time Features | ✅ | hour/weekday (แต่เป็น Pattern สังเคราะห์) |

**ไฟล์ `train_clean.csv` / `test_clean.csv` ไม่ควรนำมาใช้:**
- มี `order_id_tok2..4` (ตัด UUID เป็นท่อนๆ) ซึ่งเป็น Feature ที่ไม่มีความหมาย และเสี่ยงทำให้ Overfit
- มีคอลัมน์ชื่อ `None` ที่เกิดจากการแปลง NaN
- ไม่มีหลักฐานว่าตอนสร้าง Feature เลี่ยง Data Leakage หรือไม่

**ข้อเสนอ:** สร้าง Feature Pipeline ใหม่จากไฟล์ดิบทั้งหมด

### 3.8 Data Leakage — SkipTheDishes

- ทุก Feature (รายการ, จำนวน, เวลาสั่ง) รู้ได้ ณ เวลาสั่ง จึงไม่มี Leakage ด้านเวลา
- ความเสี่ยงที่เหลือ: การ Encode `item_k` แบบ Positional แทนที่จะเป็น Bag-of-items ควรใช้ Bag-of-items (จำนวนต่อเมนู)
- Validation: Train/Test เป็นช่วงเวลาเดียวกัน จึงวัดได้แค่ Interpolation ภายในสัปดาห์ ไม่ใช่การทำนายอนาคต

### 3.9 Verdict — Dataset A

**ใช้ได้แบบมีเงื่อนไข** สาธิต Regression Pipeline ได้ (Bag-of-items → Prep Time) แต่:
- ไม่รองรับ Restaurant Analytics ทั้งหมด
- มีความเสี่ยงด้าน License
- น่าจะเป็นข้อมูลสังเคราะห์ จึงนำไปใช้กับร้านอาหารในไทยไม่ได้

---

## 4. Dataset B — Meituan INFORMS TSL Research Challenge (ทางเลือก)

### 4.1 Source & License

| รายการ | ค่า |
|---|---|
| Repository | https://github.com/meituan/Meituan-INFORMS-TSL-Research-Challenge (เดิมชื่อ `meituan_informs_data`) |
| Push ล่าสุด | 2025-12-03 |
| ผู้จัดทำ | Meituan ร่วมกับ INFORMS Transportation Science & Logistics Society (Tsinghua, SMU) |
| **License** (`License.txt`) | **CC BY-NC 4.0** — ห้ามใช้เชิงพาณิชย์; **ห้ามแจกจ่าย Dataset ต่อโดยไม่ได้รับอนุญาต**; ต้องใส่ Acknowledgement: *"This research was supported by data provided by Meituan."* |
| เอกสารประกอบ | Background & Data Description (2024-03-21), Supplementary Document (2024-10-15), Paper Wang et al. 2025 |

**ผลต่อโปรเจกต์:** Portfolio ที่ไม่ใช่เชิงพาณิชย์ใช้ได้ แต่:
- **ห้าม** Commit ข้อมูลดิบขึ้น GitHub ให้ใช้สคริปต์ดาวน์โหลดจากต้นทาง
- ต้องใส่ Attribution และ Acknowledgement ใน README และในหน้า Model Information ของแอป
- ถ้าโปรเจกต์ถูกนำไปใช้เชิงพาณิชย์ในอนาคต จะใช้ Dataset และ Derivative นี้ไม่ได้
- ประเด็นที่ต้องตัดสินใจ: Model Artifact และค่าสถิติรวม (Aggregate) ของร้านเป็น Derivative Work ที่ CC BY-NC อนุญาตเมื่อไม่ใช่เชิงพาณิชย์ แต่เพื่อความปลอดภัย **ไม่ควรเผยแพร่ Model Artifact ใน Public Repo** (ดู Decision D4 ใน PROJECT_PLAN.md)

### 4.2 ไฟล์

| ไฟล์ | ขนาด | หมายเหตุ |
|---|---|---|
| `all_waybill_info_meituan_0322.csv.zip` | 38.8 MB (แตกแล้ว 121.7 MB) | ไฟล์หลัก 654,343 แถว × 24 คอลัมน์ |
| `courier_wave_info_meituan.csv` | 12.7 MB | Wave ของ Courier (206,748 แถวตามเอกสาร) |
| `dispatch_waybill_meituan.csv` | 0.5 MB | Input สำหรับปัญหา Dispatch |
| `dispatch_rider_meituan.csv` | 4.2 MB | Input สำหรับปัญหา Dispatch |
| PDF 3 ไฟล์ | — | เอกสารประกอบ |

Module 1 ใช้แค่ไฟล์ `all_waybill_info`

### 4.3 Schema (นิยามจากเอกสารทางการ + Supplementary)

| คอลัมน์ | ความหมาย | ใช้เป็น Feature ได้ไหม (ณ เวลาสั่ง) |
|---|---|---|
| `dt` | วันที่สร้าง Order | ✅ |
| `order_id` | รหัส Order (หนึ่ง Order มีได้หลาย Waybill) | ID |
| `waybill_id` | สร้างใหม่ทุกครั้งที่ Order เข้าสู่การ Dispatch หรือถูกปฏิเสธ | ❌ |
| `da_id` | Business District (23 พื้นที่ อาจซ้อนกันได้) | ✅ |
| `poi_id` | รหัสร้าน (Anonymized) | ✅ |
| `sender_lat/lng`, `recipient_lat/lng` | พิกัด × 1e6 **ถูกเลื่อน (Shift) แต่ไม่ได้ Scale** ระยะทางยังใช้ได้ | ✅ (ระยะทาง) |
| `platform_order_time` | เวลาสร้าง Order (Unix s) | ✅ เวลาอ้างอิง t₀ |
| `is_prebook`, `is_weekend` | Flags | ✅ |
| `estimate_arrived_time` | เวลาที่สัญญาว่าจะส่งถึงลูกค้า | ⚠️ ยกเว้น เพราะแอปของเราไม่มีค่านี้ |
| `estimate_meal_prepare_time` | **ค่าประมาณ** เวลาอาหารพร้อมจากระบบ Meituan (Supplementary §2.5: fetch อาจเร็วกว่าค่านี้ได้) | ⚠️ **ใช้เป็น Benchmark** ไม่ใช่ Feature |
| `order_push_time` | Order เข้าระบบ Dispatch | ไม่จำเป็น |
| `dispatch_time`, `courier_id`, `grab_lat/lng`, `is_courier_grabbed`, `grab_time` | เหตุการณ์หลัง Assign | ❌ **Leakage** |
| `fetch_time` | Rider รับอาหาร | ❌ ใช้สร้าง Target เท่านั้น |
| `arrive_time` | ส่งถึงลูกค้า | ❌ Leakage |

### 4.4 Profiling

| ตรวจสอบ | ผล |
|---|---|
| Missing (NaN) | 0 ในทุกคอลัมน์ แต่เวลาที่ไม่มีอยู่จริงถูกแทนด้วย `0` |
| Duplicate rows | 0 |
| Unique | order 568,546 · waybill 654,343 · poi 4,962 · courier 4,955 · da 23 · dt 8 |
| Orders/วัน | 77,027 – 89,205 |
| Waybill ที่ grab/fetch = 0 | 85,797 แถว — คือ Waybill ที่ถูกปฏิเสธ (Supplementary §2.4) |
| `estimate_meal_prepare_time = 0` | 9,907 แถว |
| Prebook | 3.68% |
| พิกัด | lng 174.48–174.99, lat 45.76–46.07 (ถูกเลื่อน จึงระบุสถานที่จริงไม่ได้) |

### 4.5 ช่วงเวลาที่คำนวณได้ (นาที, เฉพาะแถวที่มีค่าครบ)

| ช่วง | median | p5 / p95 | หมายเหตุ |
|---|---|---|---|
| Order → Pickup (`fetch − platform_order`, ไม่รวม Prebook) | **13.2** | p1 3.38 / p99 39.05 | max 557 นาที; > 120 นาที = 0.005% |
| Order → ค่าประมาณเวลาอาหารพร้อมของ Meituan | 12.27 | 0.13 / 20.4 | |
| Pickup − ค่าประมาณของ Meituan | 0.88 | −6.83 / 23.88 | Rider รับอาหารใกล้กับเวลาที่ระบบประมาณไว้ |
| Rider รับงาน → รับอาหาร (`fetch − grab`) | 9.03 | 2.55 / 21.9 | รวมเวลาเดินทางมาร้าน + เวลารอ ซึ่ง**แยกจากกันไม่ได้** |
| รับอาหาร → ส่งถึง (`arrive − fetch`) | 13.45 | 3.9 / 33.6 | |

### 4.6 ความครอบคลุมระดับร้าน (สำหรับ Restaurant Analytics)

| เกณฑ์จำนวน Order ที่ถูกรับต่อร้าน | จำนวนร้าน | ครอบคลุม % ของ Orders |
|---|---|---|
| ≥ 10 | 3,733 | 99.2% |
| ≥ 30 | 2,788 | 96.2% |
| ≥ 100 | 1,567 | 84.0% |
| ≥ 500 | 222 | 30.4% |

ถ้าตั้งเกณฑ์ขั้นต่ำ 30 Orders ต่อร้านก่อนแสดง Analytics จะได้ 2,788 ร้าน ร้านที่ต่ำกว่าเกณฑ์จะแสดงคำเตือน "ข้อมูลไม่เพียงพอ"

### 4.7 Target ที่เสนอ และสิ่งที่ "ห้ามอ้าง"

- **Target:** `order_to_pickup_min = (fetch_time − platform_order_time) / 60` ใช้ Waybill ที่ถูกรับจริงของแต่ละ Order และไม่รวม Prebook
- ค่านี้ **ไม่ใช่** Food Preparation Time จริง (Dataset ไม่มีเวลาที่อาหารพร้อมจริง) และ **ไม่ใช่** Rider Waiting Time (ไม่มีเวลาที่ Rider มาถึงร้าน)
- ค่านี้คือ "เวลาตั้งแต่ลูกค้าสั่งจนอาหารถูกรับจากร้าน" ซึ่งเกิดจากทั้งการเตรียมอาหารของร้านและการมาถึงของ Rider
- ใน UI จะใช้ชื่อ "Order-to-Pickup Time (Dataset)" พร้อมคำอธิบาย

### 4.8 Verdict — Dataset B

**เหมาะกว่าสำหรับ Module 1** เพราะ:
- เป็นข้อมูลจริง ขนาดใหญ่
- มีรหัสร้าน รองรับ Restaurant Analytics / Peak Hour / Distribution / Comparison
- Split ตามเวลาได้ (Temporal Split)
- License ชัดเจน
- มีค่าประมาณของ Meituan ให้ใช้เป็น Industry Benchmark

ข้อจำกัด:
- อยู่ในจีน ใช้แทนร้านในไทยโดยตรงไม่ได้
- ไม่มีชื่อร้าน ไม่มีรายการอาหาร
- ห้ามแจกจ่ายข้อมูล

---

## 5. ตารางเปรียบเทียบกับ Requirement ของ Module 1

| Requirement | A: SkipTheDishes | B: Meituan | Personal Pickup Log (ข้อมูลผู้ใช้) |
|---|---|---|---|
| Predict Food Preparation Time | ✅ (Synthetic) | ⚠️ ได้แค่ Order-to-Pickup | ⚠️ ได้ Rider Wait จริงเมื่อมีข้อมูลพอ |
| Restaurant Preparation Analytics | ❌ | ✅ (POI ID) | ✅ (ร้านของผู้ใช้เอง) |
| Restaurant Behavior Analysis | ❌ | ✅ | ✅ |
| Preparation Time Distribution | ✅ | ✅ | ✅ |
| Peak Hour Analysis | ⚠️ Synthetic | ✅ | ✅ เมื่อมีข้อมูลพอ |
| Restaurant Performance Comparison | ❌ | ✅ | ✅ |
| Prediction History | ✅ (เก็บใน DB ของเรา) | ✅ | ✅ |
| Real Rider Waiting Time | ❌ | ❌ | ✅ **ทางเดียวที่ได้ค่าจริง** |
| ใช้กับร้านในไทยได้ | ❌ | ❌ | ✅ |

---

## 6. ทางเลือก (Decision D1) — **อนุมัติทางเลือก "B + Log" เมื่อ 2026-11-05**

| ทางเลือก | รายละเอียด | ข้อดี | ข้อเสีย |
|---|---|---|---|
| **B + Log (แนะนำ)** | ML หลักใช้ Meituan + Personal Pickup Log แบบ Statistical | ครบทุก Feature ของ Module 1, ข้อมูลจริง, License ชัด | ต้องเปลี่ยนจาก Dataset ที่ Prompt กำหนด, ห้ามแจกจ่าย Data |
| A + B + Log | เพิ่ม Model ที่สองจาก SkipTheDishes สำหรับสาธิต "Order Composition" | Resume มีโมเดล 2 ประเภท | งานเพิ่ม ~1 สัปดาห์, ความเสี่ยง License ของ A |
| A + Log | ตามที่ Prompt กำหนด | ตรงกับแผนเดิม | ไม่มี Restaurant Analytics จาก Dataset, Synthetic, ไม่มี License |

---

## 7. ML Protocol ที่เสนอสำหรับ Phase 1 (ถ้าเลือก B)

1. **Acquisition:** สคริปต์ `ml/scripts/download_meituan.py` ดาวน์โหลดจาก GitHub ต้นทาง ตรวจ SHA-256 แล้วเก็บไว้ใน `ml/data/raw/` (gitignored)
2. **Order-level table:** เลือก Waybill ที่ `is_courier_grabbed=1` และ `fetch_time>0` ต่อ Order (ตรวจว่าแต่ละ Order มีได้แค่ 1 Waybill ที่ถูกรับ) แล้วตัด Prebook ออก
3. **Validation (Pandera หรือ Assertion):**
   - เวลาต้องเรียงลำดับถูกต้อง (`order ≤ push ≤ grab ≤ fetch ≤ arrive`)
   - Target อยู่ในช่วง (0, 120] นาที โดย > 120 = 0.005% ต้องตัดสินใจว่าจะ Exclude แล้วบันทึกเหตุผล
4. **Temporal split:** Train = 2022-10-17 ถึง 10-22 (6 วัน), Validation = 10-23, Test = 10-24 (ห้ามแตะ Test จนถึงการประเมินครั้งสุดท้าย)
5. **Features ณ t₀:**
   - เวลา: hour, minute-of-day (cyclic), weekday, is_weekend
   - พื้นที่และร้าน: `da_id`, `poi_id`
   - ระยะทาง sender→recipient (Haversine)
   - สถิติย้อนหลังของร้าน: median และ count ของ order-to-pickup **จาก Order ที่ fetch เสร็จก่อน t₀ เท่านั้น**
   - Load ของร้านและพื้นที่: จำนวน Order ที่เข้ามาใน 15/30/60 นาทีก่อน t₀
6. **Baselines:**
   - (a) Global median
   - (b) Per-POI historical median (จาก Train)
   - (c) Benchmark: ค่าประมาณของ Meituan (`estimate_meal_prepare_time − platform_order_time`) — ระบบที่ Meituan ใช้จริง ไม่ใช่โมเดลของเรา
7. **Models:** Linear Regression (One-hot/Target encoding) → Random Forest → XGBoost → CatBoost (Native Categorical)
8. **Tuning:** ใช้เฉพาะ Validation Set (Optuna หรือ Randomized Search) แล้ว Refit บน Train+Val และประเมินบน Test **ครั้งเดียว**
9. **Metrics:** MAE (หลัก), RMSE, R², MAE แยกตามช่วงเวลาและขนาดร้าน, Actual vs Predicted, Residual Plot, Error Distribution
10. **Prediction Range:** Split Conformal Prediction บน Validation แล้วรายงาน Empirical Coverage บน Test (เช่น ช่วง 80%)
11. **Export:** `model.cbm` (หรือ `.joblib`) + `preprocessor.joblib` + `feature_schema.json` + `metrics.json` + `model_card.md` + `version` (SemVer + Git SHA + data hash)

ถ้าเลือก A ด้วย: ใช้ Bag-of-items (90 คอลัมน์) + Category counts + n_items + total_qty + time features เป็น Features; ใช้ไฟล์ Test เดิมเป็น Holdout (Random Split ภายในสัปดาห์) และ Group K-Fold ไม่จำเป็นเพราะไม่มีร้าน

---

## 8. Data Governance

- `ml/data/` ทั้งหมดอยู่ใน `.gitignore` ห้าม Commit CSV/ZIP ของทั้งสอง Dataset
- ทุก Dataset มี `ml/data/SOURCES.md`: URL, Commit SHA ที่ดาวน์โหลด, วันที่, License, SHA-256 ของไฟล์
- ถ้าใช้ Meituan ต้องมี Acknowledgement ใน README + หน้า Model Info
- Phase 0 ไม่ได้คัดลอก Dataset เข้ามาในโปรเจกต์ (อยู่ใน Temporary Directory นอกโปรเจกต์เท่านั้น)

---

## 9. Module อื่น: แหล่งข้อมูล

### TrueProfit AI / Shift Simulator
- **ไม่พบ Public Dataset** ที่มีรายได้และต้นทุนรายชั่วโมงของ Rider ในไทย และไม่ควรสร้างข้อมูลปลอม
- ใช้ **ข้อมูลของผู้ใช้เอง** + สูตรที่ตรวจสอบได้ ส่วน Shift Simulator เริ่มจาก Scenario-based Simulation
- `courier_wave_info` ของ Meituan มีจำนวน Order ต่อ Wave ของ Courier สามารถใช้เป็น Prior ของ "Orders per Active Hour ตามช่วงเวลา" ได้ แต่ **ไม่มีข้อมูลรายได้** และเป็นข้อมูลจีน จึงไม่แนะนำใน MVP
- Demo Data: มีเฉพาะใน Demo Account, Flag `is_demo=true` และแสดงป้าย "DEMO DATA" ใน UI

### RoadContext AI (ตรวจ License เต็มรูปแบบแล้ว 2026-11-12, Phase 5 P5c · รายละเอียด + SHA-256 ใน `cv_service/data/SOURCES.md`)

| Dataset | งาน | License (ตรวจจากแหล่งทางการ) | สถานะ |
|---|---|---|---|
| RDD2022 (Road Damage Detection, 47,420 ภาพ, 6 ประเทศ ไม่มีไทย) | Detection: รอยแตกตามยาว/ขวาง/หนังจระเข้, หลุมบ่อ → ใช้เป็น Classification `road_damage` / `other` (China_MotorBike, Czech, India, United_States) | **CC BY 4.0** (figshare record 21431547 v1, field `license` ของ API) | ✅ ใช้ |
| AlleyFloodNet (Kaggle v1, 1,110 ภาพ) | Classification น้ำท่วมระดับพื้นดิน → `flooding` / `other` | **CC BY 4.0** (Metadata ของ Kaggle dataset) · ภาพบางส่วนผู้เผยแพร่ไม่ได้ถ่ายเอง | ✅ ใช้ |
| Flood10k (Mendeley) | Binary flood/normal 10,419 ภาพ → ใช้เฉพาะ `flooded` | **CC BY-NC 4.0** (หน้า Mendeley + README) · ภาพมาจาก Twitter/Google | ✅ ใช้ (ไม่ใช่เชิงพาณิชย์ → โมเดลเป็น Non-commercial) |
| FloodNet | ภาพจากโดรน (UAV) | — | ❌ มุมมองไม่ตรงกับภาพที่ Rider ถ่าย |
| Road Closure / Obstacle | — | ไม่พบ Dataset เฉพาะที่เหมาะสม | ใช้หมวดหมู่ที่ผู้ใช้เลือก + กฎ (Rule-based) |

**ข้อควรระวังด้าน License ของโมเดล:**
- Ultralytics YOLO (Library + Weights) เป็น **AGPL-3.0** ถ้าให้บริการผ่าน Network ต้องเปิด Source ทั้งระบบภายใต้ AGPL หรือซื้อ Enterprise License
- **D6 อนุมัติแล้ว:** ใช้ torchvision (BSD-3) เช่น MobileNetV3/EfficientNet สำหรับ Classification
- Phase 5 ต้องตรวจ License **แยกกัน 3 ส่วน**: (1) Library torchvision, (2) Pretrained Weights แต่ละตัว (เช่น ImageNet weights อาจมีเงื่อนไขต่างจาก Library), (3) Dependencies ทั้งหมดใน Image ของ CV Service
  → **ตรวจครบแล้ว 2026-11-12:** (1) torchvision BSD-3-Clause ✅ (2) MobileNetV3-Large `IMAGENET1K_V2` ไม่มี License ของตัวเอง เงื่อนไข ImageNet = ไม่ใช่เชิงพาณิชย์/การศึกษา ✅ สำหรับโปรเจกต์นี้ (3) Package ใน Image `cv` ทุกตัวเป็น MIT/BSD/Apache-2.0/PSF ไม่มี Copyleft ✅ · ผลโมเดล: `cv_service/reports/1.0.0/model_card.md`

แหล่งอ้างอิงที่ใช้สำรวจ:
- [TSL-Meituan Data Challenge](https://connect.informs.org/tsl/tslresources/datachallenge)
- [RDD2022 arXiv](https://arxiv.org/abs/2209.08538)
- [RDD2022 Dataset Ninja](https://datasetninja.com/road-damage-detector)
- [RDD2022 Roboflow](https://universe.roboflow.com/rdd2022/road-damage-iztzn)
- [AlleyFloodNet preprint](https://www.preprints.org/manuscript/202504.0154)
- [Flood10k](https://data.mendeley.com/datasets/4sgcd7zdsp/1)
