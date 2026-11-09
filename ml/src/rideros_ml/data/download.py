"""Download the Meituan INFORMS TSL dataset from a pinned commit and verify SHA-256 hashes.

The data is CC BY-NC 4.0 with a no-redistribution clause, so it is only ever stored under
ml/data/raw/ (gitignored). Hash pins live in the config; an unpinned or mismatching file fails closed.
"""

from __future__ import annotations

import hashlib
import json
import shutil
import urllib.request
import zipfile
from datetime import UTC, datetime
from pathlib import Path

from rideros_ml.config import Config
from rideros_ml.paths import raw_dataset_dir

_CHUNK = 1 << 20


class IntegrityError(RuntimeError):
    """Raised when a downloaded file is unpinned or its hash does not match the pin."""


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(_CHUNK):
            h.update(chunk)
    return h.hexdigest()


def _fetch(url: str, dest: Path) -> None:
    tmp = dest.with_suffix(dest.suffix + ".part")
    req = urllib.request.Request(url, headers={"User-Agent": "rideros-ml-dataset-fetch"})
    with urllib.request.urlopen(req, timeout=120) as resp, tmp.open("wb") as out:  # noqa: S310 (https, pinned)
        shutil.copyfileobj(resp, out, _CHUNK)
    tmp.replace(dest)


def verify_pin(filename: str, actual: str, pins: dict[str, str | None]) -> None:
    expected = pins.get(filename)
    if expected is None:
        raise IntegrityError(
            f"{filename} has no SHA-256 pin. Observed {actual}. "
            "Review the file (and License.txt) manually, then pin this hash in the config."
        )
    if expected != actual:
        raise IntegrityError(f"{filename} hash mismatch: expected {expected}, got {actual}")


def extract_member(zip_path: Path, member: str, dest: Path) -> None:
    """Extract exactly one named member (no path traversal: the output path is fixed by us)."""
    with zipfile.ZipFile(zip_path) as zf:
        names = [n for n in zf.namelist() if not n.startswith("__MACOSX/")]
        if member not in names:
            raise IntegrityError(f"{member} not found in {zip_path.name}; members: {names}")
        with zf.open(member) as src, dest.open("wb") as out:
            shutil.copyfileobj(src, out, _CHUNK)


def download(cfg: Config, *, force: bool = False) -> dict:
    ds = cfg.dataset
    out_dir = raw_dataset_dir(ds.name)
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest: dict = {"repo": ds.repo, "commit": ds.commit, "files": {}}
    observed: dict[str, str] = {}

    for filename in (ds.license_file, ds.waybill_zip):
        dest = out_dir / filename
        if force or not dest.exists():
            _fetch(ds.raw_url(filename), dest)
        digest = sha256_file(dest)
        observed[filename] = digest
        manifest["files"][filename] = {
            "url": ds.raw_url(filename),
            "sha256": digest,
            "bytes": dest.stat().st_size,
            "verified_at": datetime.now(UTC).isoformat(timespec="seconds"),
        }

    # Fail closed before extracting anything.
    for filename, digest in observed.items():
        verify_pin(filename, digest, ds.expected_sha256)

    csv_path = out_dir / ds.waybill_csv
    if force or not csv_path.exists():
        extract_member(out_dir / ds.waybill_zip, ds.waybill_csv, csv_path)
    manifest["extracted"] = {ds.waybill_csv: {"sha256": sha256_file(csv_path), "bytes": csv_path.stat().st_size}}

    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    return manifest


def observed_hashes(cfg: Config) -> dict[str, str]:
    """Download (if needed) and return hashes without enforcing pins - used once to bootstrap the pins."""
    ds = cfg.dataset
    out_dir = raw_dataset_dir(ds.name)
    out_dir.mkdir(parents=True, exist_ok=True)
    result = {}
    for filename in (ds.license_file, ds.waybill_zip):
        dest = out_dir / filename
        if not dest.exists():
            _fetch(ds.raw_url(filename), dest)
        result[filename] = sha256_file(dest)
    return result
