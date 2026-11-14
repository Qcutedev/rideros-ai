"""Application settings, read from environment variables (and `.env` in development).

Secrets have no usable defaults: `JWT_SECRET` must be set explicitly, and production refuses
anything that looks like a placeholder.
"""

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field, SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

from app.modules.road.rules import Category, RoadRule, default_road_rules

Environment = Literal["development", "test", "production"]

_PLACEHOLDER_MARKERS = ("change-me", "changeme", "example", "placeholder", "secret")
# Form fields + boundaries on top of the photo itself in a multipart report upload.
MULTIPART_OVERHEAD_BYTES = 64 * 1024


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    env: Environment = "development"
    app_name: str = "RiderOS AI API"
    log_level: str = "INFO"
    log_json: bool = True

    database_url: str = Field(
        description="SQLAlchemy async URL, e.g. postgresql+asyncpg://user:pass@host:5432/db",
    )
    db_pool_size: int = Field(default=5, ge=1, le=50)
    db_echo: bool = False

    jwt_secret: SecretStr = Field(description="HS256 signing key; at least 32 characters")
    jwt_algorithm: Literal["HS256"] = "HS256"
    access_token_ttl_minutes: int = Field(default=15, ge=1, le=60)
    refresh_token_ttl_days: int = Field(default=30, ge=1, le=90)

    password_reset_ttl_minutes: int = Field(default=30, ge=5, le=120)
    # D5: only "none" exists today. In development the reset link is written to the log;
    # in production without a provider, forgot/reset password are disabled.
    email_provider: Literal["none"] = "none"
    password_reset_url_base: str = "rideros://reset-password"

    # ---- ML (P2c) ----
    # Root that holds <model>/<version>/ artifact folders (ml/artifacts; mounted read-only in docker).
    # Unset -> the API starts without a model: predictions answer 503 and /ready reports not ready.
    model_dir: Path | None = None
    active_model_name: str = "pickup_o2p"
    active_model_version: str = "1.0.0"

    # ---- RoadContext (Phase 5) ----
    # Per-category duplicate radius / window and TTL. ROAD_RULES (JSON) overrides single categories.
    road_rules: dict[Category, RoadRule] = Field(default_factory=default_road_rules)
    road_corroborate_min_reporters: int = Field(default=2, ge=2, le=20)
    road_resolve_min_cleared: int = Field(default=2, ge=1, le=20)
    # Where report photos are stored (a docker volume). Unset -> reports with a photo answer 503.
    road_image_dir: Path | None = None
    road_image_max_bytes: int = Field(default=5 * 1024 * 1024, ge=1024, le=20 * 1024 * 1024)
    # Photo classifier (cv_service, Phase 5). Unset -> photos are not classified (ai_status stays "none").
    cv_service_url: str | None = None
    cv_timeout_seconds: float = Field(default=15.0, gt=0, le=120)

    # ---- Rate limits (per process, in memory; `limits` syntax) ----
    rate_limit_enabled: bool = True
    rate_limit_default: str = "60/minute"  # per user (valid access token), else per IP
    rate_limit_login: str = "5/minute"  # per IP, and separately per e-mail
    rate_limit_register: str = "3/minute"  # per IP
    rate_limit_password_reset: str = "3/minute"  # per IP, and per e-mail for forgot-password
    rate_limit_road_report: str = "10/minute"  # per user: new road reports and confirmations

    # Request body caps (app/core/body_limit.py): JSON / other bodies; multipart = photo limit + overhead.
    max_json_body_bytes: int = Field(default=256 * 1024, ge=1024, le=10 * 1024 * 1024)

    cors_origins: list[str] = Field(default_factory=list)
    docs_enabled: bool | None = None  # None -> enabled everywhere except production

    @field_validator("model_dir", "road_image_dir", "cv_service_url", mode="before")
    @classmethod
    def _empty_path_is_none(cls, value: object) -> object:
        return None if isinstance(value, str) and not value.strip() else value

    @field_validator("road_rules", mode="before")
    @classmethod
    def _merge_road_rules(cls, value: object) -> object:
        """A partial ROAD_RULES only replaces the categories it names."""
        if isinstance(value, dict):
            return {**default_road_rules(), **value}
        return value

    @field_validator("jwt_secret")
    @classmethod
    def _secret_length(cls, value: SecretStr) -> SecretStr:
        if len(value.get_secret_value()) < 32:
            raise ValueError("JWT_SECRET must be at least 32 characters")
        return value

    @model_validator(mode="after")
    def _production_guards(self) -> Settings:
        if self.env == "production":
            secret = self.jwt_secret.get_secret_value().lower()
            if any(marker in secret for marker in _PLACEHOLDER_MARKERS):
                raise ValueError("JWT_SECRET looks like a placeholder; refusing to start in production")
            if self.db_echo:
                raise ValueError("DB_ECHO must be off in production (it logs query parameters)")
        return self

    @property
    def is_production(self) -> bool:
        return self.env == "production"

    @property
    def show_docs(self) -> bool:
        return (not self.is_production) if self.docs_enabled is None else self.docs_enabled

    @property
    def password_reset_enabled(self) -> bool:
        """D5: the dev-log mode never runs in production."""
        return not (self.is_production and self.email_provider == "none")


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]  # values come from the environment
