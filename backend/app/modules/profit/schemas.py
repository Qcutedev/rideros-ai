import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Annotated, ClassVar, Literal

from pydantic import AwareDatetime, BaseModel, ConfigDict, Field, StringConstraints

from app.core.schemas import PatchModel, StrictModel
from app.modules.profit.models import NOTES_MAX_LENGTH, SOURCE_LABEL_MAX_LENGTH

# ---- field types (bounds mirror the CHECK constraints and numeric precision of the columns) ----

Money = Annotated[Decimal, Field(ge=0, max_digits=12, decimal_places=2)]
DistanceKm = Annotated[Decimal, Field(ge=0, max_digits=8, decimal_places=2)]
Hours = Annotated[Decimal, Field(gt=0, le=24, max_digits=5, decimal_places=2)]
OrderCount = Annotated[int, Field(ge=0, le=10_000)]
# Keeps date arithmetic (weeks, months) far away from date.min / date.max.
RecordDate = Annotated[date, Field(ge=date(2000, 1, 1), le=date(2100, 12, 31))]
Notes = Annotated[str, StringConstraints(strip_whitespace=True, max_length=NOTES_MAX_LENGTH)]
SourceLabel = Annotated[str, StringConstraints(strip_whitespace=True, max_length=SOURCE_LABEL_MAX_LENGTH)]
ExpenseCategory = Literal["fuel", "maintenance", "depreciation", "other"]

# ---- work sessions ----


class WorkSessionCreate(StrictModel):
    started_at: AwareDatetime
    ended_at: AwareDatetime
    distance_km: DistanceKm | None = None
    order_count: OrderCount | None = None
    notes: Notes | None = None


class WorkSessionUpdate(PatchModel):
    non_nullable: ClassVar[frozenset[str]] = frozenset({"started_at", "ended_at"})

    started_at: AwareDatetime | None = None
    ended_at: AwareDatetime | None = None
    distance_km: DistanceKm | None = None
    order_count: OrderCount | None = None
    notes: Notes | None = None


class WorkSessionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    started_at: datetime
    ended_at: datetime
    distance_km: Decimal | None
    order_count: int | None
    notes: str | None
    is_demo: bool
    created_at: datetime
    updated_at: datetime


# ---- income ----


class IncomeCreate(StrictModel):
    occurred_on: RecordDate
    amount: Money
    work_session_id: uuid.UUID | None = None
    order_count: OrderCount | None = None
    distance_km: DistanceKm | None = None
    working_hours: Hours | None = Field(
        default=None, description="Counted only while the record is not linked to a work session"
    )
    source_label: SourceLabel | None = Field(default=None, description="Free text, e.g. the platform name")
    notes: Notes | None = None


class IncomeUpdate(PatchModel):
    non_nullable: ClassVar[frozenset[str]] = frozenset({"occurred_on", "amount"})

    occurred_on: RecordDate | None = None
    amount: Money | None = None
    work_session_id: uuid.UUID | None = None
    order_count: OrderCount | None = None
    distance_km: DistanceKm | None = None
    working_hours: Hours | None = None
    source_label: SourceLabel | None = None
    notes: Notes | None = None


class IncomeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    occurred_on: date
    amount: Decimal
    work_session_id: uuid.UUID | None
    order_count: int | None
    distance_km: Decimal | None
    working_hours: Decimal | None
    source_label: str | None
    notes: str | None
    is_demo: bool
    created_at: datetime
    updated_at: datetime


# ---- expenses ----


class ExpenseCreate(StrictModel):
    occurred_on: RecordDate
    category: ExpenseCategory
    amount: Money
    work_session_id: uuid.UUID | None = None
    description: Notes | None = None


class ExpenseUpdate(PatchModel):
    non_nullable: ClassVar[frozenset[str]] = frozenset({"occurred_on", "category", "amount"})

    occurred_on: RecordDate | None = None
    category: ExpenseCategory | None = None
    amount: Money | None = None
    work_session_id: uuid.UUID | None = None
    description: Notes | None = None


class ExpenseOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    occurred_on: date
    category: ExpenseCategory
    amount: Decimal
    work_session_id: uuid.UUID | None
    description: str | None
    is_demo: bool
    created_at: datetime
    updated_at: datetime


# ---- summaries / trends ----

Period = Literal["day", "week", "month"]
NoDataReason = Literal["no_working_hours"]


class ProfitMetrics(BaseModel):
    """Actual figures only (shift-scenario estimates are never mixed in). Money is a decimal string."""

    total_revenue: Decimal
    total_expenses: Decimal
    net_profit: Decimal
    working_hours: Decimal
    revenue_per_hour: Decimal | None = Field(description="null when working_hours is 0")
    net_profit_per_hour: Decimal | None = Field(description="null when working_hours is 0")
    reason: NoDataReason | None = Field(description="Why the per-hour values are null")
    income_count: int
    expense_count: int
    work_session_count: int


class ProfitSummary(ProfitMetrics):
    period: Period
    start_date: date
    end_date: date = Field(description="Inclusive")
    timezone: str
    currency: str


