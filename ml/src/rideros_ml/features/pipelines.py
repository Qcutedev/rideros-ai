"""Feature preprocessing per model family.

Leakage controls:
- Only columns listed in the config feature sets are ever selected (FeatureFrame); post-t0 columns are rejected.
- POI target encoding uses sklearn's TargetEncoder, which cross-fits on the training data (fit_transform) and
  uses full-train statistics for val/test/inference -> a row's own target never encodes itself.
- CatBoost uses its ordered target statistics with has_time=True on time-sorted training rows.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.compose import ColumnTransformer
from sklearn.model_selection import KFold
from sklearn.preprocessing import OneHotEncoder, OrdinalEncoder, TargetEncoder

from rideros_ml.data.schema import PLATFORM_ESTIMATE_COLUMNS, POST_T0_COLUMNS

CATEGORICAL = ("poi_id", "da_id")
INT_COLUMNS = ("hour", "is_weekend", "poi_orders_last_30m", "da_orders_last_30m", "poi_open_orders")
FORBIDDEN = POST_T0_COLUMNS | PLATFORM_ESTIMATE_COLUMNS | {"order_to_pickup_min", "meituan_est_ready_min"}


class FeatureFrame(BaseEstimator, TransformerMixin):
    """Select and type-coerce the model input columns. Fails on missing columns or forbidden ones."""

    def __init__(self, columns: list[str]):
        self.columns = columns

    def fit(self, X, y=None):
        bad = set(self.columns) & FORBIDDEN
        if bad:
            raise ValueError(f"forbidden (post-t0 / target / platform-estimate) columns requested: {sorted(bad)}")
        return self

    def transform(self, X: pd.DataFrame) -> pd.DataFrame:
        missing = [c for c in self.columns if c not in X.columns]
        if missing:
            raise KeyError(f"missing input columns: {missing}")
        out = X[self.columns].copy()
        for c in self.columns:
            if c in CATEGORICAL:
                out[c] = out[c].astype(str)
            elif c in INT_COLUMNS:
                out[c] = pd.to_numeric(out[c], errors="raise").astype("int64")
            else:
                out[c] = pd.to_numeric(out[c], errors="raise").astype("float64")
        return out


class CountEncoder(BaseEstimator, TransformerMixin):
    """log1p(number of training rows) per category; unseen categories -> 0."""

    def fit(self, X: pd.DataFrame, y=None):
        self.counts_ = {c: X[c].value_counts() for c in X.columns}
        return self

    def transform(self, X: pd.DataFrame) -> np.ndarray:
        return np.column_stack([np.log1p(X[c].map(self.counts_[c]).fillna(0).to_numpy(float)) for c in X.columns])

    def get_feature_names_out(self, input_features=None):
        return np.array([f"{c}_log_count" for c in self.counts_])


def _numeric(columns: list[str]) -> list[str]:
    return [c for c in columns if c not in CATEGORICAL]


def _poi_target_encoder(seed: int) -> TargetEncoder:
    return TargetEncoder(target_type="continuous", cv=KFold(n_splits=5, shuffle=True, random_state=seed))


def linear_preprocessor(columns: list[str], seed: int) -> ColumnTransformer:
    num = [c for c in _numeric(columns) if c != "hour"]
    return ColumnTransformer(
        [
            ("poi_te", _poi_target_encoder(seed), ["poi_id"]),
            ("poi_cnt", CountEncoder(), ["poi_id"]),
            ("da_oh", OneHotEncoder(handle_unknown="ignore", sparse_output=False), ["da_id"]),
            ("hour_oh", OneHotEncoder(handle_unknown="ignore", sparse_output=False), ["hour"]),
            ("num", "passthrough", num),
        ],
        verbose_feature_names_out=False,
    )


def tree_preprocessor(columns: list[str], seed: int) -> ColumnTransformer:
    return ColumnTransformer(
        [
            ("poi_te", _poi_target_encoder(seed), ["poi_id"]),
            ("poi_cnt", CountEncoder(), ["poi_id"]),
            ("da_ord", OrdinalEncoder(handle_unknown="use_encoded_value", unknown_value=-1), ["da_id"]),
            ("num", "passthrough", _numeric(columns)),
        ],
        verbose_feature_names_out=False,
    )
