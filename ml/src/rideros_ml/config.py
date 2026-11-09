"""Typed access to the YAML experiment config."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml

from rideros_ml.paths import CONFIG_DIR


@dataclass(frozen=True)
class DatasetConfig:
    name: str
    repo: str
    commit: str
    license_file: str
    waybill_zip: str
    waybill_csv: str
    expected_sha256: dict[str, str | None]
    expected_rows: int
    local_utc_offset_hours: int

    def raw_url(self, filename: str) -> str:
        return f"https://raw.githubusercontent.com/{self.repo}/{self.commit}/{filename}"


@dataclass(frozen=True)
class TargetConfig:
    name: str
    min_minutes: float | None
    max_minutes: float | None


@dataclass(frozen=True)
class SplitConfig:
    train_last_date: str
    val_date: str
    test_date: str


@dataclass(frozen=True)
class FeatureConfig:
    categorical: list[str]
    numeric: list[str]
    ablation_extra: list[str]

    @property
    def deployable(self) -> list[str]:
        return [*self.categorical, *self.numeric]


@dataclass(frozen=True)
class Config:
    dataset: DatasetConfig
    target: TargetConfig
    split: SplitConfig
    features: FeatureConfig
    training: dict[str, Any]
    conformal_alpha: float
    model_name: str
    model_version: str
    min_orders_for_stats: int
    source_path: Path


def load_config(path: Path | None = None) -> Config:
    path = path or CONFIG_DIR / "pickup_o2p.yaml"
    raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    return Config(
        dataset=DatasetConfig(**raw["dataset"]),
        target=TargetConfig(**raw["target"]),
        split=SplitConfig(**raw["split"]),
        features=FeatureConfig(**raw["features"]),
        training=raw["training"],
        conformal_alpha=float(raw["conformal"]["alpha"]),
        model_name=raw["model"]["name"],
        model_version=str(raw["model"]["version"]),
        min_orders_for_stats=int(raw["analytics"]["min_orders_for_stats"]),
        source_path=path,
    )
