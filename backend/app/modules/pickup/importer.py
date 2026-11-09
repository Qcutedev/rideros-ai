"""Import ml/artifacts/restaurant_stats/<version>/ into `restaurants` + `restaurant_time_stats`.

Only the exported aggregates are imported, never raw dataset rows (docs/DATABASE_DESIGN.md §3.10).
Idempotent: dataset restaurants are upserted by (source, external_ref) and their time stats replaced,
all in one transaction.
"""

import csv
import json
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any

from sqlalchemy import delete, func, select, text
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.pickup.models import DATA_AVAILABILITY, Restaurant, RestaurantTimeStat

SOURCE = "dataset_meituan"
_REFERENCE_COLUMNS = {
    "poi_id",
    "n_orders",
    "median_min",
    "p25_min",
    "p75_min",
    "p90_min",
    "reference_da_id",
    "peak_hour",
    "data_availability",
}
_TIME_COLUMNS = {"poi_id", "day_type", "hour", "n_orders", "median_min", "p25_min", "p75_min", "p90_min"}
_BATCH = 2000


class ImportFormatError(ValueError):
    pass


@dataclass(frozen=True, slots=True)
class ImportResult:
    dataset_version: str
    restaurants: int
    time_cells: int
    skipped: bool = False


def _rows(path: Path, required: set[str]) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        missing = required - set(reader.fieldnames or [])
        if missing:
            raise ImportFormatError(f"{path.name}: missing columns {sorted(missing)}")
        return list(reader)


def _dec(value: str, field: str) -> Decimal | None:
    if value == "":
        return None
    try:
        return Decimal(value)
    except InvalidOperation as exc:
        raise ImportFormatError(f"{field}: not a number: {value!r}") from exc


def _int(value: str, field: str) -> int | None:
    if value == "":
        return None
    try:
        return int(float(value))
    except ValueError as exc:
        raise ImportFormatError(f"{field}: not an integer: {value!r}") from exc


def _restaurant_values(row: dict[str, str], dataset_version: str) -> dict[str, Any]:
    if row["data_availability"] not in DATA_AVAILABILITY:
        raise ImportFormatError(f"poi {row['poi_id']}: data_availability {row['data_availability']!r}")
    return {
        "source": SOURCE,
        "external_ref": row["poi_id"],
        "name": f"POI-{row['poi_id']}",  # the dataset has no real names
        "reference_da_id": row["reference_da_id"] or None,
        "n_orders": _int(row["n_orders"], "n_orders"),
        "median_min": _dec(row["median_min"], "median_min"),
        "p25_min": _dec(row["p25_min"], "p25_min"),
        "p75_min": _dec(row["p75_min"], "p75_min"),
        "p90_min": _dec(row["p90_min"], "p90_min"),
        "peak_hour": _int(row["peak_hour"], "peak_hour"),
        "data_availability": row["data_availability"],
        "dataset_version": dataset_version,
    }


async def dataset_restaurant_count(session: AsyncSession) -> int:
    return (
        await session.scalar(select(func.count()).select_from(Restaurant).where(Restaurant.source == SOURCE))
        or 0
    )


async def import_restaurant_stats(
    session: AsyncSession, folder: Path, *, if_empty: bool = False
) -> ImportResult:
    summary = json.loads((folder / "summary.json").read_text(encoding="utf-8"))
    source_sha = str(summary.get("source_orders_parquet_sha256", ""))[:12]
    dataset_version = f"restaurant_stats/{folder.name}" + (f" (orders {source_sha})" if source_sha else "")
    if if_empty and await dataset_restaurant_count(session) > 0:
        return ImportResult(dataset_version, 0, 0, skipped=True)

    reference = [
        _restaurant_values(r, dataset_version)
        for r in _rows(folder / "restaurant_reference.csv", _REFERENCE_COLUMNS)
    ]
    cells = _rows(folder / "restaurant_time_stats.csv", _TIME_COLUMNS)
    if summary.get("n_restaurants") not in (None, len(reference)) or summary.get("n_time_cells") not in (
        None,
        len(cells),
    ):
        raise ImportFormatError("row counts do not match summary.json")

    ids: dict[str, Any] = {}
    for start in range(0, len(reference), _BATCH):
        chunk = reference[start : start + _BATCH]
        stmt = insert(Restaurant).values(chunk)
        stmt = stmt.on_conflict_do_update(
            index_elements=[Restaurant.source, Restaurant.external_ref],
            index_where=text("external_ref IS NOT NULL"),
            set_={k: stmt.excluded[k] for k in chunk[0] if k not in ("source", "external_ref")}
            | {"updated_at": func.now()},
        ).returning(Restaurant.external_ref, Restaurant.id)
        ids.update({ref: rid for ref, rid in await session.execute(stmt)})

    await session.execute(
        delete(RestaurantTimeStat).where(RestaurantTimeStat.restaurant_id.in_(list(ids.values())))
    )
    stat_rows = []
    for row in cells:
        if row["poi_id"] not in ids:
            raise ImportFormatError(f"time stats for unknown poi {row['poi_id']}")
        if row["day_type"] not in ("weekday", "weekend"):
            raise ImportFormatError(f"day_type {row['day_type']!r}")
        stat_rows.append(
            {
                "restaurant_id": ids[row["poi_id"]],
                "day_type": row["day_type"],
                "hour": _int(row["hour"], "hour"),
                "n_orders": _int(row["n_orders"], "n_orders"),
                "median_min": _dec(row["median_min"], "median_min"),
                "p25_min": _dec(row["p25_min"], "p25_min"),
                "p75_min": _dec(row["p75_min"], "p75_min"),
                "p90_min": _dec(row["p90_min"], "p90_min"),
                "dataset_version": dataset_version,
            }
        )
    for start in range(0, len(stat_rows), _BATCH):
        await session.execute(insert(RestaurantTimeStat).values(stat_rows[start : start + _BATCH]))
    await session.commit()
    return ImportResult(dataset_version, len(reference), len(stat_rows))
