"""python -m training {download,build,train,evaluate}"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m training")
    sub = parser.add_subparsers(dest="command", required=True)
    dl = sub.add_parser("download", help="fetch RDD2022 + Flood10k, copy the AlleyFloodNet zip, verify pins")
    dl.add_argument("--alley", type=Path, help="AlleyFloodNet zip downloaded from Kaggle")
    dl.add_argument("--force", action="store_true")
    sub.add_parser("build", help="label, de-duplicate and split into data/interim")
    tr = sub.add_parser("train", help="fine-tune and export artifacts/road_cv/<version>")
    tr.add_argument("--version", default="1.0.0")
    tr.add_argument("--workers", type=int, default=4)
    ev = sub.add_parser("evaluate", help="test-split metrics -> reports/<version>")
    ev.add_argument("--version", default="1.0.0")
    args = parser.parse_args(argv)

    if args.command == "download":
        from training.download import download

        print(json.dumps(download(alley_zip=args.alley, force=args.force), indent=2))
    elif args.command == "build":
        from training.build import build

        print(json.dumps(build(), indent=2))
    elif args.command == "train":
        from training.train import TrainConfig, train

        train(TrainConfig(version=args.version, workers=args.workers))
    elif args.command == "evaluate":
        from training.evaluate import evaluate

        evaluate(args.version)
    return 0


if __name__ == "__main__":
    sys.exit(main())
