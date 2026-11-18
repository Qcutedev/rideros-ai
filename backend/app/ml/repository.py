"""Data access for `model_versions`."""

import uuid
from typing import Any

from sqlalchemy import update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.ml.models import ModelVersion


async def activate_model_version(session: AsyncSession, values: dict[str, Any]) -> uuid.UUID:
    """Upsert (name, version) and make it the only active version of `name`."""
    await session.execute(
        update(ModelVersion)
        .where(ModelVersion.name == values["name"], ModelVersion.version != values["version"])
        .values(is_active=False)
    )
    stmt = (
        insert(ModelVersion)
        .values(**values, is_active=True)
        .on_conflict_do_update(
            index_elements=[ModelVersion.name, ModelVersion.version],
            set_={k: v for k, v in values.items() if k not in ("name", "version")} | {"is_active": True},
        )
        .returning(ModelVersion.id)
    )
    return (await session.execute(stmt)).scalar_one()
