"""Build the order-level modelling table from raw waybills.

One row per non-prebook order that was picked up. t0 = platform_order_time (order creation).
Target = (fetch_time - t0) / 60  -> "order-to-pickup minutes" (NOT prep time, NOT rider wait time).
"""

from __future__ import annotations

import numpy as np
import pandas as pd

from rideros_ml.config import Config
from rideros_ml.data import schema
from rideros_ml.data.validate import ambiguous_orders, grabbed_waybills, local_datetime

TARGET = "order_to_pickup_min"
BENCHMARK = "meituan_est_ready_min"


def load_raw(csv_path) -> pd.DataFrame:
    return pd.read_csv(csv_path)


def first_dispatch_da_id(raw: pd.DataFrame) -> pd.Series:
    """da_id of each order's first dispatched waybill. da_id can change on re-dispatch (Supplementary 2.6),
    so the picked-up waybill's da_id may encode post-t0 dispatch decisions; the first one is closest to t0."""
    w = raw[["order_id", "dispatch_time", "waybill_id", "da_id"]].copy()
    w["dispatch_sort"] = w["dispatch_time"].where(w["dispatch_time"] > 0, np.iinfo(np.int64).max)
    w = w.sort_values(["order_id", "dispatch_sort", "waybill_id"])
    return w.groupby("order_id")["da_id"].first()


def picked_up_orders(raw: pd.DataFrame) -> pd.DataFrame:
    """One picked-up waybill per order (validated upstream), prebook excluded, target attached."""
    raw = raw.drop(columns=[schema.INDEX_COLUMN], errors="ignore")
    g = grabbed_waybills(raw)
    if g["order_id"].duplicated().any():
        raise ValueError("more than one picked-up waybill per order - run validation first")
    orders = g[(g["is_prebook"] == 0) & ~g["order_id"].isin(ambiguous_orders(raw))].copy()
    orders["da_id"] = orders["order_id"].map(first_dispatch_da_id(raw))
    orders[TARGET] = (orders["fetch_time"] - orders["platform_order_time"]) / 60.0
    est = orders["estimate_meal_prepare_time"]
    orders[BENCHMARK] = np.where(est > 0, (est - orders["platform_order_time"]) / 60.0, np.nan)
    return orders.reset_index(drop=True)


def add_time_features(df: pd.DataFrame, utc_offset_hours: int) -> pd.DataFrame:
    local = local_datetime(df["platform_order_time"], utc_offset_hours)
    minute_of_day = local.dt.hour * 60 + local.dt.minute
    angle = 2 * np.pi * minute_of_day / 1440.0
    return df.assign(
        local_date=local.dt.strftime("%Y-%m-%d"),
        hour=local.dt.hour.astype("int16"),
        minute_of_day=minute_of_day.astype("int16"),
        minute_sin=np.sin(angle),
        minute_cos=np.cos(angle),
    )


def haversine_km(lat1, lng1, lat2, lng2) -> np.ndarray:
    lat1, lng1, lat2, lng2 = (
        np.radians(np.asarray(x, dtype=float) / schema.COORD_SCALE) for x in (lat1, lng1, lat2, lng2)
    )
    a = np.sin((lat2 - lat1) / 2) ** 2 + np.cos(lat1) * np.cos(lat2) * np.sin((lng2 - lng1) / 2) ** 2
    return 6371.0088 * 2 * np.arcsin(np.sqrt(a))


def _count_in_window(group_keys: np.ndarray, t0: np.ndarray, window_s: int) -> np.ndarray:
    """For each row: number of OTHER rows in the same group with t0' in [t0 - window, t0)."""
    out = np.zeros(len(t0), dtype=np.int32)
    order = np.lexsort((t0, group_keys))
    keys_sorted, t_sorted = group_keys[order], t0[order]
    boundaries = np.flatnonzero(np.diff(keys_sorted)) + 1
    for start, end in zip(np.r_[0, boundaries], np.r_[boundaries, len(t0)], strict=True):
        ts = t_sorted[start:end]
        out[order[start:end]] = np.searchsorted(ts, ts, "left") - np.searchsorted(ts, ts - window_s, "left")
    return out


