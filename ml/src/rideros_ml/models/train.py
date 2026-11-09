"""End-to-end training: baselines -> candidates -> tuning (val) -> selection (val) -> ONE test evaluation -> export.

Stage order is enforced in code: test predictions are computed only in `final_test_evaluation`, after the
selected model and the conformal calibration have been fixed from validation data.
"""

from __future__ import annotations

import json
import subprocess
import time
from datetime import UTC, datetime

import pandas as pd

from rideros_ml.config import Config
from rideros_ml.data.build import BENCHMARK, TARGET, temporal_split
from rideros_ml.evaluation import plots
from rideros_ml.export.artifact import feature_schema, write_artifact
from rideros_ml.intervals.conformal import calibrate, coverage
from rideros_ml.models import candidates as C
from rideros_ml.models.metrics import hour_band, poi_bucket, regression_metrics, segment_metrics
from rideros_ml.models.tuning import tune
from rideros_ml.paths import ARTIFACTS_DIR, PROCESSED_DIR, REPORTS_DIR

LEAKAGE_REVIEW = [
    # feature, source, known at t0, available to RiderOS at inference, used in deployable model
    ("poi_id", "order", "yes", "yes (dataset restaurant)", "yes"),
    (
        "da_id",
        "first dispatched waybill (~13 s after t0)",
        "yes (pushed with order)",
        "yes (POI reference)",
        "yes",
    ),
    ("hour / minute_sin / minute_cos", "platform_order_time", "yes", "yes (request time)", "yes"),
    ("is_weekend", "order date", "yes", "yes", "yes"),
    (
        "poi_orders_last_30m",
        "orders at POI in [t0-30m, t0)",
        "yes",
        "no (no live platform data)",
        "ablation only",
    ),
    ("da_orders_last_30m", "orders in area in [t0-30m, t0)", "yes", "no", "ablation only"),
    (
        "poi_open_orders",
        "orders at POI created < t0 and fetched > t0",
        "yes (state at t0)",
        "no",
        "ablation only",
    ),
    (
        "distance_km",
        "sender/recipient coords",
        "yes",
        "no (rider rarely knows before accepting)",
        "ablation only",
    ),
    ("estimate_meal_prepare_time", "Meituan model output", "yes", "no", "benchmark only"),
    ("estimate_arrived_time", "Meituan promise", "yes", "no", "excluded"),
    (
        "dispatch/grab/fetch/arrive times, courier_id, grab_lat/lng",
        "post-assignment events",
        "NO",
        "no",
        "excluded (leakage)",
    ),
]


def _git_sha() -> str:
    try:
        return subprocess.run(
            ["git", "rev-parse", "HEAD"], capture_output=True, text=True, check=True
        ).stdout.strip()
    except subprocess.CalledProcessError, FileNotFoundError:
        return "no-commit"


def _subsample(parts: dict[str, pd.DataFrame], seed: int) -> dict[str, pd.DataFrame]:
    sizes = {"train": 40000, "val": 10000, "test": 10000}
    return {
        k: v.sample(min(sizes[k], len(v)), random_state=seed)
        .sort_values("platform_order_time")
        .reset_index(drop=True)
        for k, v in parts.items()
    }


