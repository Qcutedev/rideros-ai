from collections.abc import AsyncIterator

import pytest
from fastapi import FastAPI
from sqlalchemy import text

from app.db.models import Base


@pytest.fixture(autouse=True)
async def _clean_tables(app: FastAPI) -> AsyncIterator[None]:
    yield
    # model_versions holds the row written at startup (the app keeps its id), so it is not truncated.
    names = ", ".join(f'"{t.name}"' for t in Base.metadata.sorted_tables if t.name != "model_versions")
    async with app.state.engine.begin() as conn:
        await conn.execute(text(f"TRUNCATE {names} CASCADE"))
