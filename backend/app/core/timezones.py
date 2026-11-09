"""IANA time zones (via the `tzdata` package, so Windows hosts and slim images behave the same)."""

from datetime import UTC, date, datetime, time, timedelta
from functools import lru_cache
from zoneinfo import ZoneInfo, available_timezones


@lru_cache
def _known_zones() -> frozenset[str]:
    return frozenset(available_timezones())


def is_valid_timezone(name: str) -> bool:
    return name in _known_zones()


@lru_cache(maxsize=64)
def get_zone(name: str) -> ZoneInfo:
    return ZoneInfo(name)


def today_in(zone: ZoneInfo, now: datetime | None = None) -> date:
    return (now or datetime.now(UTC)).astimezone(zone).date()


def local_dates_to_utc_range(first: date, last: date, zone: ZoneInfo) -> tuple[datetime, datetime]:
    """[local midnight of `first`, local midnight after `last`) as UTC instants (DST-safe)."""
    start = datetime.combine(first, time.min, tzinfo=zone).astimezone(UTC)
    end = datetime.combine(last + timedelta(days=1), time.min, tzinfo=zone).astimezone(UTC)
    return start, end
