"""Optuna hyperparameter search. Objective = MAE on the VALIDATION day. The test day is never touched here."""

from __future__ import annotations

import optuna

from rideros_ml.models.candidates import fit_catboost, fit_xgboost
from rideros_ml.models.metrics import regression_metrics


def _xgb_space(trial: optuna.Trial) -> dict:
    return {
        "learning_rate": trial.suggest_float("learning_rate", 0.03, 0.3, log=True),
        "max_depth": trial.suggest_int("max_depth", 4, 10),
        "min_child_weight": trial.suggest_float("min_child_weight", 1.0, 50.0, log=True),
        "subsample": trial.suggest_float("subsample", 0.6, 1.0),
        "colsample_bytree": trial.suggest_float("colsample_bytree", 0.6, 1.0),
        "reg_lambda": trial.suggest_float("reg_lambda", 1e-3, 10.0, log=True),
    }


def _cat_space(trial: optuna.Trial) -> dict:
    return {
        "learning_rate": trial.suggest_float("learning_rate", 0.05, 0.3, log=True),
        "depth": trial.suggest_int("depth", 4, 8),
        "l2_leaf_reg": trial.suggest_float("l2_leaf_reg", 1.0, 20.0, log=True),
        "bagging_temperature": trial.suggest_float("bagging_temperature", 0.0, 1.0),
    }


def tune(kind: str, train, y, val, y_val, columns, seed: int, n_trials: int, timeout_s: int | None) -> dict:
    fit, space = {"xgboost": (fit_xgboost, _xgb_space), "catboost": (fit_catboost, _cat_space)}[kind]

    def objective(trial: optuna.Trial) -> float:
        params = space(trial)
        pipe = fit(train, y, val, y_val, columns, seed, params)
        mae = regression_metrics(y_val, pipe.predict(val))["mae"]
        best_iter = getattr(pipe.named_steps["model"], "best_iteration_", None)
        if best_iter is None:
            best_iter = getattr(pipe.named_steps["model"], "best_iteration", None)
        trial.set_user_attr("best_iteration", int(best_iter) if best_iter is not None else None)
        return mae

    optuna.logging.set_verbosity(optuna.logging.WARNING)
    study = optuna.create_study(direction="minimize", sampler=optuna.samplers.TPESampler(seed=seed))
    study.optimize(objective, n_trials=n_trials, timeout=timeout_s)
    return {
        "best_params": study.best_params,
        "best_val_mae": study.best_value,
        "n_trials_completed": len(study.trials),
        "trials": [
            {"number": t.number, "params": t.params, "val_mae": t.value, **t.user_attrs}
            for t in study.trials
        ],
    }
