"""K-Means work patterns (docs/SYSTEM_ARCHITECTURE.md §4, `GET /profit/patterns`). Pure: no I/O.

Groups a rider's work sessions by *when* and *how long* they work. Profit is deliberately not a
clustering feature: many income records are not linked to a session, so it would be missing for
most rows. Profit per hour is computed afterwards per group, from linked records only.

Features (one row per session, local time of `started_at`; a session past midnight counts on the
hour and day it started, like docs/DATABASE_DESIGN.md §3.7):
  * start hour as a point on the 24 h circle (sin, cos), so 23:00 and 01:00 are close;
  * length in hours;
  * weekend flag (Saturday/Sunday).
Scaling: length is standardised to unit variance; sin and cos share one scale so the circle stays
round and the start hour together weighs as much as one feature. The weekend flag gets half that
weight: at full weight a binary column dominates the distances, and one real habit with a few
weekend sessions was split into a weekday and a weekend group (benchmark: right k 35% vs 95%).

Model selection: k = 2..4, `n_init=10`, fixed seeds; the k with the best silhouette wins. Groups are
only shown when all three checks pass (every group must also hold at least 3 sessions):
  1. separated: silhouette >= 0.25;
  2. real, not an artefact of the feature shapes: the silhouette beats every one of 39 null data
     sets in which each feature is shuffled on its own (permutation test, p <= 0.025; 19 sets /
     p <= 0.05 let 13% of uniform random riders through in the benchmark). Without this test,
     random sessions still "cluster" because the binary weekend flag always splits them;
  3. reproducible: models refit on bootstrap resamples label the full data like the reference
     (mean adjusted Rand index >= 0.6).
"""

import math
from dataclasses import dataclass, replace
from datetime import datetime, timedelta
from decimal import ROUND_HALF_UP, Decimal
from functools import lru_cache
from typing import Literal
from zoneinfo import ZoneInfo

import numpy as np
from sklearn.cluster import KMeans
from sklearn.metrics import adjusted_rand_score, silhouette_score

MIN_SESSIONS = 30
WINDOW_DAYS = 180
K_RANGE = range(2, 5)
MIN_SILHOUETTE = 0.25
MIN_STABILITY = 0.6
MIN_GROUP_SIZE = 3
BOOTSTRAP_ROUNDS = 20
NULL_ROUNDS = 39  # p = 1 / (39 + 1) = 0.025 when the data beats every null set
SEED = 0
WEEKEND_WEIGHT = 0.5  # chosen on scripts/evaluate_work_patterns.py (1.0 split groups by weekend)
_N_INIT = 10
_NULL_N_INIT = 3  # null sets only need a fair best-silhouette estimate

type TimeOfDay = Literal["morning", "midday", "evening", "night"]
type Length = Literal["short", "medium", "long"]
type DayType = Literal["weekday", "weekend", "mixed"]
type Status = Literal["ok", "insufficient_data", "no_clear_pattern"]

_CENT = Decimal("0.01")
_TENTH = Decimal("0.1")
_MICROSECONDS_PER_HOUR = Decimal(3_600_000_000)


@dataclass(frozen=True, slots=True)
class SessionRow:
    started_at: datetime  # aware
    ended_at: datetime
    revenue: Decimal  # income records linked to this session
    expenses: Decimal  # expense records linked to this session
    income_count: int


@dataclass(frozen=True, slots=True)
class Group:
    time_of_day: TimeOfDay
    length: Length
    day_type: DayType
    mean_start_minute: int  # local, circular mean, 0..1439
    mean_hours: Decimal
    weekend_share: float
    session_count: int
    share: float
    profit_session_count: int  # sessions with linked income, used for the per-hour figures
    revenue_per_hour: Decimal | None
    net_profit_per_hour: Decimal | None


