"""Baselines every model must beat."""

from __future__ import annotations

import numpy as np
import pandas as pd
from sklearn.base import BaseEstimator, RegressorMixin


class GlobalMedianRegressor(BaseEstimator, RegressorMixin):
    def fit(self, X, y):
        self.median_ = float(np.median(y))
        return self

    def predict(self, X):
        return np.full(len(X), self.median_)


class PoiMedianRegressor(BaseEstimator, RegressorMixin):
    """Per-restaurant historical median; restaurants with < min_count train orders fall back to the global median."""

    def __init__(self, min_count: int = 5):
        self.min_count = min_count

    def fit(self, X: pd.DataFrame, y):
        y = pd.Series(np.asarray(y, float), index=X.index)
        stats = y.groupby(X["poi_id"]).agg(["median", "size"])
        self.global_median_ = float(y.median())
        self.poi_median_ = stats.loc[stats["size"] >= self.min_count, "median"]
        return self

    def predict(self, X: pd.DataFrame):
        return X["poi_id"].map(self.poi_median_).fillna(self.global_median_).to_numpy(float)
