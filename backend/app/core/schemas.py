"""Base request models shared by the modules."""

from typing import ClassVar

from pydantic import BaseModel, ConfigDict, model_validator


class StrictModel(BaseModel):
    """Request body: unknown fields are rejected (e.g. `user_id`, `is_demo`, `role`)."""

    model_config = ConfigDict(extra="forbid")


class PatchModel(StrictModel):
    """Partial update: only the fields the client sent are applied (`model_dump(exclude_unset=True)`).

    Fields listed in `non_nullable` map to NOT NULL columns, so an explicit `null` is rejected.
    """

    non_nullable: ClassVar[frozenset[str]] = frozenset()

    @model_validator(mode="after")
    def _reject_null_for_required(self) -> PatchModel:
        nulls = sorted(f for f in self.model_fields_set & self.non_nullable if getattr(self, f) is None)
        if nulls:
            raise ValueError(f"{', '.join(nulls)} cannot be null")
        return self

    def changes(self) -> dict[str, object]:
        return self.model_dump(exclude_unset=True)