class TrendPoint(ProfitMetrics):
    start_date: date
    end_date: date = Field(description="Inclusive")
    net_profit_moving_average: Decimal | None = Field(
        description="Trailing mean of net_profit over analysis.moving_average_window buckets; "
        "null outside the span with records or before the window is full"
    )
    net_profit_trend: Decimal | None = Field(
        description="Fitted linear-trend value; null unless analysis.direction is up or down"
    )


TrendDirection = Literal["up", "down", "flat"]


class TrendAnalysisOut(BaseModel):
    """Estimate from the rider's own records, not a forecast. See app/modules/profit/trend_analysis.py."""

    status: Literal["ok", "insufficient_data"]
    moving_average_window: int = Field(description="Buckets: day 7, week 4, month 3")
    active_buckets: int = Field(description="Buckets that hold at least one record")
    min_active_buckets: int
    direction: TrendDirection | None = Field(
        description="up/down only when the slope is significant (p < 0.05); flat otherwise; null without data"
    )
    slope_per_bucket: Decimal | None = Field(description="Net profit change per bucket (least squares)")
    p_value: float | None


class ProfitTrends(BaseModel):
    granularity: Period
    start_date: date
    end_date: date = Field(description="Inclusive")
    timezone: str
    currency: str
    points: list[TrendPoint]
    analysis: TrendAnalysisOut


# ---- work patterns (K-Means) ----

PatternStatus = Literal["ok", "insufficient_data", "no_clear_pattern"]


class PatternGroup(BaseModel):
    """One group of similar sessions. Labels are codes; the app turns them into words."""

    time_of_day: Literal["morning", "midday", "evening", "night"] = Field(
        description="Of the mean local start: morning 05-11, midday 11-15, evening 15-20, night 20-05"
    )
    length: Literal["short", "medium", "long"] = Field(description="Mean length: short < 4 h, medium < 8 h")
    day_type: Literal["weekday", "weekend", "mixed"] = Field(
        description="weekend when >= 70% of the sessions start on Sat/Sun, weekday when <= 30%"
    )
    mean_start_minute: int = Field(ge=0, lt=1440, description="Circular mean of the local start time")
    mean_hours: Decimal
    weekend_share: float
    session_count: int
    share: float = Field(description="session_count / all sessions in the window")
    profit_session_count: int = Field(
        description="Sessions with linked income; the per-hour figures use only these"
    )
    revenue_per_hour: Decimal | None = Field(description="Estimate; null when no session has linked income")
    net_profit_per_hour: Decimal | None = Field(
        description="Estimate: (linked income - linked expenses) / hours of those sessions"
    )


class WorkPatterns(BaseModel):
    status: PatternStatus
    window_days: int
    start_date: date
    end_date: date = Field(description="Inclusive")
    session_count: int = Field(description="Sessions in the window")
    min_sessions: int = Field(description="Sessions needed before patterns are computed")
    k: int | None
    silhouette: float | None = Field(description="Separation of the chosen grouping (-1..1)")
    null_silhouette: float | None = Field(description="Best silhouette on shuffled data; must be beaten")
    stability: float | None = Field(description="Mean adjusted Rand index over bootstrap refits (0..1)")
    groups: list[PatternGroup] = Field(description="Largest first; empty unless status is ok")
    timezone: str
    currency: str


# ---- profit heat map ----


class HeatmapCell(BaseModel):
    """One weekday × 2-hour slot, local time. Estimate: see app/modules/profit/heatmap.py."""

    weekday: int = Field(ge=0, le=6, description="0 = Monday")
    slot: int = Field(ge=0, lt=12, description="Starts at slot × 2:00 local time")
    hours: Decimal = Field(description="Counted hours that fall in this cell (0.1 h)")
    session_count: int = Field(description="Counted sessions with at least one minute in this cell")
    revenue_per_hour: Decimal | None = Field(description="null below min_cell_sessions / min_cell_hours")
    net_profit_per_hour: Decimal | None = Field(description="null below min_cell_sessions / min_cell_hours")


class ProfitHeatmap(BaseModel):
    status: Literal["ok", "insufficient_data"]
    window_days: int
    start_date: date
    end_date: date = Field(description="Inclusive")
    slot_hours: int
    session_count: int = Field(description="Counted sessions: those with linked or same-day unlinked income")
    min_sessions: int = Field(description="Counted sessions needed before cells are returned")
    min_cell_sessions: int
    min_cell_hours: int
    excluded_session_count: int = Field(description="Sessions in the window without any income")
    excluded_income_count: int = Field(
        description="Unlinked income not placed: on a day without counted sessions, or with own working_hours"
    )
    excluded_expense_count: int = Field(description="Unlinked expenses on a day without counted sessions")
    hours: Decimal = Field(description="Hours of the counted sessions")
    revenue_per_hour: Decimal | None = Field(description="Over all counted sessions; null without any")
    net_profit_per_hour: Decimal | None = Field(description="Over all counted sessions; null without any")
    cells: list[HeatmapCell] = Field(
        description="Cells with any counted time, by weekday then slot; empty unless status is ok"
    )
    timezone: str
    currency: str
