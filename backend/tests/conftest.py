"""Test fixtures. Tests run against a real PostGIS server (the docker compose `db` service).

A throw-away database (TEST_DATABASE_URL, name must end in `_test`) is dropped and re-created
per session and migrated with Alembic, so every run also exercises the migrations.
"""

import asyncio
import os
import secrets
from collections.abc import AsyncIterator, Iterator
from pathlib import Path

import asyncpg
import httpx
import pytest
from alembic import command
from alembic.config import Config
from dotenv import load_dotenv
from fastapi import FastAPI
from sqlalchemy import make_url
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.main import create_app
from tests import fake_artifact

BACKEND_DIR = Path(__file__).resolve().parents[1]
load_dotenv(BACKEND_DIR.parent / ".env", override=False)


def _test_db_url() -> str:
    url = os.environ.get("TEST_DATABASE_URL")
    if not url:
        pytest.exit("TEST_DATABASE_URL is not set (see .env.example); start the db with docker compose", 2)
    name = make_url(url).database or ""
    if not name.endswith("_test"):
        pytest.exit(
            f"Refusing to use database {name!r}: TEST_DATABASE_URL must point at a *_test database", 2
        )
    return url


async def _admin_execute(url: str, *statements: str) -> None:
    parsed = make_url(url)
    if not (parsed.database or "").endswith("_test"):
        raise RuntimeError(f"Refusing to drop/create non-test database {parsed.database!r}")
    conn = await asyncpg.connect(
        user=parsed.username,
        password=parsed.password,
        host=parsed.host,
        port=parsed.port or 5432,
        database="postgres",
    )
    try:
        for statement in statements:
            await conn.execute(statement.format(db=parsed.database))
    finally:
        await conn.close()


async def _recreate_database(url: str) -> None:
    await _admin_execute(url, 'DROP DATABASE IF EXISTS "{db}" WITH (FORCE)', 'CREATE DATABASE "{db}"')


async def _drop_database(url: str) -> None:
    await _admin_execute(url, 'DROP DATABASE IF EXISTS "{db}" WITH (FORCE)')


def alembic_config(url: str) -> Config:
    cfg = Config(str(BACKEND_DIR / "alembic.ini"))
    cfg.set_main_option("script_location", str(BACKEND_DIR / "alembic"))
    cfg.set_main_option("sqlalchemy.url", url.replace("%", "%%"))
    cfg.attributes["configure_logger"] = False
    return cfg


@pytest.fixture(scope="session")
def database_url() -> Iterator[str]:
    url = _test_db_url()
    asyncio.run(_recreate_database(url))
    command.upgrade(alembic_config(url), "head")
    yield url
    asyncio.run(_drop_database(url))


def make_settings(database_url: str, **overrides: object) -> Settings:
    values: dict[str, object] = {
        "env": "test",
        "database_url": database_url,
        "jwt_secret": secrets.token_urlsafe(48),
        "log_level": "WARNING",
        "rate_limit_enabled": False,  # tests/api/test_rate_limits.py turns it on for its own app
    }
    values.update(overrides)
    return Settings(_env_file=None, **values)  # type: ignore[arg-type]


@pytest.fixture(scope="session")
def model_dir(tmp_path_factory: pytest.TempPathFactory) -> Path:
    root = tmp_path_factory.mktemp("artifacts")
    fake_artifact.build(root)
    return root


@pytest.fixture(scope="session")
def road_image_dir(tmp_path_factory: pytest.TempPathFactory) -> Path:
    return tmp_path_factory.mktemp("road_images")


@pytest.fixture(scope="session")
def settings(database_url: str, model_dir: Path, road_image_dir: Path) -> Settings:
    return make_settings(
        database_url,
        model_dir=model_dir,
        road_image_dir=road_image_dir,
        active_model_name=fake_artifact.NAME,
        active_model_version=fake_artifact.VERSION,
    )


@pytest.fixture(scope="session")
async def app(settings: Settings) -> AsyncIterator[FastAPI]:
    application = create_app(settings)
    async with application.router.lifespan_context(application):
        yield application


@pytest.fixture
async def client(app: FastAPI) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
    async with httpx.AsyncClient(transport=transport, base_url="http://test/api/v1") as c:
        yield c


@pytest.fixture
async def db(app: FastAPI) -> AsyncIterator[AsyncSession]:
    factory: async_sessionmaker[AsyncSession] = app.state.session_factory
    async with factory() as session:
        yield session
