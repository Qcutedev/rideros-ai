"""Moving average + linear trend of net profit for `GET /profit/trends` (docs/PROJECT_PLAN.md §3). Pure.

Input: the net profit of every bucket in order (empty buckets are 0) and whether the bucket holds
any record (income, expense or work session).

Span: from the first to the last bucket that holds a record. Empty buckets inside it count as 0 (a
day off earns nothing). Buckets before the first record (the app was not used yet) and after the
last one (usually today, not recorded yet) are left out, so they cannot drag the numbers down.

Moving average: trailing mean of net profit over WINDOWS[granularity] buckets, only where the whole
window lies inside the span.

Linear trend: ordinary least squares of net profit on the bucket index over the span. It needs at
least MIN_ACTIVE_BUCKETS buckets with records; with fewer the status is "insufficient_data". The
direction is "up"/"down" only when the slope differs from zero at P_VALUE_MAX (two-sided t-test of
the slope); otherwise it is "flat" and no line is returned, because a non-significant slope drawn
as a line reads like a real trend.
"""

import math
from dataclasses import dataclass
from decimal import ROUND_HALF_UP, Decimal
from typing import Literal

from scipy import stats

Granularity = Literal["day", "week", "month"]
Direction = Literal["up", "down", "flat"]
Status = Literal["ok", "insufficient_data"]

WINDOWS: dict[Granularity, int] = {"day": 7, "week": 4, "month": 3}
MIN_ACTIVE_BUCKETS = 4
P_VALUE_MAX = 0.05
_CENT = Decimal("0.01")


@dataclass(frozen=True)
class TrendAnalysis:
    status: Status
    moving_average_window: int
    active_buckets: int
    min_active_buckets: int
    direction: Direction | None
    slope_per_bucket: Decimal | None
    p_value: float | None
    moving_average: list[Decimal | None]
    trend_line: list[Decimal | None]


def _round(value: Decimal) -> Decimal:
    return value.quantize(_CENT, rounding=ROUND_HALF_UP)


def analyse(net_profit: list[Decimal], has_records: list[bool], granularity: Granularity) -> TrendAnalysis:
    if len(net_profit) != len(has_records):
        raise ValueError("net_profit and has_records must have the same length")
    n = len(net_profit)
    window = WINDOWS[granularity]
    active = [i for i, flag in enumerate(has_records) if flag]
    moving: list[Decimal | None] = [None] * n
    line: list[Decimal | None] = [None] * n
    if not active:
        return TrendAnalysis(
            "insufficient_data", window, 0, MIN_ACTIVE_BUCKETS, None, None, None, moving, line
        )

    first, last = active[0], active[-1]
    for i in range(first + window - 1, last + 1):
        moving[i] = _round(sum(net_profit[i - window + 1 : i + 1], Decimal(0)) / window)

    if len(active) < MIN_ACTIVE_BUCKETS:
        return TrendAnalysis(
            "insufficient_data", window, len(active), MIN_ACTIVE_BUCKETS, None, None, None, moving, line
        )

    xs = list(range(first, last + 1))
    ys = [float(net_profit[i]) for i in xs]
    fit = stats.linregress(xs, ys)
    slope, intercept, p_value = float(fit.slope), float(fit.intercept), float(fit.pvalue)
    if math.isnan(p_value):  # every value equal: no spread to test, and no trend
        p_value = 1.0
    if p_value < P_VALUE_MAX and slope != 0:
        direction: Direction = "up" if slope > 0 else "down"
        for i in xs:
            line[i] = _round(Decimal(repr(intercept + slope * i)))
    else:
        direction = "flat"
    return TrendAnalysis(
        "ok",
        window,
        len(active),
        MIN_ACTIVE_BUCKETS,
        direction,
        _round(Decimal(repr(slope))),
        round(p_value, 4),
        moving,
        line,
    )
