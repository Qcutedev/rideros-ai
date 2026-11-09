"""Filesystem layout of the ml/ project. All paths are absolute and derived from this file's location."""

from pathlib import Path

ML_ROOT = Path(__file__).resolve().parents[2]
CONFIG_DIR = ML_ROOT / "configs"
DATA_DIR = ML_ROOT / "data"
RAW_DIR = DATA_DIR / "raw"
PROCESSED_DIR = DATA_DIR / "processed"
ARTIFACTS_DIR = ML_ROOT / "artifacts"
REPORTS_DIR = ML_ROOT / "reports"


def raw_dataset_dir(dataset_name: str) -> Path:
    return RAW_DIR / dataset_name
