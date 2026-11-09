"""Write a versioned model artifact directory.

ml/artifacts/<model>/<version>/   (gitignored - Decision D4: never published until redistribution rights are verified)
  pipeline.joblib        full inference pipeline (FeatureFrame -> preprocessing -> model)
  preprocessor.joblib    preprocessing steps only (everything before the estimator)
  model.cbm | model.json native model file (portable, library-specific)
  feature_schema.json    input contract for the backend
  conformal.json         interval calibration
  metrics.json           validation + test results (from the actual run)
  metadata.json          versions, hashes, seed, config snapshot
  model_card.md

Security: joblib/pickle loading executes code. The backend must only load artifacts produced by this pipeline
and must verify sha256 of pipeline.joblib against metadata.json before loading.
"""

from __future__ import annotations

import json
import platform
import sys
from datetime import UTC, datetime
from importlib import metadata as importlib_metadata
from pathlib import Path

import joblib
from sklearn.pipeline import Pipeline

from rideros_ml.data.download import sha256_file
from rideros_ml.data.license_check import ACKNOWLEDGEMENT

LIBS = ["scikit-learn", "catboost", "xgboost", "pandas", "numpy", "joblib", "optuna"]


def library_versions() -> dict[str, str]:
    out = {"python": sys.version.split()[0], "platform": platform.platform()}
    for lib in LIBS:
        try:
            out[lib] = importlib_metadata.version(lib)
        except importlib_metadata.PackageNotFoundError:
            out[lib] = "not installed"
    return out


def feature_schema(model_name: str, version: str, columns: list[str], alpha: float) -> dict:
    descriptions = {
        "poi_id": (
            "string",
            "Meituan anonymized merchant id (dataset restaurants only). Unseen ids fall back to prior statistics.",
        ),
        "da_id": (
            "string",
            "Business district of the restaurant. Backend uses the POI's reference da_id from restaurant_reference.csv.",
        ),
        "hour": ("int", "Local hour of the request, 0-23."),
        "minute_sin": ("float", "sin(2*pi*minute_of_day/1440), minute_of_day = hour*60 + minute (local)."),
        "minute_cos": ("float", "cos(2*pi*minute_of_day/1440)."),
        "is_weekend": ("int", "1 if local weekday is Saturday or Sunday, else 0."),
    }
    return {
        "model": model_name,
        "version": version,
        "target": {
            "name": "order_to_pickup_min",
            "unit": "minutes",
            "definition": "minutes from order creation (platform_order_time) to rider pickup (fetch_time), non-prebook orders",
            "is_not": ["food preparation time", "rider waiting time at the restaurant"],
        },
        "inputs": [
            {"name": c, "dtype": descriptions[c][0], "description": descriptions[c][1]} for c in columns
        ],
        "builder": "rideros_ml.features.inference.make_feature_row(poi_id, da_id, local_time)",
        "output": {
            "predicted_minutes": "float",
            "interval": f"[low, high] split-conformal, nominal coverage {1 - alpha:.0%} (empirical coverage in metrics.json)",
        },
        "domain": "Meituan on-demand delivery, one Chinese city, 2022-10-16..24. Not representative of Thai restaurants.",
    }


def model_card(meta: dict, metrics: dict, schema: dict) -> str:
    sel = metrics["selected_model"]
    t = metrics["test"][sel]
    cov = metrics["conformal_test"]
    lines = [
        f"# Model Card - {meta['model']} {meta['version']}",
        "",
        "## Intended use",
        "Portfolio / educational demo of a leakage-safe regression pipeline. Predicts **order-to-pickup minutes** for "
        "restaurants that exist in the Meituan INFORMS TSL dataset. It is **not** a food-preparation-time model and "
        "**not** a rider-waiting-time model, and it must not be presented as valid for Thai restaurants.",
        "",
        "## Data",
        f"- Meituan INFORMS TSL Research Challenge, commit `{meta['data']['commit']}`, CC BY-NC 4.0, no redistribution.",
        f"- Acknowledgement: *{ACKNOWLEDGEMENT}*",
        f"- Split by local order date: train <= {meta['split']['train_last_date']}, validation = {meta['split']['val_date']}, "
        f"test = {meta['split']['test_date']}.",
        "",
        "## Inputs",
        *[f"- `{i['name']}` ({i['dtype']}): {i['description']}" for i in schema["inputs"]],
        "",
        "## Results (test day, evaluated once)",
        f"- Selected model (by validation MAE): **{sel}**",
        f"- MAE {t['mae']:.3f} min · RMSE {t['rmse']:.3f} · R² {t['r2']:.3f} · n = {t['n']:,}",
        f"- Prediction interval: nominal {1 - meta['conformal']['alpha']:.0%}, empirical test coverage "
        f"{cov['coverage']:.1%}, mean width {cov['mean_width']:.2f} min",
        "- Full comparison (baselines, Meituan platform estimate, all candidates): see metrics.json / RESULTS.md",
        "",
        "## Limitations",
        "- 8 days of data from one city in China; weekday effects cannot be learned (only `is_weekend`).",
        "- Target mixes restaurant preparation and rider arrival; the two cannot be separated with this dataset.",
        "- Restaurants with few training orders get weaker, prior-dominated predictions (see segment metrics).",
        "- Coordinates in the dataset are shifted for privacy; restaurant locations cannot be shown on a real map.",
        "- Not for commercial use (CC BY-NC 4.0). Artifact must not be redistributed.",
    ]
    return "\n".join(lines) + "\n"


def write_artifact(
    out_dir: Path, pipeline: Pipeline, meta: dict, metrics: dict, schema: dict, conformal: dict
) -> dict:
    out_dir.mkdir(parents=True, exist_ok=True)
    joblib.dump(pipeline, out_dir / "pipeline.joblib", compress=3)
    joblib.dump(Pipeline(pipeline.steps[:-1]), out_dir / "preprocessor.joblib", compress=3)
    model = pipeline.named_steps["model"]
    native = None
    if model.__class__.__name__ == "CatBoostRegressor":
        native = "model.cbm"
        model.save_model(str(out_dir / native))
    elif model.__class__.__name__ == "XGBRegressor":
        native = "model.json"
        model.save_model(str(out_dir / native))
    meta = {
        **meta,
        "created_at": datetime.now(UTC).isoformat(timespec="seconds"),
        "libraries": library_versions(),
        "files": {
            "pipeline.joblib": sha256_file(out_dir / "pipeline.joblib"),
            "preprocessor.joblib": sha256_file(out_dir / "preprocessor.joblib"),
            **({native: sha256_file(out_dir / native)} if native else {}),
        },
    }
    for name, obj in [
        ("feature_schema.json", schema),
        ("conformal.json", conformal),
        ("metrics.json", metrics),
        ("metadata.json", meta),
    ]:
        (out_dir / name).write_text(
            json.dumps(obj, indent=2, ensure_ascii=False, default=str), encoding="utf-8"
        )
    (out_dir / "model_card.md").write_text(model_card(meta, metrics, schema), encoding="utf-8")
    return meta
