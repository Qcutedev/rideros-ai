from collections.abc import AsyncIterator

import pytest
from fastapi import FastAPI
from sqlalchemy import text

from app.db.models import Base


@pytest.fixture(autouse=True)
async def _clean_tables(app: FastAPI) -> AsyncIterator[None]:
    yield
    names = ", ".join(f'"{t.name}"' for t in Base.metadata.sorted_tables)
    async with app.state.engine.begin() as conn:
        await conn.execute(text(f"TRUNCATE {names} CASCADE"))
