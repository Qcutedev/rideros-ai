"""Order-level table: target, exclusions, da_id rule, causal load features, temporal split."""

from __future__ import annotations

import numpy as np
import pandas as pd
import pytest

from rideros_ml.data.build import (
    BENCHMARK,
    TARGET,
    _count_in_window,
    _open_orders,
    add_time_features,
    apply_target_rule,
    build_orders,
    first_dispatch_da_id,
    haversine_km,
    picked_up_orders,
    temporal_split,
)
from rideros_ml.features.pipelines import FORBIDDEN

from .conftest import BASE_T0

# ---------------- picked_up_orders ----------------


def test_target_is_order_to_pickup_minutes(waybill, frame):
    orders = picked_up_orders(frame([waybill(1, fetch_time=BASE_T0 + 750)]))
    assert orders.loc[0, TARGET] == pytest.approx(12.5)


def test_benchmark_from_platform_estimate_and_nan_when_zero(waybill, frame):
    raw = frame(
        [waybill(1, estimate_meal_prepare_time=BASE_T0 + 480), waybill(2, estimate_meal_prepare_time=0)]
    )
    orders = picked_up_orders(raw).set_index("order_id")
    assert orders.loc[1, BENCHMARK] == pytest.approx(8.0)
    assert np.isnan(orders.loc[2, BENCHMARK])


def test_prebook_orders_excluded(waybill, frame):
    orders = picked_up_orders(frame([waybill(1), waybill(2, is_prebook=1)]))
    assert orders["order_id"].tolist() == [1]


def test_rejected_waybills_and_unpicked_orders_excluded(waybill, frame, rejected):
    raw = frame([waybill(1, **rejected), waybill(1), waybill(2, **rejected)])
    orders = picked_up_orders(raw)
    assert orders["order_id"].tolist() == [1]


@pytest.mark.parametrize("col", ["platform_order_time", "recipient_lat", "recipient_lng"])
def test_ambiguous_orders_excluded(waybill, frame, rejected, col):
    first = waybill(1, **rejected)
    second = waybill(1)
    second[col] += 1
    orders = picked_up_orders(frame([first, second, waybill(2)]))
    assert orders["order_id"].tolist() == [2]


def test_more_than_one_pickup_raises(waybill, frame):
    with pytest.raises(ValueError, match="more than one picked-up waybill"):
        picked_up_orders(frame([waybill(1), waybill(1)]))


def test_da_id_comes_from_first_dispatched_waybill(waybill, frame, rejected):
    raw = frame(
        [
            waybill(
                1, da_id=7, dispatch_time=BASE_T0 + 300, grab_time=BASE_T0 + 320
            ),  # picked up, re-dispatched later
            waybill(1, da_id=5, dispatch_time=BASE_T0 + 13, **rejected),  # first dispatch, rejected
            waybill(1, da_id=9, dispatch_time=0, **rejected),  # never dispatched -> sorted last
        ]
    )
    assert first_dispatch_da_id(raw).loc[1] == 5
    assert picked_up_orders(raw).loc[0, "da_id"] == 5


def test_undispatched_waybill_only_used_when_nothing_dispatched(waybill, frame, rejected):
    raw = frame(
        [waybill(1, da_id=9, dispatch_time=0, **rejected), waybill(1, da_id=4, dispatch_time=BASE_T0 + 500)]
    )
    assert first_dispatch_da_id(raw).loc[1] == 4


# ---------------- time features ----------------


def test_time_features_use_local_offset():
    # 2022-10-21 18:30 UTC = 2022-10-22 02:30 local (Saturday)
    df = pd.DataFrame({"platform_order_time": [int(pd.Timestamp("2022-10-21 18:30:00").timestamp())]})
    out = add_time_features(df, 8).iloc[0]
    assert out["local_date"] == "2022-10-22"
    assert out["hour"] == 2
    assert out["minute_of_day"] == 150
    assert out["minute_sin"] == pytest.approx(np.sin(2 * np.pi * 150 / 1440))
    assert out["minute_cos"] == pytest.approx(np.cos(2 * np.pi * 150 / 1440))


def test_haversine_one_degree_latitude():
    assert haversine_km(45_000_000, 126_000_000, 46_000_000, 126_000_000) == pytest.approx(111.19, abs=0.05)
    assert haversine_km(45_000_000, 126_000_000, 45_000_000, 126_000_000) == pytest.approx(0.0)


# ---------------- causal load features ----------------


def test_count_in_window_is_strictly_past_and_excludes_self():
    keys = np.array([1, 1, 1, 1, 1, 2])
    t0 = np.array([0, 100, 1800, 1801, 5000, 100])
    # window [t0 - 1800, t0): 1800 sees 0 and 100; 1801 sees 100 and 1800 (0 is outside)
    assert _count_in_window(keys, t0, 1800).tolist() == [0, 1, 2, 2, 0, 0]


def test_count_in_window_ignores_simultaneous_orders():
    keys = np.array([1, 1, 1])
    t0 = np.array([50, 100, 100])
    assert _count_in_window(keys, t0, 1800).tolist() == [0, 1, 1]


