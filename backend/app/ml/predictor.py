"""Turn (restaurant, local time) into a model input row and a prediction with its interval."""

import math
from dataclasses import dataclass
from datetime import datetime
from typing import Any

from rideros_ml.features.inference import make_feature_row  # the single definition shared with training
from starlette.concurrency import run_in_threadpool

from app.ml.registry import LoadedModel


@dataclass(frozen=True, slots=True)
class Prediction:
    minutes: float
    low: float
    high: float
    features: dict[str, Any]


def _predict_sync(model: LoadedModel, poi_id: str, da_id: str, local_time: datetime) -> Prediction:
    row = make_feature_row(poi_id, da_id, local_time)
    y_hat = float(model.pipeline.predict(row)[0])
    if not math.isfinite(y_hat):
        raise ValueError("model returned a non-finite prediction")
    y_hat = max(y_hat, 0.0)
    low, high = model.conformal.interval(y_hat)
    features = {k: (v.item() if hasattr(v, "item") else v) for k, v in row.iloc[0].to_dict().items()}
    features["local_time"] = local_time.isoformat()
    return Prediction(y_hat, low, high, features)


async def predict(model: LoadedModel, *, poi_id: str, da_id: str, local_time: datetime) -> Prediction:
    """`local_time` is naive local time (the rider's zone already applied). CPU work runs off the loop."""
    return await run_in_threadpool(_predict_sync, model, poi_id, da_id, local_time)
