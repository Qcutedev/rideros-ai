"""API latency benchmark on the local docker stack (Phase 6, P6b; results in docs/PERFORMANCE.md).

Seeds one throw-away rider through the public API (about six months of records), then sends N requests per
endpoint at concurrency 1 and 10 and reports p50/p95/p99. Latency is measured on the client, so it includes
localhost networking and reading the response. The rider is deleted at the end (DELETE /me) unless --keep.

The default rate limit (60/minute per user) would turn most of these requests into 429, so run the stack with
the perf override, which only sets RATE_LIMIT_ENABLED=false:

    docker compose -f docker-compose.yml -f backend/perf/compose.perf.yml up -d backend
    cd backend; python -m uv run python -m perf.run [--requests 200] [--out reports/perf_p6b.json]
    docker compose up -d backend        # back to the normal settings

Any 429 during the measured requests fails the run instead of being retried (it would hide the latency).
Seeding retries 429 with Retry-After, so seeding also works with the limiter on.
"""

import argparse
import asyncio
import itertools
import json
import platform
import random
import secrets
import statistics
import subprocess
import sys
import time
from collections import Counter
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import UTC, date, datetime, timedelta
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

import httpx

API = "/api/v1"
ZONE = ZoneInfo("Asia/Bangkok")
CENTER = (13.7563, 100.5018)  # lat, lng (Bangkok)
DAYS = 180
WARMUP = 10
COLD_PATTERN_SAMPLES = 5

# p95 targets from docs/HANDOFF.md §4.13 (decision 5). Auth has no target: Argon2 is slow on purpose.
TARGET_MS: dict[str, float | None] = {
    "crud": 300,
    "summary": 300,
    "prediction": 500,
    "patterns": 500,
    "auth": None,
}


@dataclass(frozen=True)
class Case:
    name: str
    group: str
    method: str
    path: str
    body: Callable[[int], Any] | None = None  # request index -> JSON body
    expect: int = 200
    auth: bool = True


@dataclass
class Seeded:
    email: str
    password: str
    counts: Counter[str] = field(default_factory=Counter)
    dataset_restaurant_id: str = ""
    dataset_query: str = ""
    own_restaurant_id: str = ""
    scenario_ids: list[str] = field(default_factory=list)
    historical_scenario_id: str = ""
    incident_id: str = ""
    session_spans: list[tuple[datetime, datetime]] = field(default_factory=list)


class Api:
    def __init__(self, client: httpx.AsyncClient) -> None:
        self.client = client

    async def call(self, method: str, path: str, *, expect: int = 200, **kwargs: Any) -> httpx.Response:
        """Seeding request: retries 429 (Retry-After), fails loudly on any other unexpected status."""
        for _ in range(20):
            response = await self.client.request(method, API + path, **kwargs)
            if response.status_code == 429:
                await asyncio.sleep(float(response.headers.get("Retry-After", "1")))
                continue
            if response.status_code != expect:
                raise RuntimeError(f"{method} {path} -> {response.status_code}: {response.text[:300]}")
            return response
        raise RuntimeError(f"{method} {path} still rate limited")

    async def login(self, email: str, password: str) -> None:
        self.client.headers.pop("Authorization", None)
        tokens = (await self.call("POST", "/auth/login", json={"email": email, "password": password})).json()
        self.client.headers["Authorization"] = f"Bearer {tokens['access_token']}"


def _local(day: date, hour: float) -> datetime:
    return datetime(day.year, day.month, day.day, tzinfo=ZONE) + timedelta(hours=hour)