def test_count_in_window_unaffected_by_future_orders():
    keys, t0 = np.array([1, 1, 1]), np.array([0, 300, 600])
    before = _count_in_window(keys, t0, 1800)
    after = _count_in_window(np.r_[keys, 1, 1], np.r_[t0, 700, 5000], 1800)
    assert after[:3].tolist() == before.tolist()


def test_count_in_window_order_independent():
    keys, t0 = np.array([2, 1, 1, 2, 1]), np.array([10, 900, 0, 20, 300])
    perm = np.array([4, 2, 0, 3, 1])
    assert (
        _count_in_window(keys[perm], t0[perm], 1800).tolist()
        == _count_in_window(keys, t0, 1800)[perm].tolist()
    )


def test_open_orders_counts_created_before_and_not_yet_fetched():
    keys = np.array([1, 1, 1, 2])
    t0 = np.array([0, 300, 500, 300])
    fetch = np.array([600, 400, 900, 350])
    # A(t0=0): none before. B(300): A open. C(500): A open, B fetched at 400.
    assert _open_orders(keys, t0, fetch).tolist() == [0, 1, 1, 0]


def test_open_orders_unaffected_by_future_orders():
    keys, t0, fetch = np.array([1, 1, 1]), np.array([0, 300, 500]), np.array([600, 400, 900])
    before = _open_orders(keys, t0, fetch)
    after = _open_orders(np.r_[keys, 1], np.r_[t0, 1000], np.r_[fetch, 1200])
    assert after[:3].tolist() == before.tolist()


# ---------------- target rule ----------------


def test_target_rule_is_inclusive_and_reports_counts(cfg):
    df = pd.DataFrame({TARGET: [0.5, 1.0, 30.0, 120.0, 121.0, 300.0]})
    kept, info = apply_target_rule(df, cfg)
    assert kept[TARGET].tolist() == [1.0, 30.0, 120.0]
    assert info == {"rule": f"1.0 <= {TARGET} <= 120.0", "removed_below": 1, "removed_above": 2, "kept": 3}


def test_target_rule_must_be_configured(cfg, cfg_with):
    with pytest.raises(ValueError, match="must be decided"):
        apply_target_rule(pd.DataFrame({TARGET: [5.0]}), cfg_with(cfg, target={"max_minutes": None}))


# ---------------- build_orders ----------------


def test_build_orders_end_to_end(waybill, frame, cfg):
    raw = frame(
        [
            waybill(1, fetch_time=BASE_T0 + 20),  # 0.33 min -> removed (below)
            waybill(2, t0=BASE_T0 + 60),
            waybill(3, t0=BASE_T0 + 120, fetch_time=BASE_T0 + 120 + 8000),  # 133 min -> removed (above)
            waybill(4, t0=BASE_T0 + 180, is_prebook=1),
        ]
    )
    orders, info = build_orders(raw, cfg)
    assert orders["order_id"].tolist() == [2]
    assert info["removed_below"] == 1 and info["removed_above"] == 1
    # outlier orders still count toward load: order 2 sees order 1 (created 60 s earlier)
    assert orders.loc[0, "poi_orders_last_30m"] == 1
    assert orders.loc[0, "poi_open_orders"] == 0  # order 1 was fetched at t0+20 < order 2's t0
    assert pd.api.types.is_string_dtype(orders["poi_id"]) and orders.loc[0, "poi_id"] == "10"
    assert not (set(orders.columns) & (FORBIDDEN - {TARGET, BENCHMARK, "fetch_time"}))


def test_build_orders_deterministic(waybill, frame, cfg):
    rows = [waybill(i, t0=BASE_T0 + 37 * i, poi_id=i % 3) for i in range(30)]
    a, _ = build_orders(frame(rows), cfg)
    b, _ = build_orders(frame(rows[::-1]), cfg)
    pd.testing.assert_frame_equal(
        a.sort_values("order_id").reset_index(drop=True), b.sort_values("order_id").reset_index(drop=True)
    )


# ---------------- temporal split ----------------


def test_temporal_split_by_local_date(synthetic_orders, cfg):
    df = synthetic_orders(n_per_day=50).sample(frac=1, random_state=1)
    parts = temporal_split(df, cfg)
    assert parts["train"]["local_date"].max() <= cfg.split.train_last_date
    assert set(parts["val"]["local_date"]) == {cfg.split.val_date}
    assert set(parts["test"]["local_date"]) == {cfg.split.test_date}
    assert sum(len(p) for p in parts.values()) == len(df)
    for p in parts.values():
        assert p["platform_order_time"].is_monotonic_increasing
    assert parts["train"]["platform_order_time"].max() < parts["val"]["platform_order_time"].min()
    assert parts["val"]["platform_order_time"].max() < parts["test"]["platform_order_time"].min()


def test_temporal_split_rejects_rows_after_test_date(synthetic_orders, cfg):
    df = synthetic_orders(n_per_day=10)
    df.loc[0, "local_date"] = "2022-10-25"
    with pytest.raises(ValueError, match="outside the configured split dates"):
        temporal_split(df, cfg)
