"""Validation gate on synthetic waybill tables."""

from __future__ import annotations

import pandas as pd
import pytest

from rideros_ml.data import schema
from rideros_ml.data.validate import ambiguous_orders, local_datetime, target_tail_profile, validate_waybills

DAY = 86_400


def _check(report, name):
    matches = [c for c in report.checks if c.name == name]
    assert len(matches) == 1, name
    return matches[0]


@pytest.fixture
def clean_raw(waybill, frame, rejected):
    """One order per day over 2022-10-17..24 (all 8 dt values), plus one rejected-then-grabbed order."""
    t_first = int(pd.Timestamp("2022-10-17 03:00:00").timestamp())
    rows = [waybill(i, t0=t_first + i * DAY) for i in range(8)]
    rows.append(waybill(100, t0=t_first + DAY, **rejected))
    rows.append(
        waybill(100, t0=t_first + DAY, dispatch_time=t_first + DAY + 100, grab_time=t_first + DAY + 160)
    )
    return frame(rows)


def test_clean_table_passes(clean_raw, cfg):
    report = validate_waybills(clean_raw, cfg)
    assert report.ok, [c for c in report.blocking_failures]
    # row count differs from the official 654,343 -> warning only, not blocking
    assert _check(report, "row_count").passed is False
    assert _check(report, "row_count").severity == "warn"


def test_missing_column_stops_validation(clean_raw, cfg):
    report = validate_waybills(clean_raw.drop(columns=["fetch_time"]), cfg)
    assert not report.ok
    assert [c.name for c in report.checks] == ["schema_columns"]


def test_unexpected_column_fails(clean_raw, cfg):
    report = validate_waybills(clean_raw.assign(extra=1), cfg)
    assert not _check(report, "schema_columns").passed
    assert not report.ok


def test_nan_fails(clean_raw, cfg):
    raw = clean_raw.astype({"courier_id": float})
    raw.loc[0, "courier_id"] = float("nan")
    assert not _check(validate_waybills(raw, cfg), "no_nan").passed


def test_duplicate_waybill_id_fails(clean_raw, cfg):
    raw = clean_raw.copy()
    raw.loc[1, "waybill_id"] = raw.loc[0, "waybill_id"]
    assert not _check(validate_waybills(raw, cfg), "waybill_id_unique").passed


def test_dt_range_requires_all_8_days(clean_raw, cfg):
    raw = clean_raw[clean_raw["dt"] != 20221024]
    assert not _check(validate_waybills(raw, cfg), "dt_range").passed


@pytest.mark.parametrize("col", ["grab_time", "fetch_time", "arrive_time"])
def test_rejected_waybill_with_times_fails(clean_raw, cfg, col):
    raw = clean_raw.copy()
    rej = raw.index[raw["is_courier_grabbed"] == 0][0]
    raw.loc[rej, col] = raw.loc[rej, "platform_order_time"] + 100
    report = validate_waybills(raw, cfg)
    assert not _check(report, "rejected_waybill_consistency").passed
    assert not report.ok


def test_two_pickups_for_one_order_fails(clean_raw, cfg):
    raw = clean_raw.copy()
    raw.loc[raw["order_id"] == 100, "is_courier_grabbed"] = 1
    raw.loc[raw["order_id"] == 100, "fetch_time"] = raw["platform_order_time"] + 900
    raw.loc[raw["order_id"] == 100, "grab_time"] = raw["platform_order_time"] + 60
    raw.loc[raw["order_id"] == 100, "arrive_time"] = raw["platform_order_time"] + 1500
    assert not _check(validate_waybills(raw, cfg), "one_pickup_per_order").passed


def test_order_without_pickup_is_allowed(clean_raw, waybill, rejected, frame, cfg):
    raw = frame([*clean_raw.to_dict("records"), waybill(200, **rejected)])
    report = validate_waybills(raw, cfg)
    assert _check(report, "one_pickup_per_order").passed
    assert "without_pickup=1" in _check(report, "one_pickup_per_order").detail


