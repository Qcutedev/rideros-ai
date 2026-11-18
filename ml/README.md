# rideros-ml — order-to-pickup ML pipeline (case study)

This is the offline ML pipeline that was behind RiderOS AI's *Pickup Intelligence* module. It downloads and
validates the Meituan INFORMS TSL dataset, builds a leakage-safe order table, trains and compares models, and
exports a versioned artifact.

> **Not used by the app since 2026-11-18.** Pickup Intelligence was removed from the app and the backend
> (`docs/HANDOFF.md` §4.20): the data is from one Chinese city, there is no Thai data to retrain on, and the
> delivery platforms already show their own preparation-time estimates. The pipeline, its tests and reports stay
> here as a case study; nothing in `backend/` installs or loads this package any more.

> **What the model predicts:** **order-to-pickup minutes**, i.e. the minutes from order creation
> (`platform_order_time`) to rider pickup (`fetch_time`) for non-prebook orders at restaurants in the dataset.
> It is **not** food preparation time and **not** rider waiting time. The dataset has no rider-arrival time
> (`docs/DATASET_ANALYSIS.md` §4.7).

Data source, license and integrity pins: [`data/SOURCES.md`](data/SOURCES.md).
Acknowledgement: *This research was supported by data provided by Meituan.*

---

## Setup

