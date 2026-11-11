from fastapi import APIRouter, Response, status

from app.core.deps import CurrentUser, SessionDep, SettingsDep
from app.modules.users import service
from app.modules.users.schemas import (
    DeleteAccountRequest,
    RiderProfileIn,
    RiderProfileOut,
    UserOut,
    UserUpdate,
)

router = APIRouter(prefix="/me", tags=["users"])


@router.get("", response_model=UserOut)
async def read_me(user: CurrentUser) -> UserOut:
    return UserOut.model_validate(user)


@router.patch("", response_model=UserOut)
async def update_me(body: UserUpdate, user: CurrentUser, session: SessionDep) -> UserOut:
    return UserOut.model_validate(await service.update_me(session, user, body))


@router.delete(
    "",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={403: {"description": "Password is incorrect (`invalid_password`)"}},
)
async def delete_me(
    body: DeleteAccountRequest, user: CurrentUser, session: SessionDep, settings: SettingsDep
) -> Response:
    """Deletes the account and all of the rider's data (PDPA). Requires the current password."""
    await service.delete_me(session, settings, user, body.password)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/rider-profile", response_model=RiderProfileOut)
async def read_rider_profile(user: CurrentUser, session: SessionDep) -> RiderProfileOut:
    return await service.get_rider_profile(session, user.id)


@router.put("/rider-profile", response_model=RiderProfileOut)
async def put_rider_profile(body: RiderProfileIn, user: CurrentUser, session: SessionDep) -> RiderProfileOut:
    return await service.put_rider_profile(session, user.id, body)
