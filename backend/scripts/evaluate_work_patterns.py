"""Benchmark of the K-Means work patterns (app/modules/profit/patterns.py) on synthetic riders.

There is no labelled rider data, so the method is checked on generated sessions whose true groups
are known. These are not accuracy figures for real riders. They show two things: how often the
method invents a pattern that is not there, and how often it finds a planted one.

    uv run python -m scripts.evaluate_work_patterns [--reps 30] [--out reports/work_patterns.json]
"""

import argparse
import json
import random
import statistics
import time
from collections.abc import Callable
from datetime import datetime, timedelta
from decimal import Decimal
from pathlib import Path
from zoneinfo import ZoneInfo

from sklearn.metrics import adjusted_rand_score

from app.modules.profit.patterns import SessionRow, find_patterns

ZONE = ZoneInfo("Asia/Bangkok")
FIRST_DAY = datetime(2026, 5, 1, tzinfo=ZONE)
DAYS = 180

# (start hour mean, sd), (length h mean, sd), weekend probability
type Habit = tuple[tuple[float, float], tuple[float, float], float]
type Scenario = tuple[str, bool, int, Callable[[random.Random, int], list[tuple[SessionRow, int]]]]


def _day(rng: random.Random, weekend_p: float) -> int:
    want_weekend = rng.random() < weekend_p
    while True:
        d = rng.randrange(DAYS)
        if ((FIRST_DAY + timedelta(days=d)).weekday() >= 5) == want_weekend:
            return d


def _session(rng: random.Random, habit: Habit) -> SessionRow:
    (h_mu, h_sd), (l_mu, l_sd), weekend_p = habit
    start = FIRST_DAY + timedelta(days=_day(rng, weekend_p), hours=rng.gauss(h_mu, h_sd) % 24)
    hours = min(max(rng.gauss(l_mu, l_sd), 0.5), 14)
    return SessionRow(start, start + timedelta(hours=hours), Decimal(round(hours * 110)), Decimal(40), 1)


def planted(*habits: tuple[Habit, float]) -> Callable[[random.Random, int], list[tuple[SessionRow, int]]]:
    def make(rng: random.Random, n: int) -> list[tuple[SessionRow, int]]:
        out = []
        for label, (habit, share) in enumerate(habits):
            out += [(_session(rng, habit), label) for _ in range(round(n * share))]
        return out

    return make


def uniform(rng: random.Random, n: int) -> list[tuple[SessionRow, int]]:
    out = []
    for _ in range(n):
        start = FIRST_DAY + timedelta(days=rng.randrange(DAYS), hours=rng.uniform(0, 24))
        hours = rng.uniform(1, 12)
        out.append((SessionRow(start, start + timedelta(hours=hours), Decimal(500), Decimal(40), 1), 0))
    return out


EVENING_WEEKDAY: Habit = ((18.5, 0.8), (3.0, 0.7), 0.1)
WEEKEND_LONG: Habit = ((9.0, 1.0), (9.0, 1.2), 0.9)
LUNCH_WEEKDAY: Habit = ((11.0, 0.6), (2.5, 0.5), 0.0)
LATE_NIGHT: Habit = ((23.5, 1.0), (4.0, 0.8), 0.3)  # wraps past midnight
NOISY_EVENING: Habit = ((18.0, 1.8), (4.0, 1.5), 0.2)
NOISY_DAYTIME: Habit = ((10.0, 1.8), (7.5, 1.5), 0.8)

SCENARIOS: list[Scenario] = [
    # name, has a real pattern, true k, generator
    ("uniform random", False, 1, uniform),
    ("one habit (evening, every day)", False, 1, planted((((18.5, 1.5), (3.5, 1.0), 2 / 7), 1.0))),
    ("2 groups clear", True, 2, planted((EVENING_WEEKDAY, 0.6), (WEEKEND_LONG, 0.4))),
    ("2 groups noisy", True, 2, planted((NOISY_EVENING, 0.6), (NOISY_DAYTIME, 0.4))),
    ("3 groups", True, 3, planted((EVENING_WEEKDAY, 0.45), (WEEKEND_LONG, 0.3), (LUNCH_WEEKDAY, 0.25))),
    ("night across midnight + lunch", True, 2, planted((LATE_NIGHT, 0.5), (LUNCH_WEEKDAY, 0.5))),
]
SIZES = (30, 60, 150)


def run(reps: int) -> dict:
    results = []
    for name, has_pattern, true_k, make in SCENARIOS:
        for n in SIZES:
            found = right_k = 0
            aris, times = [], []
            for rep in range(reps):
                rows = make(random.Random(f"{name}/{n}/{rep}"), n)
                start = time.perf_counter()
                result = find_patterns([r for r, _ in rows], ZONE)
                times.append(time.perf_counter() - start)
                if result.status != "ok":
                    continue
                found += 1
                if has_pattern:
                    right_k += result.k == true_k
                    aris.append(adjusted_rand_score([t for _, t in rows], result.labels))
            row = {
                "scenario": name,
                "has_pattern": has_pattern,
                "sessions": n,
                "reps": reps,
                "shown_rate": round(found / reps, 3),
                "median_ms": round(statistics.median(times) * 1000, 1),
            }
            if has_pattern:
                row["correct_k_rate"] = round(right_k / reps, 3)
                row["mean_ari_when_shown"] = round(statistics.mean(aris), 3) if aris else None
            results.append(row)
            print(row, flush=True)
    null_rows = [r for r in results if not r["has_pattern"]]
    real_rows = [r for r in results if r["has_pattern"]]
    return {
        "method": "app/modules/profit/patterns.py",
        "note": "Synthetic riders with known groups; not accuracy on real riders.",
        "false_pattern_rate": round(statistics.mean(r["shown_rate"] for r in null_rows), 3),
        "detection_rate": round(statistics.mean(r["shown_rate"] for r in real_rows), 3),
        "correct_k_rate": round(statistics.mean(r["correct_k_rate"] for r in real_rows), 3),
        "results": results,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reps", type=int, default=30)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    report = run(args.reps)
    print({k: v for k, v in report.items() if k != "results"})
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
