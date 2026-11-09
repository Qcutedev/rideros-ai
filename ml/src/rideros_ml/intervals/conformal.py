"""Split conformal prediction intervals with asymmetric residual quantiles.

Calibrated on residuals r = y - y_hat of a held-out set. Each tail gets alpha/2 with the finite-sample
correction, so marginal coverage >= 1 - alpha holds under exchangeability. Our calibration (val day) and
test day are different days, so exchangeability is an assumption -> coverage is MEASURED on test and reported.
"""

from __future__ import annotations

import math
from dataclasses import asdict, dataclass

import numpy as np


@dataclass(frozen=True)
class ConformalInterval:
    alpha: float
    q_low: float   # added to the prediction (negative)
    q_high: float  # added to the prediction (positive)
    n_calibration: int

    def interval(self, y_hat, floor: float = 0.0):
        y_hat = np.asarray(y_hat, float)
        return np.maximum(y_hat + self.q_low, floor), y_hat + self.q_high

    def to_dict(self) -> dict:
        return asdict(self)


def _finite_sample_level(n: int, tail: float, upper: bool) -> float:
    k = math.ceil((n + 1) * (1 - tail)) if upper else math.floor((n + 1) * tail)
    return min(max(k / n, 0.0), 1.0)


def calibrate(y_true, y_pred, alpha: float) -> ConformalInterval:
    r = np.asarray(y_true, float) - np.asarray(y_pred, float)
    n = len(r)
    if n < 100:
        raise ValueError("need at least 100 calibration points")
    q_low = float(np.quantile(r, _finite_sample_level(n, alpha / 2, upper=False), method="lower"))
    q_high = float(np.quantile(r, _finite_sample_level(n, alpha / 2, upper=True), method="higher"))
    return ConformalInterval(alpha=alpha, q_low=q_low, q_high=q_high, n_calibration=n)


def coverage(y_true, low, high) -> dict[str, float]:
    y = np.asarray(y_true, float)
    inside = (y >= low) & (y <= high)
    return {"coverage": float(inside.mean()), "mean_width": float(np.mean(high - low))}
