from datetime import datetime
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, StringConstraints, field_validator

from app.core.security import PASSWORD_MAX_LENGTH

Email = Annotated[EmailStr, StringConstraints(max_length=254)]
# Length/strength rules live in security.password_problem so the message is domain-specific (400).
Password = Annotated[str, Field(min_length=1, max_length=PASSWORD_MAX_LENGTH * 2)]
OpaqueToken = Annotated[str, Field(min_length=16, max_length=256)]


class _Strict(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=False)


class RegisterRequest(_Strict):
    email: Email
    password: Password
    display_name: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=80)]

    @field_validator("email")
    @classmethod
    def _normalize_email(cls, value: str) -> str:
        return value.strip().lower()


class LoginRequest(_Strict):
    email: Email
    password: Password

    @field_validator("email")
    @classmethod
    def _normalize_email(cls, value: str) -> str:
        return value.strip().lower()


class RefreshRequest(_Strict):
    refresh_token: OpaqueToken


class LogoutRequest(_Strict):
    refresh_token: OpaqueToken


class ForgotPasswordRequest(_Strict):
    email: Email

    @field_validator("email")
    @classmethod
    def _normalize_email(cls, value: str) -> str:
        return value.strip().lower()


class ResetPasswordRequest(_Strict):
    token: OpaqueToken
    new_password: Password


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: Literal["bearer"] = "bearer"
    expires_in: int = Field(description="Access-token lifetime in seconds")
    refresh_expires_at: datetime


class AcceptedResponse(BaseModel):
    detail: str
