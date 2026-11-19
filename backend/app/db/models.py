"""Import every ORM model here so `Base.metadata` is complete (used by Alembic and tests)."""

from app.db.base import Base
from app.modules.auth.models import PasswordResetToken, RefreshToken
from app.modules.profit.models import ExpenseRecord, IncomeRecord, WorkSession
from app.modules.shifts.models import ShiftScenario
from app.modules.users.models import RiderProfile, User

__all__ = [
    "Base",
    "ExpenseRecord",
    "IncomeRecord",
    "PasswordResetToken",
    "RefreshToken",
    "RiderProfile",
    "ShiftScenario",
    "User",
    "WorkSession",
]