def _open_orders(group_keys: np.ndarray, t0: np.ndarray, fetch: np.ndarray) -> np.ndarray:
    """Orders at the same group created before t0 and not yet picked up at t0 (fetch' > t0).

    Uses fetch' only as "has it happened before t0?", which the platform knows at t0 -> causal.
    """
    out = np.zeros(len(t0), dtype=np.int32)
    order = np.argsort(group_keys, kind="stable")
    keys_sorted = group_keys[order]
    boundaries = np.flatnonzero(np.diff(keys_sorted)) + 1
    for start, end in zip(np.r_[0, boundaries], np.r_[boundaries, len(t0)], strict=True):
        idx = order[start:end]
        t_s, f_s = np.sort(t0[idx]), np.sort(fetch[idx])
        created_before = np.searchsorted(t_s, t0[idx], "left")
        fetched_by = np.searchsorted(f_s, t0[idx], "right")
        out[idx] = created_before - fetched_by
    return out


def add_ablation_features(df: pd.DataFrame) -> pd.DataFrame:
    """Platform-side real-time features (NOT available to RiderOS at inference -> ablation only)."""
    t0 = df["platform_order_time"].to_numpy(np.int64)
    fetch = df["fetch_time"].to_numpy(np.int64)
    poi = df["poi_id"].to_numpy(np.int64)
    da = df["da_id"].to_numpy(np.int64)
    return df.assign(
        poi_orders_last_30m=_count_in_window(poi, t0, 1800),
        da_orders_last_30m=_count_in_window(da, t0, 1800),
        poi_open_orders=_open_orders(poi, t0, fetch),
        distance_km=haversine_km(
            df["sender_lat"], df["sender_lng"], df["recipient_lat"], df["recipient_lng"]
        ),
    )


def apply_target_rule(df: pd.DataFrame, cfg: Config) -> tuple[pd.DataFrame, dict]:
    t = cfg.target
    if t.min_minutes is None or t.max_minutes is None:
        raise ValueError("target.min_minutes / target.max_minutes must be decided and set in the config")
    keep = (df[TARGET] >= t.min_minutes) & (df[TARGET] <= t.max_minutes)
    info = {
        "rule": f"{t.min_minutes} <= {TARGET} <= {t.max_minutes}",
        "removed_below": int((df[TARGET] < t.min_minutes).sum()),
        "removed_above": int((df[TARGET] > t.max_minutes).sum()),
        "kept": int(keep.sum()),
    }
    return df[keep].reset_index(drop=True), info


def build_orders(raw: pd.DataFrame, cfg: Config) -> tuple[pd.DataFrame, dict]:
    orders = picked_up_orders(raw)
    orders = add_time_features(orders, cfg.dataset.local_utc_offset_hours)
    # Load features are computed on ALL picked-up non-prebook orders, before target filtering:
    # outlier orders still occupied the restaurant.
    orders = add_ablation_features(orders)
    orders, rule_info = apply_target_rule(orders, cfg)
    orders["poi_id"] = orders["poi_id"].astype(str)
    orders["da_id"] = orders["da_id"].astype(str)
    keep_cols = [
        "order_id",
        "poi_id",
        "da_id",
        "platform_order_time",
        "fetch_time",
        "local_date",
        "hour",
        "minute_of_day",
        "minute_sin",
        "minute_cos",
        "is_weekend",
        "poi_orders_last_30m",
        "da_orders_last_30m",
        "poi_open_orders",
        "distance_km",
        BENCHMARK,
        TARGET,
    ]
    return orders[keep_cols], rule_info


def temporal_split(df: pd.DataFrame, cfg: Config) -> dict[str, pd.DataFrame]:
    s = cfg.split
    parts = {
        "train": df[df["local_date"] <= s.train_last_date],
        "val": df[df["local_date"] == s.val_date],
        "test": df[df["local_date"] == s.test_date],
    }
    assigned = sum(len(p) for p in parts.values())
    if assigned != len(df):
        raise ValueError(f"{len(df) - assigned} rows fall outside the configured split dates")
    for name, part in parts.items():
        parts[name] = part.sort_values("platform_order_time").reset_index(drop=True)
    return parts