def test_fetch_before_order_creation_fails(clean_raw, cfg):
    raw = clean_raw.copy()
    raw.loc[0, "fetch_time"] = raw.loc[0, "platform_order_time"] - 1
    raw.loc[0, "arrive_time"] = raw.loc[0, "platform_order_time"] + 10
    report = validate_waybills(raw, cfg)
    chrono = _check(report, "chronology")
    assert not chrono.passed
    assert chrono.data["counts"]["platform_order_time<=fetch_time"] == 1


def test_noncritical_chronology_violation_does_not_block(clean_raw, cfg):
    """push > dispatch happens once in the real data; only t0<=fetch and grab<=fetch are blocking."""
    raw = clean_raw.copy()
    raw.loc[0, "order_push_time"] = raw.loc[0, "dispatch_time"] + 1
    chrono = _check(validate_waybills(raw, cfg), "chronology")
    assert chrono.passed
    assert chrono.data["counts"]["order_push_time<=dispatch_time"] == 1


def test_core_attribute_varying_across_waybills_fails(clean_raw, cfg):
    raw = clean_raw.copy()
    raw.loc[raw["order_id"] == 100, "poi_id"] = [10, 11]
    assert not _check(validate_waybills(raw, cfg), "order_core_attributes_constant").passed


def test_ambiguous_orders_detected(clean_raw, cfg):
    raw = clean_raw.copy()
    idx = raw.index[raw["order_id"] == 100]
    raw.loc[idx[0], "recipient_lat"] += 1
    assert list(ambiguous_orders(raw)) == [100]
    check = _check(validate_waybills(raw, cfg), "order_ambiguous_attributes")
    # 1 of 9 orders is far above the 0.05% tolerance
    assert not check.passed


def test_da_id_change_on_redispatch_is_info_only(clean_raw, cfg):
    raw = clean_raw.copy()
    raw.loc[raw["order_id"] == 100, "da_id"] = [1, 2]
    check = _check(validate_waybills(raw, cfg), "da_id_waybill_level")
    assert check.severity == "info"
    assert "=1;" in check.detail


# ---------------- timezone ----------------


def test_local_datetime_applies_offset():
    s = pd.Series([int(pd.Timestamp("2022-10-21 18:00:00").timestamp())])
    assert local_datetime(s, 8).iloc[0] == pd.Timestamp("2022-10-22 02:00:00")


def test_timezone_check_detects_wrong_offset(waybill, frame, cfg, cfg_with):
    # Local Saturday 02:00 (UTC+8) is still Friday in UTC -> is_weekend disagrees under offset 0.
    t_fri_utc = int(pd.Timestamp("2022-10-21 18:00:00").timestamp())
    raw = frame([waybill(i, t0=t_fri_utc + i * 60) for i in range(20)])
    assert (raw["is_weekend"] == 1).all()
    ok = _check(validate_waybills(raw, cfg), "timezone_is_weekend_agreement")
    wrong = _check(
        validate_waybills(raw, cfg_with(cfg, dataset={"local_utc_offset_hours": 0})),
        "timezone_is_weekend_agreement",
    )
    assert ok.passed
    assert not wrong.passed


def test_target_tail_profile_counts():
    df = pd.DataFrame({"y": [0.2, 0.8, 1.5, 10, 70, 130, 200]})
    tails = target_tail_profile(df, "y")
    assert tails["n"] == 7
    assert tails["below"]["1"] == 2
    assert tails["above"]["120"] == 2
    assert tails["above"]["180"] == 1


def test_post_t0_columns_are_in_schema():
    assert schema.POST_T0_COLUMNS <= schema.EXPECTED_COLUMNS
    assert schema.PLATFORM_ESTIMATE_COLUMNS <= schema.EXPECTED_COLUMNS
    assert "platform_order_time" not in schema.POST_T0_COLUMNS
