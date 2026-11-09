"""Exploratory Data Analysis on the TRAIN period only (val/test are never inspected here).

Writes ml/reports/eda/EDA_REPORT.md and figures. Plain script output (not a notebook) so it is
reproducible and diff-able in git.
"""

from __future__ import annotations

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from rideros_ml.config import Config
from rideros_ml.data.build import BENCHMARK, TARGET, temporal_split
from rideros_ml.paths import PROCESSED_DIR, REPORTS_DIR


def _save(fig, path):
    fig.tight_layout()
    fig.savefig(path, dpi=120)
    plt.close(fig)


def _eta_squared(y: pd.Series, groups: pd.Series) -> float:
    """Share of target variance explained by group means (between-group variance / total variance)."""
    means = y.groupby(groups).transform("mean")
    return float(((means - y.mean()) ** 2).sum() / ((y - y.mean()) ** 2).sum())


def run_eda(cfg: Config) -> str:
    df = pd.read_parquet(PROCESSED_DIR / "orders.parquet")
    train = temporal_split(df, cfg)["train"]
    y = train[TARGET]
    out = REPORTS_DIR / "eda"
    out.mkdir(parents=True, exist_ok=True)
    md: list[str] = [
        "# EDA - Order-to-Pickup Time (train period only)",
        "",
        f"Rows: {len(train):,} orders · local dates {train['local_date'].min()} .. {train['local_date'].max()} · "
        f"POIs: {train['poi_id'].nunique():,} · areas (da_id): {train['da_id'].nunique()}",
        "",
        "Target = minutes from order creation to rider pickup. It is NOT food preparation time and NOT rider waiting time.",
        "",
        "## 1. Target distribution",
        "",
        "```",
        y.describe(percentiles=[0.05, 0.25, 0.5, 0.75, 0.95, 0.99]).round(2).to_string(),
        "```",
        f"Skewness: {y.skew():.2f}",
        "",
        "![target](target_hist.png)",
    ]
    fig, ax = plt.subplots(figsize=(7, 3.5))
    ax.hist(y.clip(upper=60), bins=120, color="#4C72B0")
    ax.set(xlabel="order-to-pickup minutes (clipped at 60)", ylabel="orders", title="Target distribution (train)")
    _save(fig, out / "target_hist.png")

    # 2. Time of day
    by_hour = train.groupby("hour")[TARGET].agg(["count", "median", lambda s: s.quantile(0.25), lambda s: s.quantile(0.75)])
    by_hour.columns = ["orders", "median", "p25", "p75"]
    fig, ax1 = plt.subplots(figsize=(8, 3.5))
    ax1.bar(by_hour.index, by_hour["orders"], color="#DDDDDD", label="orders")
    ax1.set(xlabel="local hour of order", ylabel="orders")
    ax2 = ax1.twinx()
    ax2.plot(by_hour.index, by_hour["median"], color="#C44E52", marker="o", label="median minutes")
    ax2.fill_between(by_hour.index, by_hour["p25"], by_hour["p75"], color="#C44E52", alpha=0.15)
    ax2.set_ylabel("minutes (median, IQR)")
    ax1.set_title("Order volume and order-to-pickup by hour (train)")
    _save(fig, out / "by_hour.png")
    md += [
        "",
        "## 2. Time of day",
        "",
        "```",
        by_hour.round(2).to_string(),
        "```",
        "",
        f"Variance explained by hour (eta²): {_eta_squared(y, train['hour']):.4f}",
        "",
        "![by hour](by_hour.png)",
    ]

    # 3. Weekend
    wk = train.groupby("is_weekend")[TARGET].agg(["count", "mean", "median"]).round(2)
    md += ["", "## 3. Weekend vs weekday", "", "```", wk.to_string(), "```",
           "Train covers Mon 17 - Sat 22 Oct (plus a few late-night orders created Sun 16 Oct local time), so every "
           "weekday appears at most once and Sunday (the validation day) is barely present. Weekday-level effects "
           "cannot be estimated reliably -> the model uses `is_weekend`, not day-of-week."]

    # 4. Restaurants (POI)
    poi_n = train.groupby("poi_id").size()
    eta_poi = _eta_squared(y, train["poi_id"])
    fig, ax = plt.subplots(figsize=(7, 3.5))
    ax.hist(np.log10(poi_n), bins=60, color="#55A868")
    ax.set(xlabel="log10(orders per POI in train)", ylabel="POIs", title="Orders per restaurant (train)")
    _save(fig, out / "poi_volume.png")
    md += [
        "",
        "## 4. Restaurants (poi_id)",
        "",
        f"- POIs in train: {poi_n.size:,}; median orders/POI: {int(poi_n.median())}; POIs with >= 30 orders: {int((poi_n >= 30).sum()):,}",
        f"- Variance explained by POI means (eta², in-sample, optimistic for small POIs): {eta_poi:.4f}",
        f"- Variance explained by area da_id (eta²): {_eta_squared(y, train['da_id']):.4f}",
        "",
        "![poi volume](poi_volume.png)",
    ]

    # 5. Platform estimate (benchmark)
    b = train[BENCHMARK]
    avail = b.notna()
    mae_b = float((train.loc[avail, TARGET] - b[avail]).abs().mean())
    fig, ax = plt.subplots(figsize=(5, 5))
    sub = train[avail].sample(min(60000, int(avail.sum())), random_state=cfg.training["seed"])
    ax.hexbin(sub[BENCHMARK].clip(0, 60), sub[TARGET].clip(0, 60), gridsize=60, bins="log", cmap="viridis")
    ax.plot([0, 60], [0, 60], color="white", lw=1)
    ax.set(xlabel="Meituan estimated meal-ready (min after order)", ylabel="actual order-to-pickup (min)",
           title="Platform estimate vs actual (train)")
    _save(fig, out / "benchmark_vs_actual.png")
    md += [
        "",
        "## 5. Meituan platform estimate (benchmark, NOT a feature)",
        "",
        f"- Available for {avail.mean():.2%} of train orders",
        f"- MAE of the estimate vs actual order-to-pickup on train: {mae_b:.3f} min",
        f"- corr(estimate, actual): {train.loc[avail, [BENCHMARK, TARGET]].corr().iloc[0, 1]:.3f}",
        "",
        "![benchmark](benchmark_vs_actual.png)",
    ]

    # 6. Ablation-only signals
    load = train.groupby(train["poi_open_orders"].clip(upper=10))[TARGET].agg(["count", "median"]).round(2)
    md += [
        "",
        "## 6. Platform-side real-time signals (ablation only - RiderOS cannot observe these at inference)",
        "",
        "Median target by number of open (not yet picked-up) orders at the same POI at t0:",
        "",
        "```",
        load.to_string(),
        "```",
        f"- corr(target, poi_open_orders): {train[[TARGET, 'poi_open_orders']].corr().iloc[0, 1]:.3f}",
        f"- corr(target, poi_orders_last_30m): {train[[TARGET, 'poi_orders_last_30m']].corr().iloc[0, 1]:.3f}",
        f"- corr(target, distance_km): {train[[TARGET, 'distance_km']].corr().iloc[0, 1]:.3f}",
    ]

    (out / "EDA_REPORT.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    return f"EDA written to {out / 'EDA_REPORT.md'}"
