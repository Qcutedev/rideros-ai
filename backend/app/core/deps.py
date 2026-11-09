"""Shared FastAPI dependencies: settings, DB session, current user."""

from typing import Annotated

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.errors import UnauthorizedError
from app.core.security import decode_access_token
from app.db.session import get_session
from app.modules.users import repository as users
from app.modules.users.models import User

_bearer = HTTPBearer(auto_error=False)


def get_app_settings(request: Request) -> Settings:
    return request.app.state.settings


SettingsDep = Annotated[Settings, Depends(get_app_settings)]
SessionDep = Annotated[AsyncSession, Depends(get_session)]


async def get_current_user(
    session: SessionDep,
    settings: SettingsDep,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise UnauthorizedError("Missing bearer token", code="not_authenticated")
    claims = decode_access_token(credentials.credentials, settings)
    user = await users.get_by_id(session, claims.user_id)
    if user is None or not user.is_active:
        raise UnauthorizedError("Invalid access token", code="invalid_token")
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]