Requires Python 3.14 and [uv](https://docs.astral.sh/uv/). On this machine uv is installed through pip and is not
on `PATH`, so call it as `python -m uv`.

```powershell
cd ml
python -m uv sync            # creates .venv from uv.lock (runtime + dev + train groups)
```

Dependencies are split so the backend can install this package for serving only:

- Runtime (`[project] dependencies`): what loading and calling `pipeline.joblib` needs (pandas, numpy, pyarrow,
  scikit-learn, xgboost, joblib, pyyaml). On Linux it is `xgboost-cpu` (no CUDA/NCCL wheels); elsewhere `xgboost`.
- `train` group: catboost, optuna, matplotlib (training, tuning and report figures only).
- `dev` group: pytest, ruff.

`[tool.uv] default-groups = ["dev", "train"]`, so a plain `uv sync` here still installs everything. The backend
installs `rideros-ml` as a path dependency (`backend/pyproject.toml`) and pins the library versions recorded in
`metadata.json` -> `libraries`.

## Pipeline

Run the stages in this order. Each one reads the previous stage's output.

```powershell
python -m uv run rideros-ml download   # pinned commit + SHA-256 verification -> data/raw/ (fails closed)
python -m uv run rideros-ml validate   # license clauses + schema/quality gate -> reports/data_validation/
python -m uv run rideros-ml build      # order table -> data/processed/orders.parquet (refuses if gate failed)
python -m uv run rideros-ml eda        # train-period EDA -> reports/eda/
python -m uv run rideros-ml train      # baselines, models, tuning, single test eval, export (~40-60 min)
python -m uv run rideros-ml stats      # per-restaurant aggregates -> artifacts/restaurant_stats/<version>/
```

- `train --quick` is a smoke test that runs on subsamples with 2 tuning trials (~1 min). It writes to
  `quick-smoke/`, which is gitignored. **Never report its numbers.**
- `hashes` downloads the files and prints their SHA-256 without enforcing pins. Use it only to bootstrap a new pin
  after you have reviewed `License.txt` by hand.
- Configuration lives in `configs/pickup_o2p.yaml`: the dataset pin, target rule, split dates, feature sets, tuning
  budget, conformal alpha and model version.

## Layout

```
ml/
  configs/pickup_o2p.yaml     experiment config (single source of truth)
  src/rideros_ml/
    data/                     download + pins, license gate, schema, validation, build
    features/                 FeatureFrame (column guard), encoders, inference row builder
    models/                   baselines, candidates, Optuna tuning, metrics, training orchestration
    intervals/                split conformal prediction intervals
    evaluation/ eda/          plots and the EDA report
    export/                   artifact writer + model card
    analytics/                restaurant aggregates for the app
  tests/                      pytest suite
  data/                       raw + processed data (gitignored, except SOURCES.md)
  artifacts/                  model + stats artifacts (gitignored, Decision D4)
  reports/                    validation, EDA and model reports (committed; summary statistics only)
```

## Method

**Unit of analysis.** One row per picked-up, non-prebook order. 88 orders (0.015%) are dropped because their t0 or
recipient coordinates conflict across waybills. The target rule `1 ≤ y ≤ 120` minutes was chosen from train-period
tails only, and the same rule applies to every split.

**Split.** The split is temporal, by local date (UTC+8, confirmed by a 100% match with `is_weekend`):
train ≤ 2022-10-22 (10-17..22, plus 14 orders created late on 10-16), validation 10-23, test 10-24. The test day is scored once, in
`models/train.py::run_training` stage 3. That happens after the selected model and the conformal calibration are
fixed from validation data, and both timestamps are recorded in `metrics.json`.

**Features.**

| Set | Columns | Used for |
|---|---|---|
| Deployable | `poi_id`, `da_id`, `hour`, `minute_sin`, `minute_cos`, `is_weekend` | the exported model; the backend can supply every value |
| Ablation | deployable + `poi_orders_last_30m`, `da_orders_last_30m`, `poi_open_orders`, `distance_km` | measurement only; needs live platform data RiderOS does not have |

- Day of week is not used because train covers only 6 days. `is_weekend` stands in for it.
- `da_id` comes from the order's *first dispatched* waybill, because `da_id` can change on re-dispatch.
- Meituan's `estimate_meal_prepare_time` is reported as a **benchmark**, never used as a feature.
- The per-feature leakage review is in each `RESULTS.md`.

**Leakage controls in code.**
- `FeatureFrame` refuses any post-t0, target or platform-estimate column.
- `poi_id` target encoding is cross-fitted (`sklearn.TargetEncoder`, 5-fold).
- CatBoost uses ordered target statistics with `has_time=True` on time-sorted rows.
- Load features count only orders in `[t0 − 30 min, t0)` and orders still open at t0.

**Models.** The baselines are global median and per-restaurant median. The candidates are linear regression, random
forest, XGBoost and CatBoost; XGBoost and CatBoost are tuned with Optuna (TPE) on validation MAE. The selected model
is the deployable model with the lowest validation MAE, and baselines are eligible. A CatBoost model on the ablation
set shows how much the non-deployable signals would add.

**Uncertainty.** The interval is split conformal with asymmetric residual quantiles, 80% nominal, calibrated on the
validation day. Coverage is *measured* on the test day and reported, because exchangeability across days is an
assumption.

## Results

Version 1.0.0 (run 2026-11-09). Test day 2022-10-24, n = 64,701, evaluated once:

| Model | Test MAE (min) | Test RMSE | Test R² |
|---|---|---|---|
| Global median (baseline) | 5.274 | 7.227 | −0.022 |
| Per-restaurant median (baseline) | 4.636 | 6.399 | 0.199 |
| **XGBoost, deployable features (selected by validation MAE)** | **4.509** | **6.061** | **0.281** |
| CatBoost, + real-time load features (ablation, not deployable) | 4.479 | 6.011 | 0.293 |

The 80% conformal interval covers 81.6% of test orders (mean width 14.95 min). For restaurants unseen in train
(215 orders) coverage drops to 65.1%. The deployable model beats the per-restaurant median by 0.127 min MAE (2.7%).
Most of the remaining error comes from factors this data cannot capture, such as rider arrival.

See `reports/pickup_o2p/<version>/RESULTS.md`. It holds the full comparison table (baselines, every candidate, the
ablation model and the Meituan benchmark), interval coverage, segment errors, figures and the run log.
Every number there comes from an actual `rideros-ml train` run.

## Artifact

`artifacts/pickup_o2p/<version>/` holds `pipeline.joblib`, `preprocessor.joblib`, the native model file,
`feature_schema.json`, `conformal.json`, `metrics.json`, `metadata.json` and `model_card.md`.
`metadata.json` records the seed, library versions, data hashes, git commit and the SHA-256 of every binary.

> **Security:** loading joblib/pickle runs code. Only load artifacts this pipeline produced, and check the
> SHA-256 of `pipeline.joblib` against `metadata.json` before calling `joblib.load`. `tests/test_artifact.py` shows how.

To build a backend request row, call `rideros_ml.features.inference.make_feature_row(poi_id, da_id, local_time)`.
Pass `local_time` as a naive local datetime. Take `da_id` from `restaurant_reference.csv` (`reference_da_id`).
Tests check that this function produces the same features as `build.py` for the same instant.

## Tests

```powershell
python -m uv run pytest                 # everything (artifact/data tests skip if files are absent)
python -m uv run pytest -m "not slow"   # skip the ~1-2 min end-to-end reproducibility run
```

| File | Covers |
|---|---|
| `test_license_and_download.py` | missing or reworded clause fails; null/absent/mismatched pin fails closed before extraction; only the named zip member is extracted |
| `test_validate.py` | schema, NaN, keys, dt range, rejected-waybill consistency, one pickup per order, chronology, ambiguous orders, timezone offset |
| `test_build.py` | target, benchmark, prebook/rejected/ambiguous exclusion, first-dispatch `da_id`, causal window and open-order counts (no future rows), target rule, temporal split |
| `test_features.py` | forbidden-column guard, type coercion, invalid input, cross-fitted target encoding, `make_feature_row`, train/serve parity |
| `test_conformal.py` · `test_metrics.py` | coverage on exchangeable data, asymmetry, floor; metric formulas, segments, baselines |
| `test_reproducibility.py` | same seed gives identical models and tuning; `slow` + `data`: rerunning `train --quick` matches the stored smoke run (abs tol 1e-6) |
| `test_artifact.py` (`artifact`) | hashes match metadata; load + predict; unseen restaurant; invalid input errors; reloaded model reproduces the test metrics in `metrics.json` |

Markers: `data` needs `data/raw` + `data/processed`; `artifact` needs `artifacts/pickup_o2p/<version>/`;
`slow` takes more than ~30 s.

## Limitations

- The data covers 8 days in one Chinese city (October 2022). It is not representative of Thai restaurants, and the
  app must say so.
- The target mixes restaurant preparation with rider arrival, and this dataset cannot separate them.
  The Personal Pickup Log (Phase 2+) is the planned source of real waiting-time data.
- Restaurants with few training orders get weaker predictions that lean on the prior (see the segment metrics).
- License is CC BY-NC 4.0 with no redistribution. Data and artifacts stay local.