@dataclass(frozen=True, slots=True)
class Result:
    status: Status
    session_count: int
    k: int | None = None
    silhouette: float | None = None
    null_silhouette: float | None = None  # best silhouette among the shuffled null sets
    stability: float | None = None
    groups: tuple[Group, ...] = ()
    labels: tuple[int, ...] = ()  # index into `groups` per input row (ok only); not sent to clients


def _hours(row: SessionRow) -> float:
    return (row.ended_at - row.started_at).total_seconds() / 3600


def features(rows: list[SessionRow], zone: ZoneInfo) -> np.ndarray:
    """Unscaled feature matrix: [sin(hour), cos(hour), length h, weekend 0/1]."""
    out = np.empty((len(rows), 4))
    for i, row in enumerate(rows):
        local = row.started_at.astimezone(zone)
        angle = 2 * math.pi * (local.hour + local.minute / 60) / 24
        out[i] = (math.sin(angle), math.cos(angle), _hours(row), 1.0 if local.weekday() >= 5 else 0.0)
    return out


def scale(x: np.ndarray) -> np.ndarray:
    """See the module docstring. A constant column stays 0 (it carries no information)."""
    centred = x - x.mean(axis=0)
    out = np.zeros_like(centred)
    circle = math.sqrt(centred[:, 0].var() + centred[:, 1].var())
    if circle > 0:
        out[:, :2] = centred[:, :2] / circle
    for col, weight in ((2, 1.0), (3, WEEKEND_WEIGHT)):
        std = centred[:, col].std()
        if std > 0:
            out[:, col] = centred[:, col] / std * weight
    return out


def best_k(x: np.ndarray, n_init: int = _N_INIT, seed: int = SEED) -> tuple[float, int, np.ndarray] | None:
    """(silhouette, k, labels) of the best k, or None when no k gives groups of MIN_GROUP_SIZE."""
    distinct = len(np.unique(x.round(9), axis=0))
    best: tuple[float, int, np.ndarray] | None = None
    for k in K_RANGE:
        if k >= distinct:
            break
        labels = KMeans(n_clusters=k, n_init=n_init, random_state=seed).fit(x).labels_
        if np.bincount(labels, minlength=k).min() < MIN_GROUP_SIZE:
            continue
        score = float(silhouette_score(x, labels))
        if best is None or score > best[0]:
            best = (score, k, labels)
    return best


def null_silhouette(raw: np.ndarray) -> float:
    """Best silhouette over NULL_ROUNDS data sets where each feature is shuffled independently.

    The shuffles keep every feature's own distribution (sin and cos move together, so the start
    hour stays a point on the circle) and only break how the features go together.
    """
    rng = np.random.default_rng(SEED)
    best = -1.0
    for round_ in range(NULL_ROUNDS):
        shuffled = raw.copy()
        shuffled[:, :2] = raw[rng.permutation(len(raw)), :2]
        shuffled[:, 2] = raw[rng.permutation(len(raw)), 2]
        shuffled[:, 3] = raw[rng.permutation(len(raw)), 3]
        found = best_k(scale(shuffled), n_init=_NULL_N_INIT, seed=SEED + round_ + 1)
        if found is not None:
            best = max(best, found[0])
    return best


def stability(x: np.ndarray, k: int, reference: np.ndarray) -> float:
    """Mean ARI between the reference labels and models refit on bootstrap resamples."""
    rng = np.random.default_rng(SEED)
    scores = []
    for round_ in range(BOOTSTRAP_ROUNDS):
        sample = x[rng.integers(0, len(x), len(x))]
        if len(np.unique(sample, axis=0)) < k:
            scores.append(0.0)
            continue
        model = KMeans(n_clusters=k, n_init=_N_INIT, random_state=SEED + round_ + 1).fit(sample)
        scores.append(adjusted_rand_score(reference, model.predict(x)))
    return float(np.mean(scores))


