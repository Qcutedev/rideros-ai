"""Cursor pagination (`?limit=&cursor=`, docs/SYSTEM_ARCHITECTURE.md §4).

A cursor is the sort key of the last item on the previous page, as URL-safe base64 JSON. It is
not a secret: every list query also filters by the current user, so a crafted cursor can only
move within the caller's own rows.
"""

import base64
import binascii
import json
from typing import Annotated, Any

from fastapi import Query
from pydantic import BaseModel

from app.core.errors import AppError

DEFAULT_PAGE_SIZE = 50
MAX_PAGE_SIZE = 100
_MAX_CURSOR_LENGTH = 512

LimitQuery = Annotated[int, Query(ge=1, le=MAX_PAGE_SIZE, description="Page size")]
CursorQuery = Annotated[
    str | None, Query(max_length=_MAX_CURSOR_LENGTH, description="`next_cursor` of the previous page")
]


class InvalidCursorError(AppError):
    code = "invalid_cursor"
    message = "Invalid pagination cursor"


class Page[T](BaseModel):
    items: list[T]
    next_cursor: str | None


def encode_cursor(values: list[Any]) -> str:
    raw = json.dumps(values, separators=(",", ":"), default=str).encode("utf-8")
    return base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=")


def decode_cursor(cursor: str, size: int) -> list[str]:
    """Return the `size` string values stored in the cursor, or raise InvalidCursorError."""
    try:
        padded = cursor + "=" * (-len(cursor) % 4)
        values = json.loads(base64.urlsafe_b64decode(padded.encode("ascii")))
    except (ValueError, UnicodeError, binascii.Error) as exc:
        raise InvalidCursorError() from exc
    if not isinstance(values, list) or len(values) != size or not all(isinstance(v, str) for v in values):
        raise InvalidCursorError()
    return values
