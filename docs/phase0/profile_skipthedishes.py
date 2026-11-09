"""Profile the SkipTheDishes food-prep dataset (read-only, no code from the repo is executed)."""
import sys
from pathlib import Path

import numpy as np
import pandas as pd

root = Path(sys.argv[1])
pd.set_option("display.width", 200)


def section(t):
    print(f"\n==================== {t} ====================")


raw_train = pd.read_csv(root / "train_orders_data_with_targets.csv")
raw_test = pd.read_csv(root / "test_orders_data_without_targets.csv")
test_y = pd.read_csv(root / "test_orders_target.csv")
menu = pd.read_csv(root / "menu_items_details_complete.csv")
menu_clean = pd.read_csv(root / "menu_clean.csv")

for name, df in [("raw_train", raw_train), ("raw_test", raw_test), ("test_y", test_y), ("menu", menu), ("menu_clean", menu_clean)]:
    section(f"{name}: shape={df.shape}")
    print("dtypes:", dict(df.dtypes.astype(str).value_counts()))
    print("columns:", list(df.columns)[:30], "..." if df.shape[1] > 30 else "")
    na = df.isna().sum()
    print("missing (non-zero):", dict(na[na > 0]))
    print("duplicate rows:", int(df.duplicated().sum()))
    if "order_id" in df.columns:
        print("duplicate order_id:", int(df["order_id"].duplicated().sum()))

section("target: food_prep_time_minutes (train)")
y = raw_train["food_prep_time_minutes"]
print(y.describe(percentiles=[.01, .05, .25, .5, .75, .95, .99]).round(3).to_string())
print("dtype:", y.dtype, "| all integer:", bool((y == y.round()).all()), "| n unique:", y.nunique())
print("<=0:", int((y <= 0).sum()), "| >120:", int((y > 120).sum()))

section("target: test_orders_target")
print(test_y["food_prep_time_minutes"].describe().round(3).to_string())
print("test ids match target ids:", set(raw_test.order_id) == set(test_y.order_id))
print("train/test order_id overlap:", len(set(raw_train.order_id) & set(test_y.order_id)))

section("datetime")
for name, df in [("train", raw_train), ("test", raw_test)]:
    dt = pd.to_datetime(df["datetime"], errors="coerce")
    print(name, "min:", dt.min(), "max:", dt.max(), "unparseable:", int(dt.isna().sum()))
    print(name, "days:", dt.dt.date.nunique(), "| hour range:", dt.dt.hour.min(), "-", dt.dt.hour.max())
    print(name, "orders by weekday:", dict(dt.dt.day_name().value_counts()))

section("items / quantities")
item_cols = [f"item_{i}" for i in range(1, 11)]
qty_cols = [f"quantity_{i}" for i in range(1, 11)]
n_items = raw_train[item_cols].notna().sum(axis=1)
print("items per order:", dict(n_items.value_counts().sort_index()))
q = raw_train[qty_cols].stack()
print("quantity values:", dict(q.value_counts().sort_index().head(15)))
all_items = pd.unique(raw_train[item_cols].stack())
print("distinct item ids in train:", len(all_items))
print("menu rows:", len(menu), "| distinct menu ids:", menu.menu_item_id.nunique())
unknown = set(all_items) - set(menu.menu_item_id)
print("train item ids NOT in menu:", len(unknown))
test_items = pd.unique(raw_test[item_cols].stack())
print("test item ids NOT in menu:", len(set(test_items) - set(menu.menu_item_id)))
print("test item ids NOT seen in train:", len(set(test_items) - set(all_items)))

section("menu categories")
print("menu category (raw) value counts:", dict(menu["category"].value_counts(dropna=False)))
print("menu_clean category:", dict(menu_clean["category"].value_counts(dropna=False)))
print("menu_clean category_type:", dict(menu_clean["category_type"].value_counts(dropna=False)))
print("sample titles:", list(menu.title.head(10)))

section("restaurant / location / price columns?")
for kw in ["restaurant", "store", "vendor", "merchant", "lat", "lon", "price", "value", "total", "courier", "driver", "rider", "arrival", "pickup"]:
    hits = [c for c in list(raw_train.columns) + list(menu.columns) if kw in c.lower()]
    print(f"{kw!r}: {hits}")

section("simple signal checks (train only, no modelling)")
tot_qty = raw_train[qty_cols].sum(axis=1)
hour = pd.to_datetime(raw_train["datetime"]).dt.hour
print("corr(target, total_qty):", round(float(np.corrcoef(tot_qty, y)[0, 1]), 3))
print("corr(target, n_items):", round(float(np.corrcoef(n_items, y)[0, 1]), 3))
print("mean target by n_items:", dict(y.groupby(n_items).mean().round(2)))
print("mean target by hour:", dict(y.groupby(hour).mean().round(2)))

section("other files")
for f in ["train_clean.csv", "test_clean.csv", "final_predictions.csv"]:
    df = pd.read_csv(root / f, nrows=5)
    full_rows = sum(1 for _ in open(root / f, encoding="utf-8")) - 1
    print(f, "rows:", full_rows, "cols:", df.shape[1])
tc = pd.read_csv(root / "train_clean.csv", nrows=3)
print("train_clean has target column:", "food_prep_time_minutes" in tc.columns)
print("train_clean extra cols sample:", [c for c in tc.columns if not c.startswith("quant_")][:40])
print("n quant_ cols:", sum(c.startswith("quant_") for c in tc.columns))
