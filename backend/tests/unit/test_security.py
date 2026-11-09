import uuid
from datetime import UTC, datetime, timedelta

import jwt
import pytest

from app.core.config import Settings
from app.core.errors import UnauthorizedError
from app.core.security import (
    create_access_token,
    decode_access_token,
    generate_opaque_token,
    hash_password,
    hash_token,
    password_problem,
    verify_password,
)

SECRET = "unit-test-signing-key-0123456789-abcdefghijkl"


@pytest.fixture
def settings() -> Settings:
    return Settings(
        _env_file=None, env="test", database_url="postgresql+asyncpg://x@localhost/x_test", jwt_secret=SECRET
    )  # type: ignore[call-arg]


def test_password_hash_is_argon2id_and_verifies() -> None:
    hashed = hash_password("a long enough password")
    assert hashed.startswith("$argon2id$")
    assert verify_password("a long enough password", hashed)
    assert not verify_password("a different password", hashed)


def test_verify_password_without_hash_is_false() -> None:
    assert verify_password("anything at all", None) is False


@pytest.mark.parametrize(
    ("password", "email", "expected"),
    [
        ("short", None, "at least 8"),
        ("x" * 129, None, "at most 128"),
        ("Password123", None, "too common"),
        ("12345678", None, "too common"),
        ("somchai.rider", "Somchai.Rider@example.com", "e-mail name"),
        ("a perfectly fine passphrase", "rider@example.com", None),
    ],
)
def test_password_problem(password: str, email: str | None, expected: str | None) -> None:
    problem = password_problem(password, email)
    if expected is None:
        assert problem is None
    else:
        assert problem is not None and expected in problem


def test_opaque_tokens_are_random_and_hash_is_sha256() -> None:
    a, b = generate_opaque_token(), generate_opaque_token()
    assert a != b and len(a) >= 43  # 32 bytes urlsafe-b64
    assert len(hash_token(a)) == 64 and hash_token(a) == hash_token(a) != hash_token(b)


def test_access_token_round_trip(settings: Settings) -> None:
    user_id = uuid.uuid4()
    claims = decode_access_token(create_access_token(user_id, settings), settings)
    assert claims.user_id == user_id
    assert claims.expires_at - claims.issued_at == timedelta(minutes=15)


def test_expired_access_token(settings: Settings) -> None:
    past = datetime.now(UTC) - timedelta(minutes=16)
    token = create_access_token(uuid.uuid4(), settings, now=past)
    with pytest.raises(UnauthorizedError) as exc:
        decode_access_token(token, settings)
    assert exc.value.code == "token_expired"


def _encode(payload: dict, key: str = SECRET, algorithm: str = "HS256") -> str:
    return jwt.encode(payload, key, algorithm=algorithm)


def _valid_payload() -> dict:
    now = int(datetime.now(UTC).timestamp())
    return {"sub": str(uuid.uuid4()), "type": "access", "iat": now, "exp": now + 600, "jti": "j"}


@pytest.mark.parametrize(
    "token_factory",
    [
        pytest.param(
            lambda: _encode(_valid_payload(), key="another-secret-of-sufficient-length-xx"), id="bad-sig"
        ),
        pytest.param(lambda: _encode({**_valid_payload(), "type": "refresh"}), id="wrong-type"),
        pytest.param(lambda: _encode({k: v for k, v in _valid_payload().items() if k != "jti"}), id="no-jti"),
        pytest.param(lambda: _encode({**_valid_payload(), "sub": "not-a-uuid"}), id="bad-sub"),
        pytest.param(lambda: _encode(_valid_payload(), key=SECRET * 2, algorithm="HS512"), id="other-alg"),
        pytest.param(lambda: jwt.encode(_valid_payload(), None, algorithm="none"), id="alg-none"),
        pytest.param(lambda: "not.a.jwt", id="garbage"),
    ],
)
def test_forged_or_malformed_tokens_are_rejected(settings: Settings, token_factory) -> None:
    with pytest.raises(UnauthorizedError) as exc:
        decode_access_token(token_factory(), settings)
    assert exc.value.code == "invalid_token"
