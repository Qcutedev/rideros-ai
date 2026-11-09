import uuid
from datetime import datetime
from decimal import Decimal
from typing import Annotated, Any, Literal

from pydantic import AwareDatetime, BaseModel, Field, StringConstraints

from app.core.schemas import StrictModel
from app.modules.pickup.models import PICKUP_LOG_NOTES_MAX_LENGTH, RESTAURANT_NAME_MAX_LENGTH

DataAvailability = Literal["sufficient", "limited", "insufficient"]
SourceFilter = Literal["dataset", "user"]

ACKNOWLEDGEMENT = "This research was supported by data provided by Meituan."
PREDICTION_DISCLAIMER = (
    "Estimate of order-to-pickup time (order placed -> rider picks up), learned from Meituan data of one "
    "Chinese city in October 2022. It is not the food preparation time or your waiting time at the "
    "restaurant, and Thai restaurants may differ."
)

# ---- restaurants ----


class Coordinates(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)


class RestaurantCreate(StrictModel):
    name: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=1, max_length=RESTAURANT_NAME_MAX_LENGTH)
    ]
    location: Coordinates | None = None


class RestaurantOut(BaseModel):
    id: uuid.UUID
    source: str
    name: str
    is_own: bool = Field(description="True for restaurants the rider created (Pickup Log only)")
    supports_prediction: bool = Field(description="Only dataset restaurants are known to the model")
    data_availability: DataAvailability | None
    n_orders: int | None
    location: Coordinates | None = Field(description="Only for the rider's own restaurants")
    created_at: datetime


class StatCell(BaseModel):
    hour: int
    n_orders: int
    median_min: Decimal | None
    p25_min: Decimal | None
    p75_min: Decimal | None
    p90_min: Decimal | None


class OverallStats(BaseModel):
    n_orders: int
    median_min: Decimal | None
    p25_min: Decimal | None
    p75_min: Decimal | None
    p90_min: Decimal | None
    peak_hour: int | None


class RestaurantAnalytics(BaseModel):
    restaurant: RestaurantOut
    metric: Literal["order_to_pickup_minutes"] = "order_to_pickup_minutes"
    data_availability: DataAvailability
    overall: OverallStats | None = Field(description="null for the rider's own restaurants")
    by_hour: dict[Literal["weekday", "weekend"], list[StatCell]] = Field(
        description="24 cells per day type (hour 0-23); cells without orders have n_orders 0"
    )
    min_orders_for_stats: int = 30
    dataset_version: str | None
    acknowledgement: str | None


class WaitStats(BaseModel):
    """Real rider wait (picked_up_at - arrived_at) from the rider's own Pickup Log."""

    restaurant_id: uuid.UUID
    n: int
    median_minutes: Decimal | None
    p80_minutes: Decimal | None
    confidence: Literal["insufficient", "low", "ok"] = Field(
        description="insufficient: n < 5 (no stats), low: 5 <= n < 20, ok: n >= 20"
    )


# ---- pickup logs ----


class PickupLogCreate(StrictModel):
    restaurant_id: uuid.UUID
    arrived_at: AwareDatetime
    picked_up_at: AwareDatetime
    notes: (
        Annotated[str, StringConstraints(strip_whitespace=True, max_length=PICKUP_LOG_NOTES_MAX_LENGTH)]
        | None
    ) = None


class PickupLogOut(BaseModel):
    id: uuid.UUID
    restaurant_id: uuid.UUID
    restaurant_name: str
    arrived_at: datetime
    picked_up_at: datetime
    wait_minutes: Decimal
    notes: str | None
    created_at: datetime


# ---- predictions ----


class PredictionCreate(StrictModel):
    restaurant_id: uuid.UUID
    requested_at: AwareDatetime | None = Field(
        default=None, description="When the order is placed (default: now); interpreted in the rider's zone"
    )


class Interval(BaseModel):
    low: Decimal
    high: Decimal
    nominal_coverage: float | None = Field(
        description="Target coverage of the conformal interval; null in history rows of an unloaded version"
    )


class PredictionOut(BaseModel):
    id: uuid.UUID
    restaurant_id: uuid.UUID | None
    restaurant_name: str | None
    metric: Literal["order_to_pickup_minutes"] = "order_to_pickup_minutes"
    predicted_minutes: Decimal = Field(description="Point estimate; show the interval, not this number alone")
    interval: Interval
    data_availability: DataAvailability
    warnings: list[str]
    model_version: str
    requested_at: datetime
    input_features: dict[str, Any]
    disclaimer: str = PREDICTION_DISCLAIMER
    created_at: datetime


# ---- model info ----


class ModelInfo(BaseModel):
    name: str
    version: str
    task: str
    target: dict[str, Any]
    dataset: str
    domain: str
    trained_at: datetime | None
    test_metrics: dict[str, Any] = Field(description="Single evaluation on the held-out test day")
    baseline_test_metrics: dict[str, Any] | None
    interval: dict[str, Any]
    limitations: list[str]
    acknowledgement: str = ACKNOWLEDGEMENT
