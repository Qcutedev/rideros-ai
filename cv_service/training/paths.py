"""Folder layout of cv_service/. Everything under data/ and artifacts/ is gitignored (no redistribution)."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
RAW = DATA / "raw"
INTERIM = DATA / "interim"
ARTIFACTS = ROOT / "artifacts"
REPORTS = ROOT / "reports"

MODEL_NAME = "road_cv"


def artifact_dir(version: str) -> Path:
    return ARTIFACTS / MODEL_NAME / version


def report_dir(version: str) -> Path:
    return REPORTS / version
