"""A tiny restaurant_stats export (same files and columns as ml/artifacts/restaurant_stats/<version>/)."""

import json
from pathlib import Path

REFERENCE = """poi_id,n_orders,median_min,p25_min,p75_min,p90_min,reference_da_id,peak_hour,data_availability
0,566,15.408,12.025,19.588,25.108,0,11,sufficient
1,12,10.433,7.892,13.992,18.04,1,12,limited
5,3,9.5,8.0,11.0,12.5,2,18,insufficient
"""
TIME_STATS = """poi_id,day_type,hour,n_orders,median_min,p25_min,p75_min,p90_min
0,weekday,11,40,13.908,11.433,17.671,19.95
0,weekday,12,35,14.0,12.0,16.0,18.0
0,weekend,18,2,17.133,14.925,19.342,20.667
1,weekday,12,12,10.4,7.9,14.0,18.0
"""


def write_stats(folder: Path, *, reference: str = REFERENCE, time_stats: str = TIME_STATS) -> Path:
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "restaurant_reference.csv").write_text(reference, encoding="utf-8")
    (folder / "restaurant_time_stats.csv").write_text(time_stats, encoding="utf-8")
    n_ref = len(reference.strip().splitlines()) - 1
    n_cells = len(time_stats.strip().splitlines()) - 1
    summary = {"source_orders_parquet_sha256": "ab" * 32, "n_restaurants": n_ref, "n_time_cells": n_cells}
    (folder / "summary.json").write_text(json.dumps(summary), encoding="utf-8")
    return folder
