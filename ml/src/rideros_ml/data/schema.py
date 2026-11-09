"""Expected schema of all_waybill_info_meituan.csv.

Column names and meanings come from the official "Background and Data Description" (2024-03-21, Tables 1-2)
and the "Supplementary Document" (2024-10-15). The CSV also carries an unnamed pandas index column.
"""

from __future__ import annotations

INDEX_COLUMN = "Unnamed: 0"

ID_COLUMNS = ["order_id", "waybill_id", "courier_id", "poi_id", "da_id"]
TIME_COLUMNS = [
    "platform_order_time",  # order created (t0)
    "order_push_time",  # order enters dispatch system
    "estimate_meal_prepare_time",  # platform ESTIMATE of meal-ready time (Supplementary 2.5)
    "estimate_arrived_time",  # promised delivery time
    "dispatch_time",  # waybill assigned to a courier
    "grab_time",  # courier accepted (0 if rejected, Supplementary 2.4)
    "fetch_time",  # courier picked up food
    "arrive_time",  # delivered
]
COORD_COLUMNS = ["sender_lat", "sender_lng", "recipient_lat", "recipient_lng", "grab_lat", "grab_lng"]
FLAG_COLUMNS = ["is_courier_grabbed", "is_prebook", "is_weekend"]
DATE_COLUMNS = ["dt"]

EXPECTED_COLUMNS = {INDEX_COLUMN, *ID_COLUMNS, *TIME_COLUMNS, *COORD_COLUMNS, *FLAG_COLUMNS, *DATE_COLUMNS}

# Columns that describe events AFTER the order is created. Never usable as model inputs (leakage).
POST_T0_COLUMNS = frozenset(
    {
        "order_push_time",
        "dispatch_time",
        "courier_id",
        "grab_lat",
        "grab_lng",
        "is_courier_grabbed",
        "grab_time",
        "fetch_time",
        "arrive_time",
        "waybill_id",
    }
)
# Known at t0 on the platform, but produced by Meituan's own systems -> benchmark / excluded, not features.
PLATFORM_ESTIMATE_COLUMNS = frozenset({"estimate_meal_prepare_time", "estimate_arrived_time"})

# Coordinates are integers scaled by 1e6 and uniformly shifted (not scaled) for privacy (Supplementary 2.1).
COORD_SCALE = 1_000_000
