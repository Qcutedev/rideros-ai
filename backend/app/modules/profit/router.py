"""TrueProfit HTTP API: /work-sessions, /income, /expenses, /profit/summary, /profit/trends."""

import uuid
from datetime import date
from typing import Annotated

from fastapi import APIRouter, Query, Response, status

from app.core.deps import CurrentUser, SessionDep
from app.core.pagination import DEFAULT_PAGE_SIZE, CursorQuery, LimitQuery, Page
from app.modules.profit import service
from app.modules.profit.schemas import (
    ExpenseCategory,
    ExpenseCreate,
    ExpenseOut,
    ExpenseUpdate,
    IncomeCreate,
    IncomeOut,
    IncomeUpdate,
    Period,
    ProfitSummary,
    ProfitTrends,
    WorkSessionCreate,
    WorkSessionOut,
    WorkSessionUpdate,
)

FromQuery = Annotated[date | None, Query(alias="from", description="First local date (inclusive)")]
ToQuery = Annotated[date | None, Query(alias="to", description="Last local date (inclusive)")]

_NOT_FOUND = {404: {"description": "Not found, or owned by another user"}}

router = APIRouter()

# ---- work sessions ----

sessions = APIRouter(prefix="/work-sessions", tags=["trueprofit"])


@sessions.get("", response_model=Page[WorkSessionOut])
async def list_work_sessions(
    user: CurrentUser,
    session: SessionDep,
    date_from: FromQuery = None,
    date_to: ToQuery = None,
    limit: LimitQuery = DEFAULT_PAGE_SIZE,
    cursor: CursorQuery = None,
) -> Page[WorkSessionOut]:
    """Newest first. `from`/`to` filter on the local date of `started_at`."""
    return await service.list_work_sessions(
        session, user.id, date_from=date_from, date_to=date_to, cursor=cursor, limit=limit
    )


@sessions.post("", status_code=status.HTTP_201_CREATED, response_model=WorkSessionOut)
async def create_work_session(
    body: WorkSessionCreate, user: CurrentUser, session: SessionDep
) -> WorkSessionOut:
    return await service.create_work_session(session, user.id, body)


@sessions.get("/{session_id}", response_model=WorkSessionOut, responses=_NOT_FOUND)
async def get_work_session(session_id: uuid.UUID, user: CurrentUser, session: SessionDep) -> WorkSessionOut:
    return await service.get_work_session(session, user.id, session_id)


@sessions.patch("/{session_id}", response_model=WorkSessionOut, responses=_NOT_FOUND)
async def update_work_session(
    session_id: uuid.UUID, body: WorkSessionUpdate, user: CurrentUser, session: SessionDep
) -> WorkSessionOut:
    return await service.update_work_session(session, user.id, session_id, body)


@sessions.delete("/{session_id}", status_code=status.HTTP_204_NO_CONTENT, responses=_NOT_FOUND)
async def delete_work_session(session_id: uuid.UUID, user: CurrentUser, session: SessionDep) -> Response:
    await service.delete_work_session(session, user.id, session_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ---- income ----

income = APIRouter(prefix="/income", tags=["trueprofit"])


@income.get("", response_model=Page[IncomeOut])
async def list_income(
    user: CurrentUser,
    session: SessionDep,
    date_from: FromQuery = None,
    date_to: ToQuery = None,
    work_session_id: uuid.UUID | None = None,
    limit: LimitQuery = DEFAULT_PAGE_SIZE,
    cursor: CursorQuery = None,
) -> Page[IncomeOut]:
    return await service.list_income(
        session,
        user.id,
        date_from=date_from,
        date_to=date_to,
        work_session_id=work_session_id,
        cursor=cursor,
        limit=limit,
    )


@income.post("", status_code=status.HTTP_201_CREATED, response_model=IncomeOut)
async def create_income(body: IncomeCreate, user: CurrentUser, session: SessionDep) -> IncomeOut:
    return await service.create_income(session, user.id, body)


@income.get("/{income_id}", response_model=IncomeOut, responses=_NOT_FOUND)
async def get_income(income_id: uuid.UUID, user: CurrentUser, session: SessionDep) -> IncomeOut:
    return await service.get_income(session, user.id, income_id)


@income.patch("/{income_id}", response_model=IncomeOut, responses=_NOT_FOUND)
async def update_income(
    income_id: uuid.UUID, body: IncomeUpdate, user: CurrentUser, session: SessionDep
) -> IncomeOut:
    return await service.update_income(session, user.id, income_id, body)


@income.delete("/{income_id}", status_code=status.HTTP_204_NO_CONTENT, responses=_NOT_FOUND)
async def delete_income(income_id: uuid.UUID, user: CurrentUser, session: SessionDep) -> Response:
    await service.delete_income(session, user.id, income_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ---- expenses ----

expenses = APIRouter(prefix="/expenses", tags=["trueprofit"])


@expenses.get("", response_model=Page[ExpenseOut])
async def list_expenses(
    user: CurrentUser,
    session: SessionDep,
    date_from: FromQuery = None,
    date_to: ToQuery = None,
    category: ExpenseCategory | None = None,
    limit: LimitQuery = DEFAULT_PAGE_SIZE,
    cursor: CursorQuery = None,
) -> Page[ExpenseOut]:
    return await service.list_expenses(
        session, user.id, date_from=date_from, date_to=date_to, category=category, cursor=cursor, limit=limit
    )


@expenses.post("", status_code=status.HTTP_201_CREATED, response_model=ExpenseOut)
async def create_expense(body: ExpenseCreate, user: CurrentUser, session: SessionDep) -> ExpenseOut:
    return await service.create_expense(session, user.id, body)


@expenses.get("/{expense_id}", response_model=ExpenseOut, responses=_NOT_FOUND)
async def get_expense(expense_id: uuid.UUID, user: CurrentUser, session: SessionDep) -> ExpenseOut:
    return await service.get_expense(session, user.id, expense_id)


@expenses.patch("/{expense_id}", response_model=ExpenseOut, responses=_NOT_FOUND)
async def update_expense(
    expense_id: uuid.UUID, body: ExpenseUpdate, user: CurrentUser, session: SessionDep
) -> ExpenseOut:
    return await service.update_expense(session, user.id, expense_id, body)


@expenses.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT, responses=_NOT_FOUND)
async def delete_expense(expense_id: uuid.UUID, user: CurrentUser, session: SessionDep) -> Response:
    await service.delete_expense(session, user.id, expense_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ---- summaries / trends ----

profit = APIRouter(prefix="/profit", tags=["trueprofit"])


@profit.get("/summary", response_model=ProfitSummary)
async def profit_summary(
    user: CurrentUser,
    session: SessionDep,
    period: Period = "day",
    on: Annotated[
        date | None, Query(alias="date", description="Any local date in the period (default: today)")
    ] = None,
) -> ProfitSummary:
    """Actual revenue, expenses, net profit and hours for one day, ISO week or calendar month."""
    return await service.summary(session, user.id, period=period, on=on)


@profit.get("/trends", response_model=ProfitTrends)
async def profit_trends(
    user: CurrentUser,
    session: SessionDep,
    granularity: Period = "day",
    date_from: FromQuery = None,
    date_to: ToQuery = None,
) -> ProfitTrends:
    """One point per bucket, empty buckets included. Default window: 30 days / 12 weeks / 12 months."""
    return await service.trends(
        session, user.id, granularity=granularity, date_from=date_from, date_to=date_to
    )


for _sub in (sessions, income, expenses, profit):
    router.include_router(_sub)
