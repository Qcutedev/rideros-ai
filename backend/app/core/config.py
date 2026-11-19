"""Application settings, read from environment variables (and `.env` in development).

Secrets have no usable defaults: `JWT_SECRET` must be set explicitly, and production refuses
anything that looks like a placeholder.
"""

from functools import lru_cache
from typing import Literal

from pydantic import Field, SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

Environment = Literal["development", "test", "production"]

_PLACEHOLDER_MARKERS = ("change-me", "changeme", "example", "placeholder", "secret")


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

    # ---- Rate limits (`limits` syntax) ----
    rate_limit_enabled: bool = True
    # memory:// counts per process (one worker); redis://host:6379/0 (Redis/Valkey) shares the counts
    # between workers and instances. It may carry a password, so it is a secret in logs.
    rate_limit_storage_url: str = "memory://"
    # uvicorn reads the same WEB_CONCURRENCY for its worker count; here it only guards production.
    web_concurrency: int = Field(default=1, ge=1, le=32)
    rate_limit_default: str = "60/minute"  # per user (valid access token), else per IP
    rate_limit_login: str = "5/minute"  # per IP, and separately per e-mail
    rate_limit_register: str = "3/minute"  # per IP
    rate_limit_password_reset: str = "3/minute"  # per IP, and per e-mail for forgot-password

    # Request body cap (app/core/body_limit.py). The API only takes JSON, so one cap covers every body.
    max_json_body_bytes: int = Field(default=256 * 1024, ge=1024, le=10 * 1024 * 1024)

    cors_origins: list[str] = Field(default_factory=list)
    docs_enabled: bool | None = None  # None -> enabled everywhere except production

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
            if self.web_concurrency > 1 and self.rate_limit_storage_url.lower().startswith("memory"):
                raise ValueError(
                    "WEB_CONCURRENCY > 1 needs a shared RATE_LIMIT_STORAGE_URL (redis://…) in production;"
                    " memory:// would count each worker separately"
                )
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
