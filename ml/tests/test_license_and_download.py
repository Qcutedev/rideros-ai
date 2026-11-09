"""License gate, SHA-256 pin enforcement and safe zip extraction."""

from __future__ import annotations

import hashlib
import zipfile

import pytest

from rideros_ml.data import download as dl
from rideros_ml.data.license_check import REQUIRED_CLAUSES, check_license_file, check_license_text
from rideros_ml.paths import raw_dataset_dir

FULL_TEXT = "Preamble.\n" + "\n".join(
    f"Some text. {phrase} More text." for phrase in REQUIRED_CLAUSES.values()
)


# ---------------- license clauses ----------------


def test_all_clauses_present_passes():
    assert all(c.present for c in check_license_text(FULL_TEXT))
    assert {c.clause for c in check_license_text(FULL_TEXT)} == set(REQUIRED_CLAUSES)


@pytest.mark.parametrize("missing", list(REQUIRED_CLAUSES))
def test_missing_clause_fails(missing):
    text = FULL_TEXT.replace(REQUIRED_CLAUSES[missing], "[removed]")
    result = {c.clause: c.present for c in check_license_text(text)}
    assert result[missing] is False
    assert all(v for k, v in result.items() if k != missing)


def test_reworded_clause_fails():
    text = FULL_TEXT.replace("is not allowed", "is allowed")
    result = {c.clause: c.present for c in check_license_text(text)}
    assert result["no_redistribution"] is False


def test_clause_split_across_lines_still_matches():
    phrase = REQUIRED_CLAUSES["no_redistribution"]
    words = phrase.split()
    wrapped = FULL_TEXT.replace(phrase, " ".join(words[:4]) + "\n   " + " ".join(words[4:]))
    assert all(c.present for c in check_license_text(wrapped))


@pytest.mark.data
def test_downloaded_license_passes(cfg):
    path = raw_dataset_dir(cfg.dataset.name) / cfg.dataset.license_file
    assert all(c.present for c in check_license_file(path))
    assert dl.sha256_file(path) == cfg.dataset.expected_sha256[cfg.dataset.license_file]


# ---------------- hash pins ----------------


def test_sha256_file_matches_hashlib(tmp_path):
    p = tmp_path / "f.bin"
    payload = b"rideros" * 500_000  # > 1 chunk
    p.write_bytes(payload)
    assert dl.sha256_file(p) == hashlib.sha256(payload).hexdigest()


def test_null_pin_fails_closed():
    with pytest.raises(dl.IntegrityError, match="no SHA-256 pin"):
        dl.verify_pin("a.zip", "abc", {"a.zip": None})


def test_absent_pin_fails_closed():
    with pytest.raises(dl.IntegrityError, match="no SHA-256 pin"):
        dl.verify_pin("a.zip", "abc", {})


def test_mismatching_pin_fails():
    with pytest.raises(dl.IntegrityError, match="mismatch"):
        dl.verify_pin("a.zip", "abc", {"a.zip": "def"})


def test_matching_pin_passes():
    dl.verify_pin("a.zip", "abc", {"a.zip": "abc"})


# ---------------- zip extraction ----------------


def _zip(path, members: dict[str, bytes]):
    with zipfile.ZipFile(path, "w") as zf:
        for name, data in members.items():
            zf.writestr(name, data)


def test_extract_only_named_member(tmp_path):
    src = tmp_path / "src"
    src.mkdir()
    out = tmp_path / "out"
    out.mkdir()
    z = src / "data.zip"
    _zip(z, {"data.csv": b"a,b\n1,2\n", "__MACOSX/data.csv": b"junk", "../evil.csv": b"x", "other.txt": b"y"})
    dl.extract_member(z, "data.csv", out / "data.csv")
    assert (out / "data.csv").read_bytes() == b"a,b\n1,2\n"
    assert sorted(p.name for p in out.iterdir()) == ["data.csv"]
    assert not (tmp_path / "evil.csv").exists()


def test_extract_missing_member_fails(tmp_path):
    z = tmp_path / "data.zip"
    _zip(z, {"other.csv": b"x"})
    with pytest.raises(dl.IntegrityError, match="not found"):
        dl.extract_member(z, "data.csv", tmp_path / "data.csv")


def test_macosx_member_is_not_extractable(tmp_path):
    z = tmp_path / "data.zip"
    _zip(z, {"__MACOSX/data.csv": b"junk"})
    with pytest.raises(dl.IntegrityError):
        dl.extract_member(z, "__MACOSX/data.csv", tmp_path / "out.csv")


# ---------------- download() end to end (network mocked) ----------------


@pytest.fixture
def fake_remote(tmp_path, monkeypatch, cfg):
    """Serve License.txt + zip from memory; redirect the raw data dir into tmp_path."""
    zbuf = tmp_path / "remote.zip"
    _zip(zbuf, {cfg.dataset.waybill_csv: b"col\n1\n"})
    files = {cfg.dataset.license_file: FULL_TEXT.encode(), cfg.dataset.waybill_zip: zbuf.read_bytes()}

    def fake_fetch(url, dest):
        dest.write_bytes(files[url.rsplit("/", 1)[-1]])

    out_dir = tmp_path / "raw"
    monkeypatch.setattr(dl, "_fetch", fake_fetch)
    monkeypatch.setattr(dl, "raw_dataset_dir", lambda _name: out_dir)
    pins = {name: hashlib.sha256(data).hexdigest() for name, data in files.items()}
    return out_dir, pins


def test_download_with_correct_pins_extracts(cfg, cfg_with, fake_remote):
    out_dir, pins = fake_remote
    manifest = dl.download(cfg_with(cfg, dataset={"expected_sha256": pins}))
    assert (out_dir / cfg.dataset.waybill_csv).read_bytes() == b"col\n1\n"
    assert manifest["commit"] == cfg.dataset.commit
    assert manifest["files"][cfg.dataset.waybill_zip]["sha256"] == pins[cfg.dataset.waybill_zip]


@pytest.mark.parametrize("bad", ["null", "wrong"])
def test_download_fails_closed_before_extracting(cfg, cfg_with, fake_remote, bad):
    out_dir, pins = fake_remote
    pins = {**pins, cfg.dataset.waybill_zip: None if bad == "null" else "0" * 64}
    with pytest.raises(dl.IntegrityError):
        dl.download(cfg_with(cfg, dataset={"expected_sha256": pins}))
    assert not (out_dir / cfg.dataset.waybill_csv).exists()
    assert not (out_dir / "manifest.json").exists()


def test_config_pins_are_set(cfg):
    for name in (cfg.dataset.license_file, cfg.dataset.waybill_zip):
        pin = cfg.dataset.expected_sha256[name]
        assert pin is not None and len(pin) == 64
