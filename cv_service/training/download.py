"""Fetch the raw datasets into data/raw/ and verify them against the pins in sources.py.

RDD2022 is one 13.3 GB zip of per-country zips stored without compression, so each country zip is a
contiguous byte range of the outer file: we read the outer central directory (a few range requests),
then download only the countries we use and check their CRC-32 from that directory as well as the pin.
"""

from __future__ import annotations

import hashlib
import io
import json
import shutil
import struct
import urllib.request
import zipfile
import zlib
from datetime import UTC, datetime
from pathlib import Path

from training import sources
from training.paths import RAW

_CHUNK = 1 << 20
_UA = {"User-Agent": "rideros-cv-dataset-fetch"}


class IntegrityError(RuntimeError):
    """A file is unpinned, or its hash/size/CRC does not match."""


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(_CHUNK):
            h.update(chunk)
    return h.hexdigest()


def verify_pin(path: Path) -> str:
    pin = sources.PINS.get(path.name)
    digest = sha256_file(path)
    if pin is None or pin.sha256 is None:
        raise IntegrityError(
            f"{path.name} has no SHA-256 pin. Observed {digest} ({path.stat().st_size} bytes). "
            "Review the file and its license, then pin the hash in training/sources.py."
        )
    if pin.sha256 != digest:
        raise IntegrityError(f"{path.name} hash mismatch: expected {pin.sha256}, got {digest}")
    if pin.bytes is not None and pin.bytes != path.stat().st_size:
        raise IntegrityError(f"{path.name} size mismatch: expected {pin.bytes}, got {path.stat().st_size}")
    return digest


class HttpRangeFile(io.RawIOBase):
    """Read-only, seekable view of a remote file through HTTP Range requests (enough for zipfile)."""

    def __init__(self, url: str) -> None:
        self.url = url
        self._pos = 0
        with self._open(0, 0) as resp:
            self.size = int(resp.headers["Content-Range"].rsplit("/", 1)[1])

    def _open(self, start: int, end: int):
        req = urllib.request.Request(self.url, headers={**_UA, "Range": f"bytes={start}-{end}"})
        resp = urllib.request.urlopen(req, timeout=120)  # noqa: S310 (fixed https URL)
        if resp.status != 206:
            resp.close()
            raise IntegrityError(f"server ignored the Range header (HTTP {resp.status})")
        return resp

    def readable(self) -> bool:
        return True

    def seekable(self) -> bool:
        return True

    def tell(self) -> int:
        return self._pos

    def seek(self, offset: int, whence: int = io.SEEK_SET) -> int:
        base = {io.SEEK_SET: 0, io.SEEK_CUR: self._pos, io.SEEK_END: self.size}[whence]
        self._pos = base + offset
        return self._pos

    def read(self, n: int = -1) -> bytes:
        if n is None or n < 0:
            n = self.size - self._pos
        n = min(n, self.size - self._pos)
        if n <= 0:
            return b""
        with self._open(self._pos, self._pos + n - 1) as resp:
            data = resp.read()
        self._pos += len(data)
        return data

    def copy_range(self, start: int, length: int, out: io.BufferedWriter) -> int:
        """Stream `length` bytes from `start` into `out`; returns the CRC-32 of what was written."""
        crc = 0
        with self._open(start, start + length - 1) as resp:
            while chunk := resp.read(_CHUNK):
                out.write(chunk)
                crc = zlib.crc32(chunk, crc)
        return crc


def _stored_member_span(remote: HttpRangeFile, info: zipfile.ZipInfo) -> tuple[int, int]:
    """Byte offset and length of a stored (uncompressed) member's data inside the outer zip."""
    if info.compress_type != zipfile.ZIP_STORED:
        raise IntegrityError(f"{info.filename} is compressed; range download needs a stored member")
    remote.seek(info.header_offset)
    header = remote.read(30)
    if header[:4] != b"PK\x03\x04":
        raise IntegrityError(f"bad local header for {info.filename}")
    name_len, extra_len = struct.unpack("<HH", header[26:30])
    return info.header_offset + 30 + name_len + extra_len, info.compress_size


def fetch_rdd(countries: tuple[str, ...] = sources.RDD_COUNTRIES, *, force: bool = False) -> dict:
    RAW.mkdir(parents=True, exist_ok=True)
    remote = HttpRangeFile(sources.RDD_URL)
    members = {i.filename: i for i in zipfile.ZipFile(remote).infolist()}
    out: dict = {}
    for country in countries:
        info = members.get(f"RDD2022/{country}.zip")
        if info is None:
            raise IntegrityError(f"RDD2022/{country}.zip not in the archive: {sorted(members)}")
        dest = RAW / f"RDD2022_{country}.zip"
        if force or not dest.exists() or dest.stat().st_size != info.file_size:
            start, length = _stored_member_span(remote, info)
            tmp = dest.with_suffix(".zip.part")
            with tmp.open("wb") as f:
                crc = remote.copy_range(start, length, f)
            if crc != info.CRC:
                tmp.unlink()
                raise IntegrityError(f"{dest.name}: CRC-32 {crc:08x} != central directory {info.CRC:08x}")
            tmp.replace(dest)
        out[dest.name] = {"source": f"{sources.RDD_URL} :: {info.filename}", "bytes": info.file_size}
    return out


def fetch_url(url: str, dest: Path, *, force: bool = False) -> None:
    if dest.exists() and not force:
        return
    RAW.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(dest.suffix + ".part")
    req = urllib.request.Request(url, headers=_UA)
    with urllib.request.urlopen(req, timeout=120) as resp, tmp.open("wb") as f:  # noqa: S310
        shutil.copyfileobj(resp, f, _CHUNK)
    tmp.replace(dest)


def download(*, alley_zip: Path | None = None, force: bool = False) -> dict:
    """Fetch everything that is missing, then verify every pin. Writes data/raw/manifest.json."""
    files: dict = {}
    files.update(fetch_rdd(force=force))

    flood = RAW / "Flood10k.zip"
    fetch_url(sources.FLOOD10K_URL, flood, force=force)
    files[flood.name] = {"source": sources.FLOOD10K_URL, "bytes": flood.stat().st_size}

    alley = RAW / "alleyfloodnet.zip"
    if alley_zip is not None:
        shutil.copyfile(alley_zip, alley)
    if not alley.exists():
        raise IntegrityError(
            f"{alley} is missing. Download the zip from {sources.ALLEY_PAGE} (Kaggle sign-in needed) "
            "and run `python -m training download --alley <path to zip>`."
        )
    files[alley.name] = {"source": sources.ALLEY_PAGE, "bytes": alley.stat().st_size}

    errors: list[str] = []
    for name, entry in files.items():
        try:
            entry["sha256"] = verify_pin(RAW / name)
        except IntegrityError as exc:
            errors.append(str(exc))
    manifest = {"verified_at": datetime.now(UTC).isoformat(timespec="seconds"), "files": files}
    if errors:
        raise IntegrityError("\n".join(errors))
    (RAW / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    return manifest
