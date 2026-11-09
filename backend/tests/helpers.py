"""Shared helpers for API tests."""

import httpx

PASSWORD = "correct horse battery staple"


async def register(client: httpx.AsyncClient, email: str, password: str = PASSWORD) -> dict:
    resp = await client.post(
        "/auth/register", json={"email": email, "password": password, "display_name": email.split("@")[0]}
    )
    assert resp.status_code == 201, resp.text
    return resp.json()


async def login(client: httpx.AsyncClient, email: str, password: str = PASSWORD) -> dict:
    resp = await client.post("/auth/login", json={"email": email, "password": password})
    assert resp.status_code == 200, resp.text
    return resp.json()


def bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


async def auth_headers(client: httpx.AsyncClient, email: str) -> dict[str, str]:
    """Register + log in a fresh user and return its Authorization header."""
    await register(client, email)
    return bearer((await login(client, email))["access_token"])