async def seed(api: Api, rng: random.Random) -> Seeded:
    """About six months of a rider who works weekday evenings and weekend lunches."""
    data = Seeded(email=f"perf+{int(time.time())}@example.com", password=f"perf run {secrets.token_hex(8)}")
    await api.call(
        "POST",
        "/auth/register",
        expect=201,
        json={"email": data.email, "password": data.password, "display_name": "Perf Rider"},
    )
    await api.login(data.email, data.password)
    await api.call(
        "PUT",
        "/me/rider-profile",
        json={
            "vehicle_type": "motorcycle",
            "fuel_km_per_liter": "45",
            "fuel_price_per_liter": "38.50",
            "depreciation_per_km": "0.5",
        },
    )

    today = datetime.now(ZONE).date()
    for back in range(DAYS, 0, -1):
        day = today - timedelta(days=back)
        weekend = day.weekday() >= 5
        if rng.random() > (0.7 if weekend else 0.75):
            continue
        start_h = rng.gauss(10.5, 0.6) if weekend else rng.gauss(17.0, 0.7)
        hours = min(max(rng.gauss(5.0 if weekend else 4.0, 0.8), 1.0), 9.0)
        start = _local(day, start_h)
        end = start + timedelta(hours=hours)
        orders = max(1, round(hours * rng.uniform(1.8, 2.6)))
        km = round(orders * rng.uniform(3.0, 5.0), 1)
        session = (
            await api.call(
                "POST",
                "/work-sessions",
                expect=201,
                json={
                    "started_at": start.isoformat(),
                    "ended_at": end.isoformat(),
                    "distance_km": str(km),
                    "order_count": orders,
                },
            )
        ).json()
        data.session_spans.append((start, end))
        data.counts["work_sessions"] += 1
        await api.call(
            "POST",
            "/income",
            expect=201,
            json={
                "occurred_on": day.isoformat(),
                "amount": f"{orders * rng.uniform(38, 55):.2f}",
                "work_session_id": session["id"],
                "order_count": orders,
                "distance_km": str(km),
                "source_label": "perf",
            },
        )
        data.counts["income"] += 1
        if data.counts["work_sessions"] % 2 == 0:
            await api.call(
                "POST",
                "/expenses",
                expect=201,
                json={
                    "occurred_on": day.isoformat(),
                    "category": "fuel",
                    "amount": f"{km * 2 * 38.5 / 45:.2f}",
                    "work_session_id": session["id"],
                },
            )
            data.counts["expenses"] += 1
    for month in range(6):
        await api.call(
            "POST",
            "/expenses",
            expect=201,
            json={
                "occurred_on": (today - timedelta(days=30 * month + 3)).isoformat(),
                "category": "maintenance",
                "amount": "350.00",
            },
        )
        data.counts["expenses"] += 1

    own = (await api.call("POST", "/pickup/restaurants", expect=201, json={"name": "Perf Kitchen"})).json()
    data.own_restaurant_id = own["id"]
    for i in range(30):
        arrived = datetime.now(UTC) - timedelta(days=2 * i + 1, hours=rng.uniform(0, 6))
        await api.call(
            "POST",
            "/pickup/logs",
            expect=201,
            json={
                "restaurant_id": own["id"],
                "arrived_at": arrived.isoformat(),
                "picked_up_at": (arrived + timedelta(minutes=rng.uniform(2, 18))).isoformat(),
            },
        )
        data.counts["pickup_logs"] += 1

    page = (await api.call("GET", "/pickup/restaurants", params={"source": "dataset", "limit": 50})).json()
    restaurant = next(r for r in page["items"] if r["supports_prediction"])
    data.dataset_restaurant_id = restaurant["id"]
    data.dataset_query = restaurant["name"][:4]
    for _ in range(20):
        await api.call("POST", "/pickup/predictions", expect=201, json={"restaurant_id": restaurant["id"]})
        data.counts["pickup_predictions"] += 1

    for name, start, end in (("Evening", "17:00", "21:00"), ("Lunch", "10:30", "14:30")):
        scenario = (
            await api.call(
                "POST",
                "/shift-scenarios",
                expect=201,
                json={
                    "name": name,
                    "start_time": start,
                    "end_time": end,
                    "assumptions": {"orders_per_hour": "2.2", "income_per_order": "45", "km_per_order": "4"},
                },
            )
        ).json()
        data.scenario_ids.append(scenario["id"])
    historical = (
        await api.call(
            "POST",
            "/shift-scenarios",
            expect=201,
            json={
                "name": "History",
                "start_time": "17:00",
                "end_time": "21:00",
                "estimation_method": "historical",
            },
        )
    ).json()
    data.historical_scenario_id = historical["id"]
    data.scenario_ids.append(historical["id"])
    data.counts["shift_scenarios"] = len(data.scenario_ids)

    categories = ("flooding", "road_damage", "road_closure", "road_obstacle", "traffic_incident")
    for i, category in enumerate(categories):
        report = (
            await api.call(
                "POST",
                "/road/reports",
                expect=201,
                data={
                    "category": category,
                    "lat": str(CENTER[0] + 0.004 * i),
                    "lng": str(CENTER[1] - 0.003 * i),
                },
            )
        ).json()
        data.incident_id = data.incident_id or report["incident_id"]
        data.counts["road_reports"] += 1
    return data


