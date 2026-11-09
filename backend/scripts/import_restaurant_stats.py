"""Import restaurant aggregates exported by the ML pipeline.

    python -m scripts.import_restaurant_stats <ml/artifacts/restaurant_stats/1.0.0> [--if-empty]

Uses DATABASE_URL. In docker the backend runs it on start when RESTAURANT_STATS_DIR is set.
"""

import argparse
import asyncio
import sys
from pathlib import Path

from app.core.config import get_settings
from app.db.session import create_engine, create_session_factory
from app.modules.pickup.importer import ImportFormatError, import_restaurant_stats


async def _main(folder: Path, if_empty: bool) -> int:
    engine = create_engine(get_settings())
    try:
        async with create_session_factory(engine)() as session:
            result = await import_restaurant_stats(session, folder, if_empty=if_empty)
    finally:
        await engine.dispose()
    if result.skipped:
        print(f"restaurant stats already imported; skipped ({result.dataset_version})")
    else:
        counts = f"{result.restaurants} restaurants, {result.time_cells} time cells"
        print(f"imported {counts} ({result.dataset_version})")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("folder", type=Path)
    parser.add_argument("--if-empty", action="store_true", help="do nothing if dataset restaurants exist")
    args = parser.parse_args()
    if not (args.folder / "summary.json").is_file():
        print(f"{args.folder}: summary.json not found", file=sys.stderr)
        return 2
    try:
        return asyncio.run(_main(args.folder, args.if_empty))
    except ImportFormatError as exc:
        print(f"import failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
