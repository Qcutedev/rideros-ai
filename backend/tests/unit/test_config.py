import secrets

import pytest
from pydantic import ValidationError

from app.core.config import Settings

DB = "postgresql+asyncpg://x@localhost/x_test"
# Generated per run so no secret-looking literal lives in the repo (gitleaks). Hex digits cannot
# spell any placeholder marker ("secret", "example", ...), so the production guard never trips on it.
GOOD_SECRET = "k" + secrets.token_hex(24)


def make(**kw: object) -> Settings:
    values = {"database_url": DB, "jwt_secret": GOOD_SECRET, **kw}
    return Settings(_env_file=None, **values)  # type: ignore[arg-type]


def test_short_jwt_secret_is_rejected() -> None:
    with pytest.raises(ValidationError, match="at least 32"):
        make(jwt_secret="too-short")


def test_missing_required_values_fail(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.delenv("JWT_SECRET", raising=False)
    with pytest.raises(ValidationError):
        Settings(_env_file=None)  # type: ignore[call-arg]


def test_production_rejects_placeholder_secret() -> None:
    with pytest.raises(ValidationError, match="placeholder"):
        make(env="production", jwt_secret="CHANGE-ME-to-a-random-string-of-at-least-32-chars")


def test_production_rejects_db_echo() -> None:
    with pytest.raises(ValidationError, match="DB_ECHO"):
        make(env="production", db_echo=True)


@pytest.mark.parametrize(("env", "enabled"), [("development", True), ("test", True), ("production", False)])
def test_password_reset_enabled_only_outside_production_without_provider(env: str, enabled: bool) -> None:
    assert make(env=env).password_reset_enabled is enabled


@pytest.mark.parametrize(
    ("env", "override", "shown"),
    [("development", None, True), ("production", None, False), ("production", True, True)],
)
def test_docs_visibility(env: str, override: bool | None, shown: bool) -> None:
    assert make(env=env, docs_enabled=override).show_docs is shown
