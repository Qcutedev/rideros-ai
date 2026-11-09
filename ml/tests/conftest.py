"""Shared fixtures.

Most tests run on small synthetic waybill tables built here, so the suite works without the dataset.
Tests that need the downloaded data or a trained artifact carry the `data` / `artifact` markers and are
skipped automatically when those files are absent.
"""

from __future__ import annotations

import itertools
from dataclasses import replace

import numpy as np
import pandas as pd
import pytest

from rideros_ml.config import load_config
from rideros_ml.data import schema
from rideros_ml.paths import ARTIFACTS_DIR, PROCESSED_DIR, raw_dataset_dir

# 2022-10-18 03:00 UTC = 11:00 China Standard Time (Tuesday)
BASE_T0 = int(pd.Timestamp("2022-10-18 03:00:00").timestamp())
LOCAL_OFFSET_S = 8 * 3600


@pytest.fixture(scope="session")
def cfg():
    return load_config()


@pytest.fixture
def cfg_with():
    """cfg_with(cfg, dataset={...}, target={...}) -> copy of cfg with nested fields replaced."""

    def _replace(base, **sections):
        updates = {name: replace(getattr(base, name), **fields) for name, fields in sections.items()}
        return replace(base, **updates)

    return _replace


@pytest.fixture
def waybill():
    """Factory for one raw waybill row with every schema column and internally consistent times."""
    ids = itertools.count(1)

    def _make(order_id: int, t0: int = BASE_T0, **overrides) -> dict:
        local = pd.Timestamp(t0 + LOCAL_OFFSET_S, unit="s")
        row = {
            schema.INDEX_COLUMN: 0,
            "order_id": order_id,
            "waybill_id": next(ids),
            "courier_id": 1,
            "poi_id": 10,
            "da_id": 1,
            "platform_order_time": t0,
            "order_push_time": t0 + 5,
            "estimate_meal_prepare_time": t0 + 600,
            "estimate_arrived_time": t0 + 1800,
            "dispatch_time": t0 + 13,
            "grab_time": t0 + 60,
            "fetch_time": t0 + 900,
            "arrive_time": t0 + 1500,
            "sender_lat": 45_000_000,
            "sender_lng": 126_000_000,
            "recipient_lat": 45_010_000,
            "recipient_lng": 126_010_000,
            "grab_lat": 45_000_000,
            "grab_lng": 126_000_000,
            "is_courier_grabbed": 1,
            "is_prebook": 0,
            "is_weekend": int(local.weekday() >= 5),
            "dt": int(local.strftime("%Y%m%d")),
        }
        row.update(overrides)
        return row

    return _make


@pytest.fixture
def rejected():
    """Overrides that turn a waybill into a rejected one (Supplementary 2.4: rejected -> times are 0)."""
    return {"is_courier_grabbed": 0, "grab_time": 0, "fetch_time": 0, "arrive_time": 0}


def to_frame(rows: list[dict]) -> pd.DataFrame:
    df = pd.DataFrame(rows)
    df[schema.INDEX_COLUMN] = np.arange(len(df))
    return df


@pytest.fixture
def frame():
    return to_frame


@pytest.fixture
def synthetic_orders():
    """Order-level table shaped like orders.parquet (after build), with a learnable signal.

    Train covers 2022-10-16..22, validation 10-23, test 10-24 (the configured split dates).
    """

    def _make(n_per_day: int = 300, seed: int = 0) -> pd.DataFrame:
        rng = np.random.default_rng(seed)
        days = pd.date_range("2022-10-16", "2022-10-24", freq="D")
        frames = []
        for day in days:
            minutes = np.sort(rng.integers(0, 1440, n_per_day))
            poi = rng.integers(0, 25, n_per_day)
            local = day + pd.to_timedelta(minutes, unit="m")
            angle = 2 * np.pi * minutes / 1440.0
            y = 8 + 0.4 * poi + 3 * np.sin(angle) + rng.normal(0, 2, n_per_day)
            frames.append(
                pd.DataFrame(
                    {
                        "order_id": np.arange(n_per_day) + len(frames) * n_per_day,
                        "poi_id": poi.astype(str),
                        "da_id": (poi % 4).astype(str),
                        "platform_order_time": (local - pd.Timedelta(hours=8)).astype("int64") // 10**9,
                        "local_date": local.strftime("%Y-%m-%d"),
                        "hour": local.hour.astype("int16"),
                        "minute_of_day": minutes.astype("int16"),
                        "minute_sin": np.sin(angle),
                        "minute_cos": np.cos(angle),
                        "is_weekend": (local.day_of_week >= 5).astype(int),
                        "poi_orders_last_30m": rng.integers(0, 5, n_per_day),
                        "da_orders_last_30m": rng.integers(0, 20, n_per_day),
                        "poi_open_orders": rng.integers(0, 4, n_per_day),
                        "distance_km": rng.uniform(0.5, 5, n_per_day),
                        "meituan_est_ready_min": y + rng.normal(0, 3, n_per_day),
                        "order_to_pickup_min": np.clip(y, 1, 120),
                    }
                )
            )
        df = pd.concat(frames, ignore_index=True)
        df["fetch_time"] = df["platform_order_time"] + (df["order_to_pickup_min"] * 60).astype("int64")
        return df

    return _make


def pytest_collection_modifyitems(config, items):
    cfg = load_config()
    has_raw = (raw_dataset_dir(cfg.dataset.name) / cfg.dataset.license_file).exists()
    has_processed = (PROCESSED_DIR / "orders.parquet").exists()
    has_artifact = (ARTIFACTS_DIR / cfg.model_name / cfg.model_version / "metadata.json").exists()
    skip_data = pytest.mark.skip(
        reason="dataset not downloaded/built (run rideros-ml download/validate/build)"
    )
    skip_artifact = pytest.mark.skip(
        reason=f"no trained artifact {cfg.model_name}/{cfg.model_version} (run rideros-ml train)"
    )
    for item in items:
        if "data" in item.keywords and not (has_raw and has_processed):
            item.add_marker(skip_data)
        if "artifact" in item.keywords and not has_artifact:
            item.add_marker(skip_artifact)
