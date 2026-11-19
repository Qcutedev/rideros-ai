import uuid
from datetime import datetime, time
from decimal import Decimal
from typing import Annotated, Any, ClassVar, Literal

from pydantic import BaseModel, ConfigDict, Field, StringConstraints, computed_field, field_validator

from app.core.schemas import PatchModel, StrictModel
from app.modules.shifts.models import SCENARIO_NAME_MAX_LENGTH

EstimationMethod = Literal["assumption", "historical"]
ScenarioName = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=1, max_length=SCENARIO_NAME_MAX_LENGTH)
]
Weekday = Annotated[int, Field(ge=0, le=6, description="0 = Monday ... 6 = Sunday")]


OrdersPerHour = Annotated[Decimal, Field(ge=0, le=30, max_digits=5, decimal_places=2)]
IncomePerOrder = Annotated[Decimal, Field(ge=0, le=10_000, max_digits=8, decimal_places=2)]
KmPerOrder = Annotated[Decimal, Field(ge=0, le=100, max_digits=6, decimal_places=2)]
KmPerLiter = Annotated[Decimal, Field(gt=0, le=1_000, max_digits=6, decimal_places=2)]
PricePerLiter = Annotated[Decimal, Field(ge=0, le=1_000, max_digits=8, decimal_places=2)]
CostPerKm = Annotated[Decimal, Field(ge=0, le=1_000, max_digits=8, decimal_places=4)]
FixedCosts = Annotated[Decimal, Field(ge=0, le=100_000, max_digits=10, decimal_places=2)]


class ShiftAssumptions(StrictModel):
    """Rider inputs. `assumption` needs orders_per_hour and income_per_order; fuel and depreciation
    values fall back to the rider profile when omitted."""

    orders_per_hour: OrdersPerHour | None = None
    income_per_order: IncomePerOrder | None = None
    km_per_order: KmPerOrder | None = None
    fuel_km_per_liter: KmPerLiter | None = None
    fuel_price_per_liter: PricePerLiter | None = None
    depreciation_per_km: CostPerKm | None = None
    other_costs: FixedCosts | None = Field(
        default=None, description="Fixed costs for the shift (parking, food, ...)"
    )


def _no_seconds(value: time | None) -> time | None:
    if value is None:
        return None
    if value.tzinfo is not None:
        raise ValueError("use a local time without a time zone, e.g. 17:30")
    return value.replace(second=0, microsecond=0)


class ShiftScenarioCreate(StrictModel):
    name: ScenarioName
    start_time: time = Field(description="Local time, e.g. 17:00")
    end_time: time = Field(description="Local time; earlier than start_time means the shift ends next day")
    planned_weekday: Weekday | None = None
    estimation_method: EstimationMethod = "assumption"
    assumptions: ShiftAssumptions = Field(default_factory=ShiftAssumptions)
    actual_work_session_id: uuid.UUID | None = None

    @field_validator("start_time", "end_time")
    @classmethod
    def _times(cls, value: time) -> time | None:
        return _no_seconds(value)


class ShiftScenarioUpdate(PatchModel):
    non_nullable: ClassVar[frozenset[str]] = frozenset(
        {"name", "start_time", "end_time", "estimation_method", "assumptions"}
    )

    name: ScenarioName | None = None
    start_time: time | None = None
    end_time: time | None = None
    planned_weekday: Weekday | None = None
    estimation_method: EstimationMethod | None = None
    assumptions: ShiftAssumptions | None = Field(default=None, description="Replaces all assumptions")
    actual_work_session_id: uuid.UUID | None = None

    @field_validator("start_time", "end_time")
    @classmethod
    def _times(cls, value: time | None) -> time | None:
        return _no_seconds(value)


class ShiftScenarioOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    start_time: time
    end_time: time
    duration_minutes: int
    planned_weekday: int | None
    estimation_method: EstimationMethod
    assumptions: dict[str, Any]
    is_estimate: Literal[True] = Field(default=True, description="Never counted as actual TrueProfit data")
    estimated_revenue: Decimal
    estimated_expenses: Decimal
    estimated_net_profit: Decimal
    estimate_low: Decimal | None = Field(description="Low end of the net-profit range (historical only)")
    estimate_high: Decimal | None
    estimate_details: dict[str, Any]
    actual_work_session_id: uuid.UUID | None
    created_at: datetime
    updated_at: datetime

    @computed_field
    @property
    def estimated_net_profit_per_hour(self) -> Decimal:
        return (self.estimated_net_profit * 60 / Decimal(self.duration_minutes)).quantize(Decimal("0.01"))


class CompareRequest(StrictModel):
    ids: Annotated[list[uuid.UUID], Field(min_length=2, max_length=5)]

    @field_validator("ids")
    @classmethod
    def _unique(cls, value: list[uuid.UUID]) -> list[uuid.UUID]:
        if len(set(value)) != len(value):
            raise ValueError("ids must be unique")
        return value


class CompareResult(BaseModel):
    scenarios: list[ShiftScenarioOut] = Field(description="In the order of `ids`")
    best_net_profit_id: uuid.UUID
    best_net_profit_per_hour_id: uuid.UUID
