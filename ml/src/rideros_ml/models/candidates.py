"""Candidate model builders. Each returns a FITTED sklearn Pipeline whose input is the raw order frame."""

from __future__ import annotations

import os

import pandas as pd
from catboost import CatBoostRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.pipeline import Pipeline
from xgboost import XGBRegressor

from rideros_ml.features.pipelines import CATEGORICAL, FeatureFrame, linear_preprocessor, tree_preprocessor
from rideros_ml.models.baselines import GlobalMedianRegressor, PoiMedianRegressor

N_JOBS = max(1, (os.cpu_count() or 2) - 1)


def _assemble(frame: FeatureFrame, pre, model) -> Pipeline:
    steps = [("frame", frame)]
    if pre is not None:
        steps.append(("pre", pre))
    steps.append(("model", model))
    return Pipeline(steps)


def fit_global_median(train: pd.DataFrame, y) -> Pipeline:
    frame = FeatureFrame(["poi_id"]).fit(train)
    return _assemble(frame, None, GlobalMedianRegressor().fit(frame.transform(train), y))


def fit_poi_median(train: pd.DataFrame, y) -> Pipeline:
    frame = FeatureFrame(["poi_id"]).fit(train)
    return _assemble(frame, None, PoiMedianRegressor(min_count=5).fit(frame.transform(train), y))


def fit_linear(train: pd.DataFrame, y, columns: list[str], seed: int) -> Pipeline:
    frame = FeatureFrame(columns).fit(train)
    pre = linear_preprocessor(columns, seed)
    Xt = pre.fit_transform(frame.transform(train), y)
    return _assemble(frame, pre, LinearRegression().fit(Xt, y))


def fit_random_forest(train: pd.DataFrame, y, columns: list[str], seed: int, params: dict) -> Pipeline:
    frame = FeatureFrame(columns).fit(train)
    pre = tree_preprocessor(columns, seed)
    Xt = pre.fit_transform(frame.transform(train), y)
    model = RandomForestRegressor(random_state=seed, n_jobs=N_JOBS, **params).fit(Xt, y)
    return _assemble(frame, pre, model)


def fit_xgboost(train, y, val, y_val, columns: list[str], seed: int, params: dict) -> Pipeline:
    frame = FeatureFrame(columns).fit(train)
    pre = tree_preprocessor(columns, seed)
    Xt = pre.fit_transform(frame.transform(train), y)
    Xv = pre.transform(frame.transform(val))
    model = XGBRegressor(
        n_estimators=2000,
        early_stopping_rounds=100,
        objective="reg:squarederror",
        eval_metric="mae",
        tree_method="hist",
        random_state=seed,
        n_jobs=N_JOBS,
        **params,
    )
    model.fit(Xt, y, eval_set=[(Xv, y_val)], verbose=False)
    return _assemble(frame, pre, model)


def fit_catboost(train, y, val, y_val, columns: list[str], seed: int, params: dict) -> Pipeline:
    """train must be sorted by t0: has_time=True makes CatBoost's ordered target statistics time-causal."""
    frame = FeatureFrame(columns).fit(train)
    cat = [c for c in columns if c in CATEGORICAL]
    model = CatBoostRegressor(
        iterations=2000,
        loss_function="RMSE",
        eval_metric="MAE",
        od_type="Iter",
        od_wait=100,
        use_best_model=True,
        has_time=True,
        cat_features=cat,
        random_seed=seed,
        thread_count=N_JOBS,
        allow_writing_files=False,
        verbose=0,
        **params,
    )
    model.fit(frame.transform(train), y, eval_set=(frame.transform(val), y_val))
    return _assemble(frame, None, model)