def run_training(cfg: Config, quick: bool = False) -> str:
    seed = int(cfg.training["seed"])
    orders = pd.read_parquet(PROCESSED_DIR / "orders.parquet")
    data_meta = json.loads((PROCESSED_DIR / "orders.meta.json").read_text(encoding="utf-8"))
    parts = temporal_split(orders, cfg)
    if quick:
        parts = _subsample(parts, seed)
    train, val, test = parts["train"], parts["val"], parts["test"]
    y_tr, y_va = train[TARGET].to_numpy(), val[TARGET].to_numpy()
    deploy = cfg.features.deployable
    ablation = deploy + cfg.features.ablation_extra
    version = "quick-smoke" if quick else cfg.model_version
    n_xgb = 2 if quick else int(cfg.training["xgboost_trials"])
    n_cat = 2 if quick else int(cfg.training["catboost_trials"])
    timeout = 120 if quick else None
    log: list[str] = []
    t_start = time.time()

    def note(msg: str):
        stamp = f"[{time.time() - t_start:7.1f}s] {msg}"
        log.append(stamp)
        print(stamp, flush=True)

    note(f"split sizes train={len(train):,} val={len(val):,} test={len(test):,} quick={quick}")
    if not (
        train["platform_order_time"].max()
        < val["platform_order_time"].min()
        <= val["platform_order_time"].max()
        < test["platform_order_time"].min()
    ):
        raise AssertionError("temporal split is not strictly ordered")

    # ---------------- Stage 1: fit on train, score on validation ----------------
    models: dict[str, dict] = {}

    def register(name: str, pipe, features: list[str], deployable: bool, extra: dict | None = None):
        models[name] = {
            "pipe": pipe,
            "features": features,
            "deployable": deployable,
            "val": regression_metrics(y_va, pipe.predict(val)),
            **(extra or {}),
        }
        note(f"{name}: val MAE={models[name]['val']['mae']:.4f}")

    register("baseline_global_median", C.fit_global_median(train, y_tr), ["-"], True)
    register("baseline_poi_median", C.fit_poi_median(train, y_tr), ["poi_id"], True)
    register("linear_regression", C.fit_linear(train, y_tr, deploy, seed), deploy, True)
    rf_params = dict(cfg.training["random_forest"])
    if quick:
        rf_params["n_estimators"] = 20
    register(
        "random_forest",
        C.fit_random_forest(train, y_tr, deploy, seed, rf_params),
        deploy,
        True,
        {"params": rf_params},
    )

    xgb_tuning = tune("xgboost", train, y_tr, val, y_va, deploy, seed, n_xgb, timeout)
    note(
        f"xgboost tuning: {xgb_tuning['n_trials_completed']} trials, best val MAE={xgb_tuning['best_val_mae']:.4f}"
    )
    register(
        "xgboost",
        C.fit_xgboost(train, y_tr, val, y_va, deploy, seed, xgb_tuning["best_params"]),
        deploy,
        True,
        {"params": xgb_tuning["best_params"]},
    )

    cat_tuning = tune("catboost", train, y_tr, val, y_va, deploy, seed, n_cat, timeout)
    note(
        f"catboost tuning: {cat_tuning['n_trials_completed']} trials, best val MAE={cat_tuning['best_val_mae']:.4f}"
    )
    register(
        "catboost",
        C.fit_catboost(train, y_tr, val, y_va, deploy, seed, cat_tuning["best_params"]),
        deploy,
        True,
        {"params": cat_tuning["best_params"]},
    )

    register(
        "catboost_ablation_realtime",
        C.fit_catboost(train, y_tr, val, y_va, ablation, seed, cat_tuning["best_params"]),
        ablation,
        False,
        {"params": cat_tuning["best_params"]},
    )

    # Meituan platform estimate (benchmark, not ours)
    def benchmark_metrics(df: pd.DataFrame) -> dict:
        avail = df[BENCHMARK].notna()
        return {
            "available_share": float(avail.mean()),
            **regression_metrics(df.loc[avail, TARGET], df.loc[avail, BENCHMARK]),
        }

    bench_val = benchmark_metrics(val)
    note(
        f"meituan platform estimate (benchmark): val MAE={bench_val['mae']:.4f} on {bench_val['available_share']:.2%} rows"
    )

    # ---------------- Stage 2: selection + calibration (validation only) ----------------
    deployable = {k: v for k, v in models.items() if v["deployable"]}
    selected = min(deployable, key=lambda k: deployable[k]["val"]["mae"])
    sel_pipe = models[selected]["pipe"]
    conformal = calibrate(y_va, sel_pipe.predict(val), cfg.conformal_alpha)
    selection_time = datetime.now(UTC).isoformat(timespec="seconds")
    note(
        f"SELECTED (by val MAE): {selected}; conformal q_low={conformal.q_low:.3f} q_high={conformal.q_high:.3f}"
    )

    # ---------------- Stage 3: single test evaluation ----------------
    test_time = datetime.now(UTC).isoformat(timespec="seconds")
    test_scored = test.copy()
    test_metrics = {}
    for name, m in models.items():
        test_scored[f"pred_{name}"] = m["pipe"].predict(test)
        test_metrics[name] = regression_metrics(test_scored[TARGET], test_scored[f"pred_{name}"])
    bench_test = benchmark_metrics(test)
    low, high = conformal.interval(test_scored[f"pred_{selected}"])
    cov_test = coverage(test_scored[TARGET], low, high)
    train_counts = test_scored["poi_id"].map(train["poi_id"].value_counts()).fillna(0)
    pred_col = f"pred_{selected}"
    segments = {
        "hour_band": segment_metrics(test_scored, TARGET, pred_col, hour_band(test_scored["hour"])),
        "poi_train_orders": segment_metrics(test_scored, TARGET, pred_col, poi_bucket(train_counts)),
    }
    inside = (test_scored[TARGET] >= low) & (test_scored[TARGET] <= high)
    cov_by_bucket = inside.groupby(poi_bucket(train_counts)).mean().to_dict()
    note(
        f"TEST {selected}: MAE={test_metrics[selected]['mae']:.4f} R2={test_metrics[selected]['r2']:.4f} interval coverage={cov_test['coverage']:.3f}"
    )

    # ---------------- Reports + artifact ----------------
    rep_dir = REPORTS_DIR / cfg.model_name / version
    rep_dir.mkdir(parents=True, exist_ok=True)
    comparison = [
        {
            "model": n,
            "features": "deployable" if m["deployable"] else "ablation (not deployable)",
            "val_mae": m["val"]["mae"],
            "val_rmse": m["val"]["rmse"],
            "val_r2": m["val"]["r2"],
            "test_mae": test_metrics[n]["mae"],
            "test_rmse": test_metrics[n]["rmse"],
            "test_r2": test_metrics[n]["r2"],
        }
        for n, m in models.items()
    ]
    plots.model_comparison(
        [r for r in comparison if r["features"] == "deployable"], rep_dir / "model_comparison.png"
    )
    y_t, p_t = test_scored[TARGET].to_numpy(), test_scored[pred_col].to_numpy()
    plots.actual_vs_predicted(y_t, p_t, rep_dir / "actual_vs_predicted.png", f"{selected} - test")
    plots.residuals_vs_predicted(y_t, p_t, rep_dir / "residuals.png", f"{selected} - residuals (test)")
    plots.error_distribution(
        y_t, p_t, rep_dir / "error_distribution.png", f"{selected} - error distribution (test)"
    )
    plots.mae_by_hour(
        test_scored,
        TARGET,
        {selected: pred_col, "baseline_poi_median": "pred_baseline_poi_median"},
        rep_dir / "mae_by_hour.png",
        "Test MAE by hour",
    )

    metrics = {
        "model": cfg.model_name,
        "version": version,
        "quick_smoke_test": quick,
        "selected_model": selected,
        "selection_rule": "lowest validation MAE among deployable models (baselines included)",
        "selection_decided_at": selection_time,
        "test_evaluated_at": test_time,
        "split_sizes": {k: len(v) for k, v in parts.items()},
        "validation": {n: m["val"] for n, m in models.items()},
        "test": test_metrics,
        "benchmark_meituan_estimate": {"validation": bench_val, "test": bench_test},
        "conformal_test": cov_test,
        "conformal_test_by_poi_bucket": {str(k): float(v) for k, v in cov_by_bucket.items()},
        "segments_test_selected": segments,
        "tuning": {"xgboost": xgb_tuning, "catboost": cat_tuning},
        "random_forest_params": rf_params,
        "log": log,
    }
    (rep_dir / "metrics.json").write_text(json.dumps(metrics, indent=2, default=str), encoding="utf-8")
    (rep_dir / "RESULTS.md").write_text(_results_markdown(metrics, comparison, cfg), encoding="utf-8")

    meta = {
        "model": cfg.model_name,
        "version": version,
        "selected_model": selected,
        "features": models[selected]["features"],
        "seed": seed,
        "git_commit": _git_sha(),
        "data": {"commit": cfg.dataset.commit, **data_meta},
        "split": cfg.split.__dict__,
        "conformal": conformal.to_dict(),
        "config_file": cfg.source_path.name,
        "params": models[selected].get("params"),
    }
    schema = feature_schema(cfg.model_name, version, deploy, cfg.conformal_alpha)
    write_artifact(
        ARTIFACTS_DIR / cfg.model_name / version, sel_pipe, meta, metrics, schema, conformal.to_dict()
    )
    note(f"artifact written to {ARTIFACTS_DIR / cfg.model_name / version}")
    return f"done: selected={selected} report={rep_dir / 'RESULTS.md'}"


