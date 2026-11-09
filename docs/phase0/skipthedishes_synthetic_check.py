"""Phase-0 data-quality probe: is the target near-deterministic / synthetic? (train file only, no model fitting)."""
import sys
from pathlib import Path

import numpy as np
import pandas as pd

root = Path(sys.argv[1])
df = pd.read_csv(root / "train_orders_data_with_targets.csv")
y = df["food_prep_time_minutes"]
dt = pd.to_datetime(df["datetime"])

print("quantity_1 values:", dict(df["quantity_1"].value_counts()))
print("target histogram (counts per value, first 47):")
print(dict(y.value_counts().sort_index()))

single = df[df["item_2"].isna()].copy()
single["hour_block"] = dt[single.index].dt.hour // 3
g = single.groupby(["item_1", "quantity_1"])["food_prep_time_minutes"]
stats = g.agg(["count", "mean", "std", "min", "max"])
print("\nsingle-item orders:", len(single), "| (item, qty) groups:", len(stats))
print("within-group std: median", round(stats["std"].median(), 2), "| mean", round(stats["std"].mean(), 2))
print(stats.sort_values("count", ascending=False).head(8).round(2).to_string())

print("\nmean target by weekday:", dict(y.groupby(dt.dt.day_name()).mean().round(2)))
print("mean target by 3h block:", dict(y.groupby(dt.dt.hour // 3).mean().round(2)))
print("orders by hour:", dict(dt.dt.hour.value_counts().sort_index()))
