"""Evaluation figures (test set, selected model)."""

from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


def _save(fig, path: Path):
    fig.tight_layout()
    fig.savefig(path, dpi=120)
    plt.close(fig)


def actual_vs_predicted(y, p, path: Path, title: str):
    fig, ax = plt.subplots(figsize=(5.5, 5))
    hb = ax.hexbin(np.clip(p, 0, 60), np.clip(y, 0, 60), gridsize=60, bins="log", cmap="viridis")
    ax.plot([0, 60], [0, 60], color="white", lw=1)
    ax.set(xlabel="predicted minutes", ylabel="actual minutes", title=title)
    fig.colorbar(hb, ax=ax, label="log10(count)")
    _save(fig, path)


def residuals_vs_predicted(y, p, path: Path, title: str):
    r = np.asarray(y) - np.asarray(p)
    fig, ax = plt.subplots(figsize=(6.5, 4))
    hb = ax.hexbin(np.clip(p, 0, 60), np.clip(r, -40, 60), gridsize=60, bins="log", cmap="magma")
    ax.axhline(0, color="white", lw=1)
    ax.set(xlabel="predicted minutes", ylabel="residual (actual - predicted)", title=title)
    fig.colorbar(hb, ax=ax, label="log10(count)")
    _save(fig, path)


def error_distribution(y, p, path: Path, title: str):
    r = np.asarray(y) - np.asarray(p)
    fig, ax = plt.subplots(figsize=(6.5, 3.5))
    ax.hist(np.clip(r, -40, 60), bins=150, color="#4C72B0")
    ax.axvline(0, color="black", lw=1)
    ax.set(xlabel="residual minutes (clipped -40..60)", ylabel="orders", title=title)
    _save(fig, path)


def mae_by_hour(df: pd.DataFrame, y_col: str, pred_cols: dict[str, str], path: Path, title: str):
    fig, ax = plt.subplots(figsize=(8, 3.5))
    for label, col in pred_cols.items():
        mae = (df[col] - df[y_col]).abs().groupby(df["hour"]).mean()
        ax.plot(mae.index, mae.values, marker="o", label=label)
    ax.set(xlabel="local hour", ylabel="MAE (minutes)", title=title)
    ax.legend()
    _save(fig, path)


def model_comparison(rows: list[dict], path: Path):
    names = [r["model"] for r in rows]
    val = [r["val_mae"] for r in rows]
    test = [r["test_mae"] for r in rows]
    x = np.arange(len(names))
    fig, ax = plt.subplots(figsize=(9, 3.8))
    ax.bar(x - 0.2, val, 0.4, label="validation MAE")
    ax.bar(x + 0.2, test, 0.4, label="test MAE")
    ax.set_xticks(x, names, rotation=25, ha="right")
    ax.set(ylabel="MAE (minutes)", title="Model comparison")
    ax.legend()
    _save(fig, path)
