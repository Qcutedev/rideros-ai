"""Phase-0 feasibility probe of Meituan waybill data: columns, missingness, derivable prep / rider-wait times."""
import sys

import numpy as np
import pandas as pd

df = pd.read_csv(sys.argv[1])
print("shape:", df.shape)
print("columns:", list(df.columns))
print(df.head(3).T.to_string())
na = df.isna().sum()
print("missing (non-zero):", dict(na[na > 0]))
print("duplicate rows:", int(df.duplicated().sum()))
for c in ["order_id", "waybill_id", "poi_id", "courier_id", "da_id", "dt"]:
    if c in df.columns:
        print(f"n unique {c}:", df[c].nunique())

ts_cols = [c for c in df.columns if c.endswith("_time")]
print("time cols:", ts_cols)
for c in ts_cols:
    s = df[c]
    print(f"{c}: zeros={int((s == 0).sum())} min={s[s > 0].min()} max={s.max()}")


def mins(a, b):
    m = (df[a] > 0) & (df[b] > 0)
    d = (df.loc[m, b] - df.loc[m, a]) / 60
    return d


pairs = [
    ("platform_order_time", "estimate_meal_prepare_time"),
    ("platform_order_time", "order_push_time"),
    ("platform_order_time", "arrive_time"),
    ("grab_time", "fetch_time"),
    ("platform_order_time", "fetch_time"),
    ("estimate_meal_prepare_time", "fetch_time"),
    ("fetch_time", "arrive_time"),
]
for a, b in pairs:
    if a in df.columns and b in df.columns:
        d = mins(a, b)
        print(f"{b} - {a} (min): n={len(d)}", d.describe(percentiles=[.05, .5, .95]).round(2).to_dict())
