"""Report photos: validate, strip metadata, store (docs/SYSTEM_ARCHITECTURE.md §5, "File upload").

Only JPEG / PNG / WebP are accepted, recognised by their magic bytes (the client's content type
and file name are ignored). Every photo is decoded and re-encoded as a new JPEG, which drops EXIF
(GPS position included), ICC/XMP blocks and any bytes appended to the file. Files get a random
name; a client never chooses a path.
"""

import io
import os
import re
import uuid
from pathlib import Path

from PIL import Image, ImageOps, UnidentifiedImageError

from app.core.errors import AppError, ServiceUnavailableError

MAX_PIXELS = 40_000_000  # decoded size guard (a 5 MB PNG can expand to gigabytes)
MAX_SIDE_PX = 1600  # stored photos are downscaled to this on the long side
JPEG_QUALITY = 85
_FORMATS = {"JPEG", "PNG", "WEBP"}
_KEY = re.compile(r"^[0-9a-f]{32}\.jpg$")


class UnsupportedImageError(AppError):
    status_code = 415
    code = "unsupported_image"
    message = "The photo must be a JPEG, PNG or WebP image"


class ImageTooLargeError(AppError):
    status_code = 413
    code = "image_too_large"
    message = "The photo is too large"


class ImageStorageUnavailableError(ServiceUnavailableError):
    code = "image_storage_unavailable"
    message = "Photo uploads are not configured on this server; send the report without a photo"


def sniff(data: bytes) -> str | None:
    """Image format from the leading bytes, or None."""
    if data.startswith(b"\xff\xd8\xff"):
        return "JPEG"
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "PNG"
    if len(data) >= 12 and data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "WEBP"
    return None


def reencode(data: bytes) -> bytes:
    """Return a clean JPEG of the photo (upright, RGB, ≤ MAX_SIDE_PX, no metadata)."""
    if sniff(data) is None:
        raise UnsupportedImageError()
    try:
        with Image.open(io.BytesIO(data)) as img:
            if img.format not in _FORMATS:
                raise UnsupportedImageError()
            if img.width * img.height > MAX_PIXELS:
                raise ImageTooLargeError(f"The photo is larger than {MAX_PIXELS // 1_000_000} megapixels")
            upright = ImageOps.exif_transpose(img)  # apply the orientation tag before EXIF is dropped
            if upright.mode in ("RGBA", "LA", "P"):
                rgba = upright.convert("RGBA")
                flat = Image.new("RGB", rgba.size, (255, 255, 255))
                flat.paste(rgba, mask=rgba.getchannel("A"))
            else:
                flat = upright.convert("RGB")
            flat.thumbnail((MAX_SIDE_PX, MAX_SIDE_PX))
            out = io.BytesIO()
            flat.save(out, "JPEG", quality=JPEG_QUALITY, optimize=True)  # no exif= -> none written
            return out.getvalue()
    except (UnidentifiedImageError, OSError, SyntaxError, ValueError, Image.DecompressionBombError) as exc:
        raise UnsupportedImageError("The photo could not be read") from exc


class ImageStore:
    """Photos as `<root>/<32 hex>.jpg` (a docker volume in development)."""

    def __init__(self, root: Path) -> None:
        self.root = root

    def save(self, jpeg: bytes) -> str:
        self.root.mkdir(parents=True, exist_ok=True)
        key = f"{uuid.uuid4().hex}.jpg"
        tmp = self.root / f".{key}.tmp"
        tmp.write_bytes(jpeg)
        os.replace(tmp, self.root / key)
        return key

    def path(self, key: str) -> Path:
        if not _KEY.match(key):  # keys are generated here; anything else is never turned into a path
            raise ValueError("invalid image key")
        return self.root / key

    def delete(self, keys: list[str]) -> None:
        for key in keys:
            try:
                self.path(key).unlink(missing_ok=True)
            except ValueError, OSError:
                continue
