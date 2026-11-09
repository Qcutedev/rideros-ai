# Data Sources

This file is the only thing under `ml/data/` that is committed. Every data file (raw, extracted, processed)
stays local and is listed in `.gitignore` (Decisions D1 and D4 in `docs/PROJECT_PLAN.md`).

## 1. Meituan INFORMS TSL Research Challenge (used)

| Item | Value |
|---|---|
| Provider | Meituan, with the INFORMS Transportation Science & Logistics (TSL) Society |
| Repository | https://github.com/meituan/Meituan-INFORMS-TSL-Research-Challenge |
| Pinned commit | `1f9b4288cee5a78d1e5da007fc306bbaa662fc6d` (repo HEAD on 2025-12-03) |
| Challenge page | https://connect.informs.org/tsl/tslresources/datachallenge |
| Documentation used | "Background and Data Description" (2024-03-21, Tables 1–2) and "Supplementary Document" (2024-10-15), both in the repository |
| License | **CC BY-NC 4.0**, plus the provider's own terms in `License.txt` (see below) |
| Local path | `ml/data/raw/meituan_informs_tsl/` (gitignored) |
| How to get it | `python -m uv run rideros-ml download` (downloads from the pinned commit and verifies SHA-256) |

### Files and integrity pins

The pins live in `ml/configs/pickup_o2p.yaml`. `download` fails closed: a file with no pin, or with a hash
that differs from its pin, raises `IntegrityError` before anything is extracted. Only the one named CSV
member is extracted from the zip.

| File | Bytes | SHA-256 |
|---|---|---|
| `License.txt` | 1,961 | `469f53d91ee9d0dbdf7b60146bfdbcee57732db4f2b6bb13c41bfdf28c30daab` |
| `all_waybill_info_meituan_0322.csv.zip` | 38,763,754 | `38b51431a12dd7e73deb4fc750b1275067fbc29cfce2c4b4492339738c988ce2` |
| `all_waybill_info_meituan_0322.csv` (extracted) | 121,698,401 | `1d31aac21e17c11aec6ab0033d4040c03aea5bab1dfd60aa11e74d766bbd2c04` |

The download date and per-file verification time are recorded in `ml/data/raw/meituan_informs_tsl/manifest.json`.

### License terms we rely on

`License.txt` was reviewed by hand on 2026-11-05. Its text was identical to the Phase 0 review. On top of the hash
pin, `rideros-ml validate` checks that these four clauses are present word for word
(`src/rideros_ml/data/license_check.py`):

1. Provided under **Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)**.
2. **"the distribution of this dataset to third parties is not allowed"**, without permission.
3. **"this dataset is intended for non-commercial use only"**, such as academic research, teaching or scientific publishing.
   No permission is granted to use the dataset *or any derivative works* for commercial purposes.
4. Published work based on the dataset must carry this acknowledgement.

### Required acknowledgement

> This research was supported by data provided by Meituan.
>
> 本研究由美团提供数据支持。

The acknowledgement must appear in the project README, in the model card (already generated in
`ml/artifacts/<model>/<version>/model_card.md`), and on the app's Model Information screen.

### What this project does with it

- **Use:** a non-commercial portfolio and educational project.
- **Derived files** (all local and gitignored):
  - `ml/data/processed/orders.parquet`: the order-level modelling table.
  - `ml/artifacts/pickup_o2p/<version>/`: the trained model.
  - `ml/artifacts/restaurant_stats/<version>/`: per-restaurant aggregates only, with no raw rows.
- **Not redistributed:** raw files, the processed table, model artifacts and restaurant aggregates are never committed
  or published. Decision D4 applies until redistribution rights are verified.
- **Committed:** code, configs, and reports that hold summary statistics and figures (`ml/reports/`).
- **Target definition:** the data has no rider-arrival time. The model therefore predicts **order-to-pickup minutes**
  (`fetch_time − platform_order_time`). It does not predict food preparation time or rider waiting time.
- **Privacy:** coordinates in the dataset are integers scaled by 1e6 and shifted uniformly for privacy
  (Supplementary §2.1). The project never tries to undo that shift.

## 2. Personal Pickup Log (planned, user-generated)

Riders using the app record their own arrival and pickup times. This data belongs to each user, lives in the
backend database (Phase 2+), and is never mixed into this directory. See `docs/DATASET_ANALYSIS.md` §6.

## 3. Reviewed and rejected

| Dataset | Reason not used | Evidence |
|---|---|---|
| SkipTheDishes food-preparation-time (github.com/SehajS/food-preparation-time-prediction) | No license (GitHub reports `license: null`, no LICENSE file). Strong signs the data is synthetic, e.g. order volume is flat within 3-hour blocks. No restaurant id. | `docs/DATASET_ANALYSIS.md` §3, `docs/phase0/skipthedishes_synthetic_check.py` |
