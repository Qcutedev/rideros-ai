"""Regression metrics and segment breakdowns."""

from __future__ import annotations

import numpy as np
import pandas as pd


def regression_metrics(y_true, y_pred) -> dict[str, float]:
    y_true, y_pred = np.asarray(y_true, float), np.asarray(y_pred, float)
    err = y_pred - y_true
    ss_res = float((err**2).sum())
    ss_tot = float(((y_true - y_true.mean()) ** 2).sum())
    return {
        "n": int(len(y_true)),
        "mae": float(np.abs(err).mean()),
        "rmse": float(np.sqrt((err**2).mean())),
        "r2": float(1 - ss_res / ss_tot) if ss_tot > 0 else float("nan"),
        "median_ae": float(np.median(np.abs(err))),
        "bias": float(err.mean()),
    }


HOUR_BANDS = [(0, 5, "00-05"), (6, 10, "06-10"), (11, 13, "11-13 lunch"), (14, 16, "14-16"), (17, 20, "17-20 dinner"), (21, 23, "21-23")]
POI_BUCKETS = [(-1, 0, "unseen in train"), (1, 29, "1-29"), (30, 99, "30-99"), (100, 499, "100-499"), (500, 10**9, "500+")]


def hour_band(hour: pd.Series) -> pd.Series:
    out = pd.Series(index=hour.index, dtype=object)
    for lo, hi, name in HOUR_BANDS:
        out[(hour >= lo) & (hour <= hi)] = name
    return out


def poi_bucket(train_counts: pd.Series) -> pd.Series:
    out = pd.Series(index=train_counts.index, dtype=object)
    for lo, hi, name in POI_BUCKETS:
        out[(train_counts >= lo) & (train_counts <= hi)] = name
    return out


def segment_metrics(df: pd.DataFrame, y_col: str, pred_col: str, segment: pd.Series) -> dict[str, dict]:
    result = {}
    for name, idx in df.groupby(segment).groups.items():
        part = df.loc[idx]
        result[str(name)] = regression_metrics(part[y_col], part[pred_col])
    return result
