"""Data validation gate for the raw Meituan waybill table.

Every check returns a CheckResult. Any failed check with severity "error" blocks the pipeline.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Literal

import numpy as np
import pandas as pd

from rideros_ml.config import Config
from rideros_ml.data import schema

Severity = Literal["error", "warn", "info"]


@dataclass
class CheckResult:
    name: str
    passed: bool
    severity: Severity
    detail: str
    data: dict = field(default_factory=dict)


@dataclass
class ValidationReport:
    checks: list[CheckResult]

    @property
    def blocking_failures(self) -> list[CheckResult]:
        return [c for c in self.checks if c.severity == "error" and not c.passed]

    @property
    def ok(self) -> bool:
        return not self.blocking_failures

    def to_dict(self) -> dict:
        return {"ok": self.ok, "checks": [asdict(c) for c in self.checks]}


def local_datetime(unix_seconds: pd.Series, utc_offset_hours: int) -> pd.Series:
    """Unix seconds -> naive local datetime using a fixed UTC offset (China has no DST)."""
    return pd.to_datetime(unix_seconds, unit="s") + pd.Timedelta(hours=utc_offset_hours)


def _check(name: str, passed: bool, severity: Severity, detail: str, **data) -> CheckResult:
    return CheckResult(name, bool(passed), severity, detail, {k: _jsonable(v) for k, v in data.items()})


def _jsonable(v):
    if isinstance(v, (np.integer,)):
        return int(v)
    if isinstance(v, (np.floating,)):
        return float(v)
    if isinstance(v, dict):
        return {str(k): _jsonable(x) for k, x in v.items()}
    if isinstance(v, (list, tuple)):
        return [_jsonable(x) for x in v]
    return v


def grabbed_waybills(df: pd.DataFrame) -> pd.DataFrame:
    return df[(df["is_courier_grabbed"] == 1) & (df["fetch_time"] > 0)]


def ambiguous_orders(df: pd.DataFrame) -> pd.Index:
    """Orders whose t0 or delivery coordinates differ between their waybills (excluded from modelling)."""
    nun = df.groupby("order_id")[["platform_order_time", "recipient_lat", "recipient_lng"]].nunique()
    return nun.index[(nun > 1).any(axis=1)]


def validate_waybills(df: pd.DataFrame, cfg: Config) -> ValidationReport:
    ds = cfg.dataset
    checks: list[CheckResult] = []

    # 1. Schema
    cols = set(df.columns)
    missing, unexpected = schema.EXPECTED_COLUMNS - cols, cols - schema.EXPECTED_COLUMNS
    checks.append(
        _check(
            "schema_columns",
            not missing and not unexpected,
            "error",
            f"missing={sorted(missing)} unexpected={sorted(unexpected)}",
        )
    )
    if missing:
        return ValidationReport(checks)  # nothing else is meaningful

    # 2. Row count vs official documentation
    checks.append(
        _check(
            "row_count", len(df) == ds.expected_rows, "warn", f"rows={len(df)} expected={ds.expected_rows}"
        )
    )

    # 3. Missing values (the dataset encodes "no time" as 0, never NaN)
    na = df.isna().sum()
    checks.append(
        _check(
            "no_nan",
            int(na.sum()) == 0,
            "error",
            f"NaN cells={int(na.sum())}",
            per_column=na[na > 0].to_dict(),
        )
    )

    # 4. Keys
    checks.append(
        _check(
            "waybill_id_unique",
            df["waybill_id"].is_unique,
            "error",
            f"duplicates={int(df['waybill_id'].duplicated().sum())}",
        )
    )
    checks.append(
        _check(
            "no_duplicate_rows",
            not df.duplicated().any(),
            "error",
            f"duplicate rows={int(df.duplicated().sum())}",
        )
    )

    # 5. dt range
    dts = sorted(df["dt"].unique().tolist())
    checks.append(
        _check(
            "dt_range",
            dts[0] == 20221017 and dts[-1] == 20221024 and len(dts) == 8,
            "error",
            f"dt values={dts}",
        )
    )

    # 6. Plausible timestamps (non-zero values)
    lo, hi = pd.Timestamp("2022-10-01").timestamp(), pd.Timestamp("2022-11-01").timestamp()
    out_of_range = {}
    for c in schema.TIME_COLUMNS:
        s = df[c]
        nz = s[s > 0]
        out_of_range[c] = int(((nz < lo) | (nz > hi)).sum())
    checks.append(
        _check(
            "timestamps_plausible",
            sum(out_of_range.values()) == 0,
            "warn",
            "non-zero timestamps outside Oct 2022",
            counts=out_of_range,
        )
    )
    zero_counts = {c: int((df[c] == 0).sum()) for c in schema.TIME_COLUMNS}
    checks.append(
        _check("timestamp_zero_counts", True, "info", "0 = event did not happen", counts=zero_counts)
    )

    # 7. Rejected-waybill consistency (Supplementary 2.4)
    rejected = df["is_courier_grabbed"] == 0
    inconsistent = int(
        (rejected & ((df["grab_time"] > 0) | (df["fetch_time"] > 0) | (df["arrive_time"] > 0))).sum()
    )
    grabbed_missing_fetch = int((~rejected & (df["fetch_time"] == 0)).sum())
    checks.append(
        _check(
            "rejected_waybill_consistency",
            inconsistent == 0,
            "error",
            f"rejected-but-has-times={inconsistent}; grabbed-without-fetch={grabbed_missing_fetch}",
            rejected=int(rejected.sum()),
        )
    )

    # 8. Exactly one picked-up waybill per order
    g = grabbed_waybills(df)
    per_order = g.groupby("order_id").size()
    n_orders = df["order_id"].nunique()
    orders_without_pickup = n_orders - per_order.size
    orders_multi_pickup = int((per_order > 1).sum())
    checks.append(
        _check(
            "one_pickup_per_order",
            orders_multi_pickup == 0,
            "error",
            f"orders={n_orders} with_pickup={per_order.size} without_pickup={orders_without_pickup} multi_pickup={orders_multi_pickup}",
        )
    )

    # 9. Order-level attributes across an order's waybills
    by_order = df.groupby("order_id")
    core = ["poi_id", "is_prebook", "sender_lat", "sender_lng"]
    varying = {c: int((by_order[c].nunique() > 1).sum()) for c in core}
    checks.append(
        _check(
            "order_core_attributes_constant",
            sum(varying.values()) == 0,
            "error",
            "orders whose core attribute differs across waybills",
            counts=varying,
        )
    )
    # t0 and delivery address must be unambiguous. A tiny share of conflicting orders is tolerated and EXCLUDED in build.
    ambiguous = {
        c: int((by_order[c].nunique() > 1).sum())
        for c in ["platform_order_time", "recipient_lat", "recipient_lng"]
    }
    n_ambiguous = len(ambiguous_orders(df))
    share = n_ambiguous / n_orders
    checks.append(
        _check(
            "order_ambiguous_attributes",
            share < 5e-4,
            "error",
            f"orders with conflicting t0 or recipient across waybills={n_ambiguous} ({share:.5%}); excluded in build (tolerance 0.05%)",
            counts=ambiguous,
        )
    )
    # da_id is a waybill-level attribute (Supplementary 2.6: linked to location AND order type, areas may overlap).
    da_varying = int((by_order["da_id"].nunique() > 1).sum())
    checks.append(
        _check(
            "da_id_waybill_level",
            True,
            "info",
            f"orders whose da_id differs across waybills={da_varying}; build uses the da_id of the FIRST dispatched waybill (closest to t0)",
        )
    )

    # 10. Chronology for picked-up waybills
    pairs = [
        ("platform_order_time", "order_push_time"),
        ("order_push_time", "dispatch_time"),
        ("dispatch_time", "grab_time"),
        ("grab_time", "fetch_time"),
        ("fetch_time", "arrive_time"),
        ("platform_order_time", "fetch_time"),
    ]
    viol = {f"{a}<={b}": int((g[b] < g[a]).sum()) for a, b in pairs}
    critical = viol["platform_order_time<=fetch_time"] + viol["grab_time<=fetch_time"]
    checks.append(
        _check(
            "chronology",
            critical == 0,
            "error",
            "violations (later event earlier than earlier event)",
            counts=viol,
        )
    )

    # 11. Coordinates present for pickup and delivery
    zero_coords = {
        c: int((df[c] == 0).sum()) for c in ["sender_lat", "sender_lng", "recipient_lat", "recipient_lng"]
    }
    checks.append(
        _check(
            "coordinates_present",
            sum(zero_coords.values()) == 0,
            "warn",
            "zero coordinates",
            counts=zero_coords,
        )
    )

    # 12. Timezone: is_weekend must agree with the local weekday of t0 under the configured UTC offset
    local = local_datetime(df["platform_order_time"], ds.local_utc_offset_hours)
    computed_weekend = (local.dt.day_of_week >= 5).astype(int)
    agree = float((computed_weekend == df["is_weekend"]).mean())
    utc_agree = float(
        (
            (pd.to_datetime(df["platform_order_time"], unit="s").dt.day_of_week >= 5).astype(int)
            == df["is_weekend"]
        ).mean()
    )
    checks.append(
        _check(
            "timezone_is_weekend_agreement",
            agree >= 0.999,
            "error",
            f"agreement UTC+{ds.local_utc_offset_hours}={agree:.5f} (UTC would be {utc_agree:.5f})",
        )
    )
    dt_agree = float((local.dt.strftime("%Y%m%d").astype(int) == df["dt"]).mean())
    checks.append(
        _check(
            "dt_vs_local_order_date",
            True,
            "info",
            f"share of rows where dt == local date of t0: {dt_agree:.5f}",
        )
    )

    # 13. Prebook share and platform estimate availability
    checks.append(_check("prebook_share", True, "info", f"is_prebook share={df['is_prebook'].mean():.4f}"))

    return ValidationReport(checks)


def target_tail_profile(orders: pd.DataFrame, target: str) -> dict:
    """Tail counts used to decide (and document) the target cleaning rule."""
    y = orders[target]
    thresholds_low = [0.5, 1, 2, 3]
    thresholds_high = [60, 90, 120, 180, 240]
    return {
        "n": int(len(y)),
        "quantiles": {str(q): float(y.quantile(q)) for q in [0.0, 0.001, 0.01, 0.5, 0.99, 0.999, 1.0]},
        "below": {str(t): int((y < t).sum()) for t in thresholds_low},
        "above": {str(t): int((y > t).sum()) for t in thresholds_high},
    }