def cases(s: Seeded) -> list[Case]:
    today = datetime.now(ZONE).date()
    lat, lng = CENTER
    bbox = f"{lng - 0.1},{lat - 0.1},{lng + 0.1},{lat + 0.1}"
    return [
        Case("GET /me", "crud", "GET", "/me"),
        Case("GET /work-sessions", "crud", "GET", "/work-sessions?limit=50"),
        Case("GET /income", "crud", "GET", "/income?limit=50"),
        Case("GET /expenses", "crud", "GET", "/expenses?limit=50"),
        Case("GET /pickup/restaurants?q=", "crud", "GET", f"/pickup/restaurants?q={s.dataset_query}"),
        Case(
            "GET /pickup/restaurants/{id}/analytics",
            "crud",
            "GET",
            f"/pickup/restaurants/{s.dataset_restaurant_id}/analytics",
        ),
        Case(
            "GET /pickup/restaurants/{id}/wait-stats",
            "crud",
            "GET",
            f"/pickup/restaurants/{s.own_restaurant_id}/wait-stats",
        ),
        Case("GET /pickup/predictions", "crud", "GET", "/pickup/predictions?limit=50"),
        Case("GET /pickup/logs", "crud", "GET", "/pickup/logs?limit=50"),
        Case("GET /shift-scenarios", "crud", "GET", "/shift-scenarios"),
        Case("GET /road/incidents?bbox=", "crud", "GET", f"/road/incidents?bbox={bbox}"),
        Case("GET /road/incidents/nearby", "crud", "GET", f"/road/incidents/nearby?lat={lat}&lng={lng}"),
        Case("GET /road/incidents/{id}", "crud", "GET", f"/road/incidents/{s.incident_id}"),
        Case("GET /road/reports", "crud", "GET", "/road/reports"),
        Case("GET /profit/summary?period=week", "summary", "GET", "/profit/summary?period=week"),
        Case("GET /profit/summary?period=month", "summary", "GET", "/profit/summary?period=month"),
        Case(
            "GET /profit/trends (90 days, day)",
            "summary",
            "GET",
            f"/profit/trends?granularity=day&from={today - timedelta(days=89)}&to={today}",
        ),
        Case(
            "GET /profit/trends (180 days, week)",
            "summary",
            "GET",
            f"/profit/trends?granularity=week&from={today - timedelta(days=179)}&to={today}",
        ),
        Case(
            "POST /shift-scenarios/{id}/estimate (historical)",
            "summary",
            "POST",
            f"/shift-scenarios/{s.historical_scenario_id}/estimate",
        ),
        Case(
            "POST /shift-scenarios/compare",
            "summary",
            "POST",
            "/shift-scenarios/compare",
            body=lambda _i: {"ids": s.scenario_ids},
        ),
        Case("GET /profit/patterns (cached)", "patterns", "GET", "/profit/patterns"),
        Case(
            "POST /pickup/predictions",
            "prediction",
            "POST",
            "/pickup/predictions",
            body=lambda _i: {"restaurant_id": s.dataset_restaurant_id},
            expect=201,
        ),
        Case(
            "POST /income",
            "crud",
            "POST",
            "/income",
            expect=201,
            body=lambda i: {
                "occurred_on": today.isoformat(),
                "amount": f"{100 + i % 50}.00",
                "source_label": "perf",
            },
        ),
        Case(
            "POST /auth/login",
            "auth",
            "POST",
            "/auth/login",
            auth=False,
            body=lambda _i: {"email": s.email, "password": s.password},
        ),
    ]


