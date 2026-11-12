"""Service settings (environment variables)."""

from functools import lru_cache
from pathlib import Path

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Folder with model.pt + metadata.json (artifacts/road_cv/<version>). Unset -> /classify answers 503.
    cv_model_dir: Path | None = None
    cv_max_bytes: int = Field(default=5 * 1024 * 1024, ge=1024, le=20 * 1024 * 1024)
    # Torch intra-op threads. One request at a time per worker; 1 thread keeps latency predictable.
    cv_threads: int = Field(default=1, ge=1, le=16)

    @field_validator("cv_model_dir", mode="before")
    @classmethod
    def _empty_is_none(cls, value: object) -> object:
        return None if isinstance(value, str) and not value.strip() else value


@lru_cache
def get_settings() -> Settings:
    return Settings()
