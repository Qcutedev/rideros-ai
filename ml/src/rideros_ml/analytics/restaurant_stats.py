"""Descriptive restaurant analytics for the app (feeds DATABASE_DESIGN `restaurants` + `restaurant_time_stats`).

Aggregates only - raw rows are never exported. Output is a derivative of CC BY-NC data: it stays in
ml/artifacts/ (gitignored) and must not be published (Decision D4).
"""

from __future__ import annotations

import json

import pandas as pd

from rideros_ml.config import Config
from rideros_ml.data.build import TARGET
from rideros_ml.paths import ARTIFACTS_DIR, PROCESSED_DIR


def _q(p: float):
    return lambda s: float(s.quantile(p))


def export_restaurant_stats(cfg: Config) -> str:
    df = pd.read_parquet(PROCESSED_DIR / "orders.parquet")
    data_meta = json.loads((PROCESSED_DIR / "orders.meta.json").read_text(encoding="utf-8"))
    df["day_type"] = df["is_weekend"].map({0: "weekday", 1: "weekend"})

    # Reference per POI: overall stats + the da_id the backend must send to the model.
    ref = df.groupby("poi_id").agg(
        n_orders=(TARGET, "size"),
        median_min=(TARGET, "median"),
        p25_min=(TARGET, _q(0.25)),
        p75_min=(TARGET, _q(0.75)),
        p90_min=(TARGET, _q(0.90)),
        reference_da_id=("da_id", lambda s: s.value_counts().index[0]),
    )
    hourly_n = df.groupby(["poi_id", "hour"]).size()
    ref["peak_hour"] = hourly_n.groupby(level=0).idxmax().map(lambda t: t[1])
    ref["data_availability"] = pd.cut(
        ref["n_orders"], [0, 4, cfg.min_orders_for_stats - 1, float("inf")], labels=["insufficient", "limited", "sufficient"]
    ).astype(str)

    time_stats = df.groupby(["poi_id", "day_type", "hour"]).agg(
        n_orders=(TARGET, "size"),
        median_min=(TARGET, "median"),
        p25_min=(TARGET, _q(0.25)),
        p75_min=(TARGET, _q(0.75)),
        p90_min=(TARGET, _q(0.90)),
    )

    out = ARTIFACTS_DIR / "restaurant_stats" / cfg.model_version
    out.mkdir(parents=True, exist_ok=True)
    ref.round(3).to_csv(out / "restaurant_reference.csv")
    time_stats.round(3).to_csv(out / "restaurant_time_stats.csv")
    summary = {
        "source_orders_parquet_sha256": data_meta["orders_parquet_sha256"],
        "n_restaurants": int(len(ref)),
        "availability": ref["data_availability"].value_counts().to_dict(),
        "n_time_cells": int(len(time_stats)),
        "min_orders_for_stats": cfg.min_orders_for_stats,
        "note": "Aggregates over all 8 days (descriptive analytics, not model evaluation).",
    }
    (out / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return json.dumps(summary, indent=2)
