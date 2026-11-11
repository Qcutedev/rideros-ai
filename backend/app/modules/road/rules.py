"""RoadContext rules: categories, statuses, duplicate radius / window and TTL (DATABASE_DESIGN.md §4).

The per-category numbers are starting values that have not been validated against real reports.
They live in settings (`ROAD_RULES`, JSON) so they can be tuned without code changes.
"""

from datetime import timedelta
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

Category = Literal["flooding", "road_damage", "road_closure", "road_obstacle", "traffic_incident"]
CATEGORIES: tuple[Category, ...] = (
    "flooding",
    "road_damage",
    "road_closure",
    "road_obstacle",
    "traffic_incident",
)

IncidentStatus = Literal["unverified", "corroborated", "resolved", "expired", "rejected"]
INCIDENT_STATUSES: tuple[IncidentStatus, ...] = (
    "unverified",
    "corroborated",
    "resolved",
    "expired",
    "rejected",
)
# Shown on the map and open to new reports / confirmations (while `expires_at` is in the future).
ACTIVE_STATUSES: tuple[IncidentStatus, ...] = ("unverified", "corroborated")

ReportType = Literal["report", "still_present", "cleared"]
REPORT_TYPES: tuple[ReportType, ...] = ("report", "still_present", "cleared")

AiStatus = Literal["none", "pending", "done", "failed"]
AI_STATUSES: tuple[AiStatus, ...] = ("none", "pending", "done", "failed")

DESCRIPTION_MAX_LENGTH = 500
MAX_NEARBY_RADIUS_M = 5000


class RoadRule(BaseModel):
    """How one category groups reports into an incident and how long the incident stays open."""

    model_config = ConfigDict(frozen=True, extra="forbid")

    radius_m: int = Field(gt=0, le=MAX_NEARBY_RADIUS_M, description="Reports closer than this merge")
    window_minutes: int = Field(gt=0, description="...and at most this long after the last report")
    ttl_minutes: int = Field(gt=0, description="The incident expires this long after the last report")

    @property
    def window(self) -> timedelta:
        return timedelta(minutes=self.window_minutes)

    @property
    def ttl(self) -> timedelta:
        return timedelta(minutes=self.ttl_minutes)


_HOUR = 60
_DAY = 24 * _HOUR


def default_road_rules() -> dict[Category, RoadRule]:
    return {
        "flooding": RoadRule(radius_m=300, window_minutes=6 * _HOUR, ttl_minutes=12 * _HOUR),
        "road_damage": RoadRule(radius_m=50, window_minutes=30 * _DAY, ttl_minutes=90 * _DAY),
        "road_closure": RoadRule(radius_m=200, window_minutes=12 * _HOUR, ttl_minutes=24 * _HOUR),
        "road_obstacle": RoadRule(radius_m=100, window_minutes=3 * _HOUR, ttl_minutes=6 * _HOUR),
        "traffic_incident": RoadRule(radius_m=200, window_minutes=2 * _HOUR, ttl_minutes=3 * _HOUR),
    }


def sql_in(values: tuple[str, ...]) -> str:
    """`'a', 'b'` for CHECK constraints built from the tuples above."""
    return ", ".join(f"'{v}'" for v in values)
