"""`model_versions` (docs/DATABASE_DESIGN.md): one row per trained model version the app has used."""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import Boolean, Index, Text, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import DateTime

from app.db.base import Base, created_at_column, uuid_pk


class ModelVersion(Base):
    """Registered from the model's own description (cv_service `GET /model`); `metrics` is verbatim."""

    __tablename__ = "model_versions"
    __table_args__ = (
        Index("uq_model_versions_name_version", "name", "version", unique=True),
        Index("uq_model_versions_active_name", "name", unique=True, postgresql_where=text("is_active")),
    )

    id: Mapped[uuid.UUID] = uuid_pk()
    name: Mapped[str] = mapped_column(Text, nullable=False)
    version: Mapped[str] = mapped_column(Text, nullable=False)
    task: Mapped[str] = mapped_column(Text, nullable=False)
    dataset: Mapped[str] = mapped_column(Text, nullable=False)
    metrics: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    feature_schema: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    artifact_uri: Mapped[str] = mapped_column(Text, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))
    trained_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = created_at_column()
