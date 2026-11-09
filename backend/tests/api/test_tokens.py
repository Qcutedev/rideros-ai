"""Exit-criteria auth tests: expired / forged access tokens, refresh rotation + reuse, logout."""

import uuid
from datetime import UTC, datetime, timedelta

import httpx
import jwt
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.security import create_access_token, hash_token
from app.modules.auth.models import RefreshToken
from tests.helpers import bearer, login, register


async def _user_with_session(client: httpx.AsyncClient, email: str) -> tuple[dict, dict]:
    user = await register(client, email)
    return user, await login(client, email)


async def test_expired_access_token_is_rejected(client: httpx.AsyncClient, settings: Settings) -> None:
    user, _ = await _user_with_session(client, "exp@example.com")
    token = create_access_token(uuid.UUID(user["id"]), settings, now=datetime.now(UTC) - timedelta(hours=1))
    resp = await client.get("/me", headers=bearer(token))
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "token_expired"


async def test_forged_access_token_is_rejected(client: httpx.AsyncClient) -> None:
    user, _ = await _user_with_session(client, "forge@example.com")
    now = int(datetime.now(UTC).timestamp())
    payload = {"sub": user["id"], "type": "access", "iat": now, "exp": now + 600, "jti": "x"}
    forged = jwt.encode(payload, "attacker-guessed-secret-that-is-long-enough", algorithm="HS256")
    resp = await client.get("/me", headers=bearer(forged))
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "invalid_token"


async def test_access_token_for_unknown_user_is_rejected(
    client: httpx.AsyncClient, settings: Settings
) -> None:
    resp = await client.get("/me", headers=bearer(create_access_token(uuid.uuid4(), settings)))
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "invalid_token"


async def test_refresh_rotates_tokens(client: httpx.AsyncClient, db: AsyncSession) -> None:
    _, pair = await _user_with_session(client, "rotate@example.com")
    resp = await client.post("/auth/refresh", json={"refresh_token": pair["refresh_token"]})
    assert resp.status_code == 200
    new = resp.json()
    assert new["refresh_token"] != pair["refresh_token"]
    assert (await client.get("/me", headers=bearer(new["access_token"]))).status_code == 200

    old_row = (
        await db.execute(
            select(RefreshToken).where(RefreshToken.token_hash == hash_token(pair["refresh_token"]))
        )
    ).scalar_one()
    new_row = (
        await db.execute(
            select(RefreshToken).where(RefreshToken.token_hash == hash_token(new["refresh_token"]))
        )
    ).scalar_one()
    assert old_row.revoked_at is not None
    assert new_row.revoked_at is None and new_row.family_id == old_row.family_id


async def test_refresh_tokens_are_stored_hashed(client: httpx.AsyncClient, db: AsyncSession) -> None:
    _, pair = await _user_with_session(client, "hashed@example.com")
    stored = (await db.execute(select(RefreshToken.token_hash))).scalars().all()
    assert pair["refresh_token"] not in stored
    assert hash_token(pair["refresh_token"]) in stored


async def test_refresh_reuse_revokes_whole_family(client: httpx.AsyncClient) -> None:
    _, pair = await _user_with_session(client, "reuse@example.com")
    first = await client.post("/auth/refresh", json={"refresh_token": pair["refresh_token"]})
    rotated = first.json()["refresh_token"]

    # The old token is replayed (e.g. stolen) -> rejected and the family is killed.
    replay = await client.post("/auth/refresh", json={"refresh_token": pair["refresh_token"]})
    assert replay.status_code == 401
    assert replay.json()["error"]["code"] == "refresh_token_revoked"

    # The legitimately rotated token no longer works either.
    after = await client.post("/auth/refresh", json={"refresh_token": rotated})
    assert after.status_code == 401
    assert after.json()["error"]["code"] == "refresh_token_revoked"


async def test_reuse_in_one_session_does_not_touch_other_sessions(client: httpx.AsyncClient) -> None:
    _, phone = await _user_with_session(client, "two@example.com")
    tablet = await login(client, "two@example.com")
    await client.post("/auth/refresh", json={"refresh_token": phone["refresh_token"]})
    await client.post("/auth/refresh", json={"refresh_token": phone["refresh_token"]})  # reuse
    resp = await client.post("/auth/refresh", json={"refresh_token": tablet["refresh_token"]})
    assert resp.status_code == 200


async def test_expired_refresh_token_is_rejected(client: httpx.AsyncClient, db: AsyncSession) -> None:
    _, pair = await _user_with_session(client, "oldrefresh@example.com")
    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.token_hash == hash_token(pair["refresh_token"]))
        .values(expires_at=datetime.now(UTC) - timedelta(seconds=1))
    )
    await db.commit()
    resp = await client.post("/auth/refresh", json={"refresh_token": pair["refresh_token"]})
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "refresh_token_expired"


async def test_unknown_refresh_token_is_rejected(client: httpx.AsyncClient) -> None:
    resp = await client.post("/auth/refresh", json={"refresh_token": "x" * 43})
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "invalid_refresh_token"


async def test_refresh_for_deactivated_user_is_rejected(client: httpx.AsyncClient, db: AsyncSession) -> None:
    from app.modules.users.models import User

    _, pair = await _user_with_session(client, "deact@example.com")
    await db.execute(update(User).where(User.email == "deact@example.com").values(is_active=False))
    await db.commit()
    resp = await client.post("/auth/refresh", json={"refresh_token": pair["refresh_token"]})
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "invalid_refresh_token"


async def test_logout_revokes_the_session(client: httpx.AsyncClient) -> None:
    _, pair = await _user_with_session(client, "logout@example.com")
    resp = await client.post("/auth/logout", json={"refresh_token": pair["refresh_token"]})
    assert resp.status_code == 204 and resp.content == b""
    again = await client.post("/auth/refresh", json={"refresh_token": pair["refresh_token"]})
    assert again.status_code == 401
    assert again.json()["error"]["code"] == "refresh_token_revoked"


async def test_logout_revokes_tokens_rotated_from_the_same_login(client: httpx.AsyncClient) -> None:
    _, pair = await _user_with_session(client, "logout2@example.com")
    rotated = (await client.post("/auth/refresh", json={"refresh_token": pair["refresh_token"]})).json()
    await client.post("/auth/logout", json={"refresh_token": rotated["refresh_token"]})
    resp = await client.post("/auth/refresh", json={"refresh_token": rotated["refresh_token"]})
    assert resp.status_code == 401


async def test_logout_keeps_other_sessions(client: httpx.AsyncClient) -> None:
    _, phone = await _user_with_session(client, "multi@example.com")
    tablet = await login(client, "multi@example.com")
    await client.post("/auth/logout", json={"refresh_token": phone["refresh_token"]})
    resp = await client.post("/auth/refresh", json={"refresh_token": tablet["refresh_token"]})
    assert resp.status_code == 200


async def test_logout_is_idempotent_and_hides_unknown_tokens(client: httpx.AsyncClient) -> None:
    _, pair = await _user_with_session(client, "idem@example.com")
    for token in (pair["refresh_token"], pair["refresh_token"], "y" * 43):
        resp = await client.post("/auth/logout", json={"refresh_token": token})
        assert resp.status_code == 204
