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


def test_road_rules_default_to_the_design_table() -> None:
    rules = make().road_rules
    assert set(rules) == {"flooding", "road_damage", "road_closure", "road_obstacle", "traffic_incident"}
    assert (rules["flooding"].radius_m, rules["flooding"].window_minutes, rules["flooding"].ttl_minutes) == (
        300,
        360,
        720,
    )


def test_partial_road_rules_override_only_named_categories(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv(
        "ROAD_RULES", '{"flooding": {"radius_m": 500, "window_minutes": 60, "ttl_minutes": 120}}'
    )
    rules = make().road_rules
    assert rules["flooding"].radius_m == 500
    assert rules["road_damage"].radius_m == 50


def test_bad_road_rules_are_rejected() -> None:
    with pytest.raises(ValidationError):
        make(road_rules={"flooding": {"radius_m": 0, "window_minutes": 1, "ttl_minutes": 1}})
    with pytest.raises(ValidationError):
        make(road_rules={"volcano": {"radius_m": 10, "window_minutes": 1, "ttl_minutes": 1}})


def test_empty_road_image_dir_means_disabled() -> None:
    assert make(road_image_dir="").road_image_dir is None