def summarize(latencies: list[float]) -> dict[str, float]:
    q = statistics.quantiles(latencies, n=100, method="inclusive")
    return {
        "p50_ms": round(q[49], 1),
        "p95_ms": round(q[94], 1),
        "p99_ms": round(q[98], 1),
        "mean_ms": round(statistics.fmean(latencies), 1),
        "max_ms": round(max(latencies), 1),
    }


async def measure(client: httpx.AsyncClient, case: Case, n: int, concurrency: int) -> dict[str, Any]:
    latencies: list[float] = []
    errors: Counter[str] = Counter()
    counter = itertools.count()
    headers = None if case.auth else {"Authorization": ""}

    async def worker() -> None:
        while (i := next(counter)) < n:
            body = case.body(i) if case.body else None
            started = time.perf_counter()
            try:
                response = await client.request(case.method, API + case.path, json=body, headers=headers)
            except httpx.HTTPError as exc:
                errors[type(exc).__name__] += 1
                continue
            elapsed = (time.perf_counter() - started) * 1000
            if response.status_code == case.expect:
                latencies.append(elapsed)
            else:
                errors[str(response.status_code)] += 1

    started = time.perf_counter()
    await asyncio.gather(*(worker() for _ in range(concurrency)))
    wall = time.perf_counter() - started
    result: dict[str, Any] = {"concurrency": concurrency, "ok": len(latencies), "errors": dict(errors)}
    result["throughput_rps"] = round(len(latencies) / wall, 1)
    if len(latencies) >= 2:
        result |= summarize(latencies)
    return result


async def cold_patterns(api: Api, s: Seeded) -> list[dict[str, Any]]:
    """First request after the rider's data changed: one new short session each time (cache miss).

    The cache (patterns.find_patterns_cached) is keyed by the session rows, not the user, and the seed is
    fixed, so an earlier run leaves the same rows cached. A random minute makes these rows new every run.
    """
    samples = []
    minute = secrets.randbelow(50)
    today = datetime.now(ZONE).date()
    for k in range(COLD_PATTERN_SAMPLES):
        start = _local(today - timedelta(days=3 + k), 3.0 + minute / 60)  # 03:xx, no seeded session there
        await api.call(
            "POST",
            "/work-sessions",
            expect=201,
            json={"started_at": start.isoformat(), "ended_at": (start + timedelta(minutes=45)).isoformat()},
        )
        started = time.perf_counter()
        response = await api.call("GET", "/profit/patterns")
        samples.append(
            {"ms": round((time.perf_counter() - started) * 1000, 1), "status": response.json().get("status")}
        )
    return samples


def machine() -> dict[str, Any]:
    info: dict[str, Any] = {
        "host_os": platform.platform(),
        "host_cpu": platform.processor(),
        "host_logical_cpus": __import__("os").cpu_count(),
        "client_python": sys.version.split()[0],
    }
    try:
        out = subprocess.run(
            ["docker", "info", "--format", "{{json .}}"],
            capture_output=True,
            text=True,
            timeout=30,
            check=True,
        ).stdout
        docker = json.loads(out)
        info["docker"] = {
            "server_version": docker.get("ServerVersion"),
            "os": docker.get("OperatingSystem"),
            "kernel": docker.get("KernelVersion"),
            "cpus": docker.get("NCPU"),
            "memory_gib": round(docker.get("MemTotal", 0) / 2**30, 1),
        }
    except (OSError, subprocess.SubprocessError, json.JSONDecodeError) as exc:
        info["docker"] = f"unavailable: {exc}"
    return info