def _time_of_day(minute: int) -> TimeOfDay:
    hour = minute // 60
    if 5 <= hour < 11:
        return "morning"
    if 11 <= hour < 15:
        return "midday"
    if 15 <= hour < 20:
        return "evening"
    return "night"


def _length(hours: float) -> Length:
    if hours < 4:
        return "short"
    return "medium" if hours < 8 else "long"


def _day_type(weekend_share: float) -> DayType:
    if weekend_share >= 0.7:
        return "weekend"
    return "weekday" if weekend_share <= 0.3 else "mixed"


def _per_hour(amount: Decimal, hours: Decimal) -> Decimal:
    return (amount / hours).quantize(_CENT, ROUND_HALF_UP)


def describe(rows: list[SessionRow], raw: np.ndarray) -> Group:
    """Summary of one group. `raw` holds the unscaled features of exactly these rows."""
    angle = math.atan2(raw[:, 0].mean(), raw[:, 1].mean())
    minute = round((angle % (2 * math.pi)) / (2 * math.pi) * 1440) % 1440
    mean_hours = float(raw[:, 2].mean())
    weekend_share = float(raw[:, 3].mean())
    paid = [r for r in rows if r.income_count > 0]
    paid_us = sum((r.ended_at - r.started_at) // timedelta(microseconds=1) for r in paid)
    paid_hours = Decimal(paid_us) / _MICROSECONDS_PER_HOUR
    revenue = sum((r.revenue for r in paid), Decimal(0))
    expenses = sum((r.expenses for r in paid), Decimal(0))
    return Group(
        time_of_day=_time_of_day(minute),
        length=_length(mean_hours),
        day_type=_day_type(weekend_share),
        mean_start_minute=minute,
        mean_hours=Decimal(mean_hours).quantize(_TENTH, ROUND_HALF_UP),
        weekend_share=round(weekend_share, 3),
        session_count=len(rows),
        share=0.0,  # set by the caller, who knows the total
        profit_session_count=len(paid),
        revenue_per_hour=_per_hour(revenue, paid_hours) if paid_hours > 0 else None,
        net_profit_per_hour=_per_hour(revenue - expenses, paid_hours) if paid_hours > 0 else None,
    )


def find_patterns(rows: list[SessionRow], zone: ZoneInfo) -> Result:
    n = len(rows)
    if n < MIN_SESSIONS:
        return Result(status="insufficient_data", session_count=n)
    raw = features(rows, zone)
    x = scale(raw)
    best = best_k(x)
    if best is None:
        return Result(status="no_clear_pattern", session_count=n)
    score, k, labels = best
    checks = {"silhouette": round(score, 3)}
    if score < MIN_SILHOUETTE:
        return Result(status="no_clear_pattern", session_count=n, k=k, **checks)
    null = null_silhouette(raw)
    checks["null_silhouette"] = round(null, 3)
    if score <= null:
        return Result(status="no_clear_pattern", session_count=n, k=k, **checks)
    stable = stability(x, k, labels)
    checks["stability"] = round(stable, 3)
    if stable < MIN_STABILITY:
        return Result(status="no_clear_pattern", session_count=n, k=k, **checks)
    groups = []
    for label in range(k):
        idx = np.flatnonzero(labels == label)
        g = describe([rows[i] for i in idx], raw[idx])
        groups.append(replace(g, share=round(g.session_count / n, 3)))
    order = sorted(range(k), key=lambda i: (-groups[i].session_count, groups[i].mean_start_minute))
    rank = {old: new for new, old in enumerate(order)}
    return Result(
        status="ok",
        session_count=n,
        k=k,
        groups=tuple(groups[i] for i in order),
        labels=tuple(rank[int(label)] for label in labels),
        **checks,
    )


@lru_cache(maxsize=256)
def find_patterns_cached(rows: tuple[SessionRow, ...], zone: ZoneInfo) -> Result:
    """`find_patterns` is deterministic (fixed seeds), so an unchanged session set is not refit."""
    return find_patterns(list(rows), zone)
