"""Command-line entry point: `uv run rideros-ml <command>`.

Order: download -> validate -> build -> eda -> train -> stats
"""

from __future__ import annotations

import argparse
import json
import sys

from rideros_ml.config import load_config
from rideros_ml.paths import PROCESSED_DIR, REPORTS_DIR, raw_dataset_dir


def cmd_hashes(cfg, _args) -> int:
    from rideros_ml.data.download import observed_hashes

    print(json.dumps(observed_hashes(cfg), indent=2))
    return 0


def cmd_download(cfg, args) -> int:
    from rideros_ml.data.download import download

    manifest = download(cfg, force=args.force)
    print(json.dumps(manifest, indent=2))
    return 0


def _load_manifest(cfg) -> dict:
    path = raw_dataset_dir(cfg.dataset.name) / "manifest.json"
    if not path.exists():
        raise SystemExit("manifest.json missing - run `rideros-ml download` first")
    return json.loads(path.read_text(encoding="utf-8"))


def cmd_validate(cfg, _args) -> int:
    from rideros_ml.data.build import TARGET, add_time_features, load_raw, picked_up_orders
    from rideros_ml.data.license_check import check_license_file
    from rideros_ml.data.validate import target_tail_profile, validate_waybills
    from rideros_ml.reporting import validation_markdown, write_json

    manifest = _load_manifest(cfg)
    raw_dir = raw_dataset_dir(cfg.dataset.name)
    license_checks = check_license_file(raw_dir / cfg.dataset.license_file)
    raw = load_raw(raw_dir / cfg.dataset.waybill_csv)
    report = validate_waybills(raw, cfg)

    tails = {}
    if report.ok:
        orders = add_time_features(picked_up_orders(raw), cfg.dataset.local_utc_offset_hours)
        tails = target_tail_profile(orders[orders["local_date"] <= cfg.split.train_last_date], TARGET)

    out = REPORTS_DIR / "data_validation"
    write_json(
        out / "validation.json",
        {**report.to_dict(), "license": [c.__dict__ for c in license_checks], "tails": tails},
    )
    (out / "VALIDATION_REPORT.md").write_text(
        validation_markdown(report, license_checks, manifest, tails), encoding="utf-8"
    )

    gate_ok = report.ok and all(c.present for c in license_checks)
    for c in report.checks:
        flag = "PASS" if c.passed else ("FAIL" if c.severity == "error" else "WARN")
        print(f"[{flag:4}] {c.name}: {c.detail}")
    for c in license_checks:
        print(f"[{'PASS' if c.present else 'FAIL':4}] license:{c.clause}")
    print("GATE:", "PASS" if gate_ok else "FAIL")
    return 0 if gate_ok else 2


def cmd_build(cfg, _args) -> int:
    from rideros_ml.data.build import build_orders, load_raw
    from rideros_ml.data.download import sha256_file
    from rideros_ml.reporting import write_json

    raw_csv = raw_dataset_dir(cfg.dataset.name) / cfg.dataset.waybill_csv
    validation = REPORTS_DIR / "data_validation" / "validation.json"
    if not validation.exists() or not json.loads(validation.read_text(encoding="utf-8"))["ok"]:
        raise SystemExit("validation gate has not passed - run `rideros-ml validate` first")
    orders, rule_info = build_orders(load_raw(raw_csv), cfg)
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    out = PROCESSED_DIR / "orders.parquet"
    orders.to_parquet(out, index=False)
    meta = {
        "rows": len(orders),
        "source_csv_sha256": sha256_file(raw_csv),
        "orders_parquet_sha256": sha256_file(out),
        "target_rule": rule_info,
    }
    write_json(PROCESSED_DIR / "orders.meta.json", meta)
    write_json(REPORTS_DIR / "data_validation" / "build_summary.json", meta)
    print(json.dumps(meta, indent=2))
    return 0


def cmd_eda(cfg, _args) -> int:
    from rideros_ml.eda.report import run_eda

    print(run_eda(cfg))
    return 0


def cmd_train(cfg, args) -> int:
    from rideros_ml.models.train import run_training

    print(run_training(cfg, quick=args.quick))
    return 0


def cmd_stats(cfg, _args) -> int:
    from rideros_ml.analytics.restaurant_stats import export_restaurant_stats

    print(export_restaurant_stats(cfg))
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="rideros-ml")
    parser.add_argument("--config", default=None, help="path to YAML config")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("hashes", help="download and print SHA-256 (bootstrap pins)")
    p = sub.add_parser("download", help="download + verify pinned dataset")
    p.add_argument("--force", action="store_true")
    sub.add_parser("validate", help="license + schema + quality gate")
    sub.add_parser("build", help="build order-level table")
    sub.add_parser("eda", help="EDA report on the train period")
    p = sub.add_parser("train", help="baselines, models, tuning, evaluation, export")
    p.add_argument(
        "--quick", action="store_true", help="tiny tuning budget (smoke test only, not for reporting)"
    )
    sub.add_parser("stats", help="export restaurant analytics aggregates")
    args = parser.parse_args(argv)

    from pathlib import Path

    cfg = load_config(Path(args.config) if args.config else None)
    handlers = {
        "hashes": cmd_hashes,
        "download": cmd_download,
        "validate": cmd_validate,
        "build": cmd_build,
        "eda": cmd_eda,
        "train": cmd_train,
        "stats": cmd_stats,
    }
    return handlers[args.command](cfg, args)


if __name__ == "__main__":
    sys.exit(main())
