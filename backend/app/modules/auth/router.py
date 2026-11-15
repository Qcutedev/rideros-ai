from fastapi import APIRouter, Depends, Request, Response, status

from app.core.deps import SessionDep, SettingsDep
from app.core.rate_limit import default_limit, get_limiter, per_ip
from app.modules.auth import service
from app.modules.auth.schemas import (
    AcceptedResponse,
    ForgotPasswordRequest,
    LoginRequest,
    LogoutRequest,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    TokenPair,
)
from app.modules.users.schemas import UserOut

router = APIRouter(prefix="/auth", tags=["auth"])

_FORGOT_ACCEPTED = "If an account exists for this e-mail, a reset link has been sent."


@router.post(
    "/register",
    status_code=status.HTTP_201_CREATED,
    response_model=UserOut,
    dependencies=[Depends(per_ip("register", "rate_limit_register"))],
)
async def register(body: RegisterRequest, session: SessionDep) -> UserOut:
    user = await service.register(
        session, email=body.email, password=body.password, display_name=body.display_name
    )
    return UserOut.model_validate(user)


@router.post("/login", response_model=TokenPair, dependencies=[Depends(per_ip("login", "rate_limit_login"))])
async def login(
    body: LoginRequest, request: Request, session: SessionDep, settings: SettingsDep
) -> TokenPair:
    # Also per e-mail, so a password-guessing run spread over many IPs is still slowed down.
    await get_limiter(request).hit(settings.rate_limit_login, "login_email", body.email)
    return await service.login(session, email=body.email, password=body.password, settings=settings)


@router.post("/refresh", response_model=TokenPair, dependencies=[Depends(default_limit)])
async def refresh(body: RefreshRequest, session: SessionDep, settings: SettingsDep) -> TokenPair:
    return await service.refresh(session, refresh_token=body.refresh_token, settings=settings)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(default_limit)])
async def logout(body: LogoutRequest, session: SessionDep) -> Response:
    await service.logout(session, refresh_token=body.refresh_token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/forgot-password",
    status_code=status.HTTP_202_ACCEPTED,
    response_model=AcceptedResponse,
    dependencies=[Depends(per_ip("forgot_password", "rate_limit_password_reset"))],
)
async def forgot_password(
    body: ForgotPasswordRequest, request: Request, session: SessionDep, settings: SettingsDep
) -> AcceptedResponse:
    await get_limiter(request).hit(settings.rate_limit_password_reset, "forgot_password_email", body.email)
    await service.forgot_password(session, email=body.email, settings=settings)
    return AcceptedResponse(detail=_FORGOT_ACCEPTED)


@router.post(
    "/reset-password",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(per_ip("reset_password", "rate_limit_password_reset"))],
)
async def reset_password(body: ResetPasswordRequest, session: SessionDep, settings: SettingsDep) -> Response:
    await service.reset_password(session, token=body.token, new_password=body.new_password, settings=settings)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
