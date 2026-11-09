"""Build one model input row from what the RiderOS backend knows at request time.

The backend only has: the dataset restaurant (poi_id + its reference da_id) and the local request time.
This function is the single definition of that mapping and is covered by tests.
"""

from __future__ import annotations

import math
from datetime import datetime

import pandas as pd


def make_feature_row(poi_id: str, da_id: str, local_time: datetime) -> pd.DataFrame:
    if local_time.tzinfo is not None:
        raise ValueError("pass a naive LOCAL datetime (timezone already applied)")
    minute_of_day = local_time.hour * 60 + local_time.minute
    angle = 2 * math.pi * minute_of_day / 1440.0
    return pd.DataFrame(
        [
            {
                "poi_id": str(poi_id),
                "da_id": str(da_id),
                "hour": local_time.hour,
                "minute_sin": math.sin(angle),
                "minute_cos": math.cos(angle),
                "is_weekend": int(local_time.weekday() >= 5),
            }
        ]
    )