def print_table(results: list[dict[str, Any]]) -> None:
    print("| Endpoint | Group | c | p50 | p95 | p99 | rps | target p95 | errors |")
    print("|---|---|---|---|---|---|---|---|---|")
    for r in results:
        target = TARGET_MS[r["group"]]
        verdict = (
            "—"
            if target is None
            else (f"< {target:g} ✅" if r.get("p95_ms", 1e9) < target else f"< {target:g} ❌")
        )
        print(
            f"| {r['name']} | {r['group']} | {r['concurrency']} | {r.get('p50_ms')} | {r.get('p95_ms')} | "
            f"{r.get('p99_ms')} | {r['throughput_rps']} | {verdict} | {r['errors'] or 0} |"
        )


async def run(args: argparse.Namespace) -> int:
    rng = random.Random(args.seed)
    async with httpx.AsyncClient(base_url=args.base_url, timeout=60) as client:
        api = Api(client)
        ready = (await client.get(API + "/ready")).json()
        print(f"ready: {ready}")
        seeded_at = time.perf_counter()
        s = await seed(api, rng)
        print(f"seeded {dict(s.counts)} in {time.perf_counter() - seeded_at:.0f} s as {s.email}")
        results: list[dict[str, Any]] = []
        failed = False
        try:
            for case in cases(s):
                await api.login(s.email, s.password)  # access tokens last 15 minutes
                for concurrency in args.concurrency:
                    await measure(client, case, WARMUP, 1)
                    result = {"name": case.name, "group": case.group, "method": case.method}
                    result |= await measure(client, case, args.requests, concurrency)
                    results.append(result)
                    print(
                        f"{case.name:<50} c={concurrency} p95 {result.get('p95_ms')} err={result['errors']}"
                    )
                    if result["errors"]:
                        failed = True
            await api.login(s.email, s.password)
            cold = await cold_patterns(api, s)
            print(f"patterns first request after a change: {cold}")
        finally:
            if args.keep:
                print(f"kept the perf rider {s.email} / {s.password}")
            else:
                await api.login(s.email, s.password)
                await api.call("DELETE", "/me", expect=204, json={"password": s.password})
                print("deleted the perf rider")

    print()
    print_table(results)
    report = {
        "generated_at": datetime.now(UTC).isoformat(timespec="seconds"),
        "base_url": args.base_url,
        "requests_per_case": args.requests,
        "warmup_per_case": WARMUP,
        "concurrency": args.concurrency,
        "rate_limit": "disabled for the run (backend/perf/compose.perf.yml)",
        "machine": machine(),
        "seeded": dict(s.counts),
        "targets_p95_ms": TARGET_MS,
        "results": results,
        "patterns_first_request": cold,
    }
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"\nwrote {args.out}")
    misses = [
        r
        for r in results
        if TARGET_MS[r["group"]] is not None and r.get("p95_ms", 1e9) >= TARGET_MS[r["group"]]
    ]
    if failed:
        print("FAILED: some requests did not return the expected status (429 -> start with compose.perf.yml)")
    if misses:
        print(f"over target: {[(r['name'], r['concurrency'], r.get('p95_ms')) for r in misses]}")
    return 1 if failed or misses else 0


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--base-url", default="http://127.0.0.1:8000")
    parser.add_argument(
        "--requests", type=int, default=200, help="measured requests per endpoint and concurrency"
    )
    parser.add_argument("--concurrency", type=int, nargs="+", default=[1, 10])
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--out", type=Path, default=None, help="JSON report, e.g. reports/perf_p6b.json")
    parser.add_argument("--keep", action="store_true", help="do not delete the perf rider")
    sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(asyncio.run(run(parser.parse_args())))


if __name__ == "__main__":
    main()
