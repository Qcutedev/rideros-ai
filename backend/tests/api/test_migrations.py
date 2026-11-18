"""Migrations match the ORM models and can be rolled back and re-applied."""

import asyncio

import pytest
from alembic import command
from alembic.autogenerate import compare_metadata
from alembic.migration import MigrationContext
from fastapi import FastAPI
from sqlalchemy import make_url, text
from sqlalchemy.ext.asyncio import create_async_engine

from app.db.models import Base
from tests.conftest import _drop_database, _recreate_database, alembic_config


def _include_name(name: str | None, type_: str, _parents: dict) -> bool:
    return name in Base.metadata.tables if type_ == "table" else True


async def test_models_and_migrations_have_no_drift(app: FastAPI) -> None:
    def _diff(sync_conn):
        ctx = MigrationContext.configure(
            sync_conn, opts={"compare_type": True, "include_name": _include_name}
        )
        return compare_metadata(ctx, Base.metadata)

    async with app.state.engine.connect() as conn:
        diff = await conn.run_sync(_diff)
    assert diff == [], f"ORM models and Alembic migrations differ: {diff}"


async def test_check_constraints_exist(app: FastAPI) -> None:
    async with app.state.engine.connect() as conn:
        rows = await conn.execute(
            text("SELECT conname FROM pg_constraint WHERE conrelid = 'users'::regclass AND contype = 'c'")
        )
        names = {r[0] for r in rows}
    assert {"ck_users_role", "ck_users_display_name_length", "ck_users_email_lowercase"} <= names


async def test_work_session_overlap_is_enforced_by_an_exclusion_constraint(app: FastAPI) -> None:
    async with app.state.engine.connect() as conn:
        kind = await conn.scalar(
            text("SELECT contype::text FROM pg_constraint WHERE conname = 'ex_work_sessions_no_overlap'")
        )
        ext = await conn.scalar(text("SELECT count(*) FROM pg_extension WHERE extname = 'btree_gist'"))
    assert kind == "x" and ext == 1


@pytest.fixture
def scratch_db_url(database_url: str):
    url = make_url(database_url)
    scratch = url.set(database=f"{url.database}_migrations_test").render_as_string(hide_password=False)
    asyncio.run(_recreate_database(scratch))
    yield scratch
    asyncio.run(_drop_database(scratch))


def test_downgrade_to_base_and_upgrade_again(scratch_db_url: str) -> None:
    cfg = alembic_config(scratch_db_url)
    command.upgrade(cfg, "head")
    command.downgrade(cfg, "base")

    async def _tables() -> set[str]:
        engine = create_async_engine(scratch_db_url)
        async with engine.connect() as conn:
            rows = await conn.execute(text("SELECT tablename FROM pg_tables WHERE schemaname = 'public'"))
            names = {r[0] for r in rows}
        await engine.dispose()
        return names

    assert not (set(Base.metadata.tables) & asyncio.run(_tables()))
    command.upgrade(cfg, "head")
    assert set(Base.metadata.tables) <= asyncio.run(_tables())


PICKUP_TABLES = {"restaurants", "restaurant_time_stats", "pickup_logs", "pickup_predictions"}


async def _run(url: str, sql: str) -> list[tuple]:
    engine = create_async_engine(url)
    async with engine.begin() as conn:
        result = await conn.execute(text(sql))
        rows = [tuple(r) for r in result] if result.returns_rows else []
    await engine.dispose()
    return rows


async def test_pickup_tables_are_gone(app: FastAPI) -> None:
    async with app.state.engine.connect() as conn:
        rows = await conn.execute(text("SELECT tablename FROM pg_tables WHERE schemaname = 'public'"))
        names = {r[0] for r in rows}
    assert not PICKUP_TABLES & names
    assert "model_versions" in names  # RoadContext keeps using it


def test_0006_removes_only_the_pickup_model_rows(scratch_db_url: str) -> None:
    cfg = alembic_config(scratch_db_url)
    command.upgrade(cfg, "0005")
    for name in ("pickup_o2p", "road_cv"):
        asyncio.run(
            _run(
                scratch_db_url,
                "INSERT INTO model_versions "
                "(name, version, task, dataset, metrics, feature_schema, artifact_uri) "
                f"VALUES ('{name}', '1.0.0', 't', 'd', '{{}}'::jsonb, '{{}}'::jsonb, 'u')",
            )
        )
    command.upgrade(cfg, "head")
    assert asyncio.run(_run(scratch_db_url, "SELECT name FROM model_versions")) == [("road_cv",)]
