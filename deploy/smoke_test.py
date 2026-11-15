"""Smoke test of a running RiderOS AI API (docs/DEPLOYMENT.md §Smoke test). Standard library only, so
it runs on the server (python3) as well as on a laptop.

    python3 deploy/smoke_test.py https://api.203-0-113-7.sslip.io
    python deploy/smoke_test.py https://localhost --insecure      # local stack, Caddy's own CA

It creates a throw-away account (smoke+<timestamp>@example.com), walks the main features once, checks
the production switches (no /docs, password reset off), and deletes the account again with
DELETE /me, even when a step fails. Exit code 0 = all checks passed.
"""

import argparse
import datetime as dt
import json
import secrets
import ssl
import struct
import sys
import time
import urllib.error
import urllib.request
import uuid
import zlib
from typing import Any


class Api:
    def __init__(self, base: str, insecure: bool) -> None:
        self.base = base.rstrip("/") + "/api/v1"
        self.root = base.rstrip("/")
        self.ctx = ssl._create_unverified_context() if insecure else ssl.create_default_context()  # noqa: S323
        self.token: str | None = None

    def call(
        self,
        method: str,
        path: str,
        body: Any = None,
        *,
        multipart: dict[str, Any] | None = None,
        absolute: bool = False,
    ) -> tuple[int, Any]:
        url = (self.root if absolute else self.base) + path
        headers = {"Accept": "application/json", "User-Agent": "rideros-smoke-test"}
        data: bytes | None = None
        if multipart is not None:
            boundary = uuid.uuid4().hex
            data = _multipart(multipart, boundary)
            headers["Content-Type"] = f"multipart/form-data; boundary={boundary}"
        elif body is not None:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        for attempt in range(6):  # the API allows 60 requests/minute per user; wait out a 429
            request = urllib.request.Request(url, data=data, headers=headers, method=method)  # noqa: S310
            try:
                with urllib.request.urlopen(request, context=self.ctx, timeout=30) as resp:  # noqa: S310
                    return resp.status, _json(resp.read())
            except urllib.error.HTTPError as err:
                if err.code == 429 and attempt < 5:
                    time.sleep(int(err.headers.get("Retry-After", "5")))
                    continue
                return err.code, _json(err.read())
        raise AssertionError("unreachable")


def _json(raw: bytes) -> Any:
    try:
        return json.loads(raw) if raw else None
    except ValueError:
        return raw.decode(errors="replace")[:200]


def _multipart(fields: dict[str, Any], boundary: str) -> bytes:
    out = b""
    for name, value in fields.items():
        out += f"--{boundary}\r\n".encode()
        if isinstance(value, bytes):  # the photo
            out += f'Content-Disposition: form-data; name="{name}"; filename="smoke.png"\r\n'.encode()
            out += b"Content-Type: image/png\r\n\r\n" + value + b"\r\n"
        else:
            out += f'Content-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'.encode()
    return out + f"--{boundary}--\r\n".encode()


def _png(width: int = 64, height: int = 64) -> bytes:
    """A small grey gradient PNG (no image library on the server)."""
    rows = b"".join(
        b"\x00" + bytes((x * 4 + y) % 256 for x in range(width) for _ in range(3)) for y in range(height)
    )

    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (
            struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload))
        )

    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(rows))
        + chunk(b"IEND", b"")
    )


class Checks:
    def __init__(self) -> None:
        self.failed = 0

    def expect(self, name: str, ok: bool, detail: Any = "") -> bool:
        print(f"{'PASS' if ok else 'FAIL'}  {name}" + ("" if ok else f"  -> {str(detail)[:300]}"))
        self.failed += 0 if ok else 1
        return ok


def run(api: Api, production: bool) -> int:
    c = Checks()
    status, body = api.call("GET", "/ready")
    c.expect("GET /ready is ok", status == 200 and body.get("status") == "ok", body)
    if production:
        status, _ = api.call("GET", "/docs", absolute=True)
        c.expect("/docs is off", status == 404, status)
        status, _ = api.call("GET", "/openapi.json", absolute=True)
        c.expect("/openapi.json is off", status == 404, status)
        status, body = api.call("POST", "/auth/forgot-password", {"email": "nobody@example.com"})
        c.expect("password reset is off (D5)", status == 503, body)

    email = f"smoke+{int(time.time())}@example.com"
    password = "smoke " + secrets.token_urlsafe(12)
    status, body = api.call(
        "POST", "/auth/register", {"email": email, "password": password, "display_name": "Smoke"}
    )
    if not c.expect("register", status == 201, body):
        return 1
    try:
        status, body = api.call("POST", "/auth/login", {"email": email, "password": password})
        if not c.expect("login", status == 200, body):
            return 1
        api.token = body["access_token"]
        status, body = api.call("GET", "/me")
        c.expect("GET /me", status == 200 and body.get("email") == email, body)

        today = dt.date.today().isoformat()
        status, body = api.call("POST", "/income", {"occurred_on": today, "amount": "123.45"})
        c.expect("POST /income", status == 201, body)
        status, body = api.call("GET", "/profit/summary?period=week")
        c.expect("GET /profit/summary", status == 200, body)

        status, body = api.call("GET", "/pickup/restaurants?source=dataset&limit=1")
        items = body.get("items", []) if isinstance(body, dict) else []
        if c.expect("dataset restaurants are imported", status == 200 and len(items) == 1, body):
            status, body = api.call("POST", "/pickup/predictions", {"restaurant_id": items[0]["id"]})
            c.expect("pickup prediction (model)", status == 201, body)

        status, body = api.call(
            "POST",
            "/road/reports",
            multipart={"category": "road_obstacle", "lat": "13.7563", "lng": "100.5018", "image": _png()},
        )
        if c.expect("road report with photo", status == 201, body):
            report_id = body["report_id"]
            ai_status = "pending"
            deadline = time.monotonic() + 90
            while ai_status == "pending" and time.monotonic() < deadline:
                time.sleep(2)
                _, reports = api.call("GET", "/road/reports")
                mine = [r for r in (reports or {}).get("items", []) if r.get("id") == report_id]
                ai_status = mine[0]["ai_status"] if mine else "missing"
            c.expect("photo classified by cv_service", ai_status == "done", ai_status)
    finally:
        status, body = api.call("DELETE", "/me", {"password": password})
        c.expect("DELETE /me (clean-up)", status == 204, body)
        api.token = None
        status, _ = api.call("POST", "/auth/login", {"email": email, "password": password})
        c.expect("deleted account cannot log in", status == 401, status)

    print("SMOKE TEST PASSED" if c.failed == 0 else f"SMOKE TEST FAILED ({c.failed} check(s))")
    return 0 if c.failed == 0 else 1


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("base_url", help="e.g. https://api.203-0-113-7.sslip.io")
    parser.add_argument("--insecure", action="store_true", help="skip TLS verification (local Caddy CA)")
    parser.add_argument("--dev", action="store_true", help="development server: skip the production checks")
    args = parser.parse_args()
    return run(Api(args.base_url, args.insecure), production=not args.dev)


if __name__ == "__main__":
    sys.exit(main())