def _fmt(x: float) -> str:
    return f"{x:.3f}"


def _results_markdown(m: dict, comparison: list[dict], cfg: Config) -> str:
    sel = m["selected_model"]
    bv, bt = m["benchmark_meituan_estimate"]["validation"], m["benchmark_meituan_estimate"]["test"]
    lines = [
        f"# Results - {m['model']} {m['version']}",
        "",
        "> All numbers below were produced by `rideros-ml train` on the Meituan INFORMS TSL data in this run.",
        "> Target: **order-to-pickup minutes** (not food preparation time, not rider waiting time).",
        "",
    ]
    if m["quick_smoke_test"]:
        lines += ["> **QUICK SMOKE TEST on subsamples - NOT valid for reporting.**", ""]
    lines += [
        f"Split: train {m['split_sizes']['train']:,} · validation {m['split_sizes']['val']:,} ({cfg.split.val_date}) · test {m['split_sizes']['test']:,} ({cfg.split.test_date})",
        "",
        f"Selected model: **{sel}** ({m['selection_rule']}). Selection fixed at {m['selection_decided_at']}, test evaluated at {m['test_evaluated_at']}.",
        "",
        "## Model comparison",
        "",
        "| Model | Features | Val MAE | Val RMSE | Val R² | Test MAE | Test RMSE | Test R² |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for r in comparison:
        name = f"**{r['model']}**" if r["model"] == sel else r["model"]
        lines.append(
            f"| {name} | {r['features']} | {_fmt(r['val_mae'])} | {_fmt(r['val_rmse'])} | {_fmt(r['val_r2'])} | {_fmt(r['test_mae'])} | {_fmt(r['test_rmse'])} | {_fmt(r['test_r2'])} |"
        )
    lines.append(
        f"| Meituan platform estimate (benchmark, not ours) | platform model | {_fmt(bv['mae'])} | {_fmt(bv['rmse'])} | {_fmt(bv['r2'])} | {_fmt(bt['mae'])} | {_fmt(bt['rmse'])} | {_fmt(bt['r2'])} |"
    )
    lines += [
        "",
        f"Benchmark rows: estimate available for {bv['available_share']:.2%} (val) / {bt['available_share']:.2%} (test) of orders; metrics on that subset. "
        "The estimate predicts meal-ready time, a different quantity than order-to-pickup, so this comparison shows how "
        "well the platform's own number tracks pickup time - not a like-for-like model contest.",
        "",
        "![comparison](model_comparison.png)",
        "",
        "## Prediction interval (split conformal, calibrated on validation)",
        "",
        f"- Nominal coverage {1 - cfg.conformal_alpha:.0%} · **empirical test coverage {m['conformal_test']['coverage']:.1%}** · mean width {m['conformal_test']['mean_width']:.2f} min",
        "- Coverage by restaurant training volume: "
        + ", ".join(f"{k}: {v:.1%}" for k, v in m["conformal_test_by_poi_bucket"].items()),
        "",
        "## Test error by segment (selected model)",
        "",
        "| Segment | Group | n | MAE | RMSE | Bias |",
        "|---|---|---|---|---|---|",
    ]
    for seg, groups in m["segments_test_selected"].items():
        for g, s in groups.items():
            lines.append(
                f"| {seg} | {g} | {s['n']:,} | {_fmt(s['mae'])} | {_fmt(s['rmse'])} | {_fmt(s['bias'])} |"
            )
    lines += [
        "",
        "## Figures (test day, selected model)",
        "",
        "![actual vs predicted](actual_vs_predicted.png)",
        "![residuals](residuals.png)",
        "![error distribution](error_distribution.png)",
        "![mae by hour](mae_by_hour.png)",
        "",
        "## Tuning",
        "",
        f"- XGBoost: {m['tuning']['xgboost']['n_trials_completed']} Optuna trials, best val MAE {_fmt(m['tuning']['xgboost']['best_val_mae'])}, params `{json.dumps(m['tuning']['xgboost']['best_params'])}`",
        f"- CatBoost: {m['tuning']['catboost']['n_trials_completed']} Optuna trials, best val MAE {_fmt(m['tuning']['catboost']['best_val_mae'])}, params `{json.dumps(m['tuning']['catboost']['best_params'])}`",
        f"- Random forest (fixed, not tuned): `{json.dumps(m['random_forest_params'])}`",
        "- Early stopping and tuning both use the validation day; the conformal calibration reuses it, so test coverage is the honest check.",
        "",
        "## Leakage review",
        "",
        "| Feature | Source | Known at t0 | Available to RiderOS at inference | Used |",
        "|---|---|---|---|---|",
        *[f"| {a} | {b} | {c} | {d} | {e} |" for a, b, c, d, e in LEAKAGE_REVIEW],
        "",
        "## Run log",
        "",
        "```",
        *m["log"],
        "```",
    ]
    return "\n".join(lines) + "\n"
