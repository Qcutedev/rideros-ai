"""TrueProfit data access. Every query is scoped by `user_id` (docs/DATABASE_DESIGN.md §5)."""

import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import NamedTuple

from sqlalchemy import Select, delete, func, select, tuple_
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.profit.heatmap import UnlinkedDay
from app.modules.profit.models import ExpenseRecord, IncomeRecord, WorkSession
from app.modules.profit.patterns import SessionRow

type Owned = WorkSession | IncomeRecord | ExpenseRecord
type RecordCursor = tuple[date, datetime, uuid.UUID]  # (occurred_on, created_at, id), newest first
type SessionCursor = tuple[datetime, uuid.UUID]  # (started_at, id), newest first


async def add[T: Owned](session: AsyncSession, row: T) -> T:
    session.add(row)
    await session.flush()
    await session.refresh(row)
    return row


async def get_owned[T: Owned](
    session: AsyncSession, model: type[T], user_id: uuid.UUID, row_id: uuid.UUID
) -> T | None:
    stmt = select(model).where(model.id == row_id, model.user_id == user_id)
    return (await session.execute(stmt)).scalar_one_or_none()


async def get_by_id[T: Owned](session: AsyncSession, model: type[T], row_id: uuid.UUID) -> T | None:
    """Any user's row. Only for checking a client-generated id on create; never return it as data."""
    stmt = select(model).where(model.id == row_id)
    return (await session.execute(stmt)).scalar_one_or_none()


async def delete_owned(
    session: AsyncSession, model: type[Owned], user_id: uuid.UUID, row_id: uuid.UUID
) -> bool:
    stmt = delete(model).where(model.id == row_id, model.user_id == user_id).returning(model.id)
    return (await session.execute(stmt)).scalar_one_or_none() is not None


async def owns_work_session(session: AsyncSession, user_id: uuid.UUID, session_id: uuid.UUID) -> bool:
    stmt = select(WorkSession.id).where(WorkSession.id == session_id, WorkSession.user_id == user_id)
    return (await session.execute(stmt)).scalar_one_or_none() is not None


async def has_overlapping_session(
    session: AsyncSession,
    user_id: uuid.UUID,
    started_at: datetime,
    ended_at: datetime,
    exclude_id: uuid.UUID | None = None,
) -> bool:
    """Same rule as the exclusion constraint: half-open ranges, so touching sessions are fine."""
    stmt = select(WorkSession.id).where(
        WorkSession.user_id == user_id,
        WorkSession.started_at < ended_at,
        WorkSession.ended_at > started_at,
    )
    if exclude_id is not None:
        stmt = stmt.where(WorkSession.id != exclude_id)
    return (await session.execute(stmt.limit(1))).scalar_one_or_none() is not None


# ---- lists (cursor pagination, newest first) ----


def _dated_page[T: (IncomeRecord, ExpenseRecord)](
    model: type[T],
    user_id: uuid.UUID,
    date_from: date | None,
    date_to: date | None,
    after: RecordCursor | None,
    limit: int,
) -> Select[tuple[T]]:
    stmt = select(model).where(model.user_id == user_id)
    if date_from is not None:
        stmt = stmt.where(model.occurred_on >= date_from)
    if date_to is not None:
        stmt = stmt.where(model.occurred_on <= date_to)
    if after is not None:
        stmt = stmt.where(tuple_(model.occurred_on, model.created_at, model.id) < tuple_(*after))
    return stmt.order_by(model.occurred_on.desc(), model.created_at.desc(), model.id.desc()).limit(limit)


async def list_income(
    session: AsyncSession,
    user_id: uuid.UUID,
    *,
    date_from: date | None,
    date_to: date | None,
    work_session_id: uuid.UUID | None,
    after: RecordCursor | None,
    limit: int,
) -> list[IncomeRecord]:
    stmt = _dated_page(IncomeRecord, user_id, date_from, date_to, after, limit)
    if work_session_id is not None:
        stmt = stmt.where(IncomeRecord.work_session_id == work_session_id)
    return list((await session.execute(stmt)).scalars())


async def list_expenses(
    session: AsyncSession,
    user_id: uuid.UUID,
    *,
    date_from: date | None,
    date_to: date | None,
    category: str | None,
    after: RecordCursor | None,
    limit: int,
) -> list[ExpenseRecord]:
    stmt = _dated_page(ExpenseRecord, user_id, date_from, date_to, after, limit)
    if category is not None:
        stmt = stmt.where(ExpenseRecord.category == category)
    return list((await session.execute(stmt)).scalars())


async def list_sessions(
    session: AsyncSession,
    user_id: uuid.UUID,
    *,
    start: datetime | None,
    end: datetime | None,
    after: SessionCursor | None,
    limit: int,
) -> list[WorkSession]:
    """Sessions whose `started_at` is in [start, end)."""
    stmt = select(WorkSession).where(WorkSession.user_id == user_id)
    if start is not None:
        stmt = stmt.where(WorkSession.started_at >= start)
    if end is not None:
        stmt = stmt.where(WorkSession.started_at < end)
    if after is not None:
        stmt = stmt.where(tuple_(WorkSession.started_at, WorkSession.id) < tuple_(*after))
    stmt = stmt.order_by(WorkSession.started_at.desc(), WorkSession.id.desc()).limit(limit)
    return list((await session.execute(stmt)).scalars())


# ---- aggregates for summaries / trends ----


class IncomeDay(NamedTuple):
    day: date
    revenue: Decimal
    unlinked_hours: Decimal  # working_hours of records without a work session
    count: int


class ExpenseDay(NamedTuple):
    day: date
    expenses: Decimal
    count: int


async def income_by_day(
    session: AsyncSession, user_id: uuid.UUID, first: date, last: date
) -> list[IncomeDay]:
    stmt = (
        select(
            IncomeRecord.occurred_on,
            func.coalesce(func.sum(IncomeRecord.amount), 0),
            func.coalesce(
                func.sum(IncomeRecord.working_hours).filter(IncomeRecord.work_session_id.is_(None)), 0
            ),
            func.count(),
        )
        .where(IncomeRecord.user_id == user_id, IncomeRecord.occurred_on.between(first, last))
        .group_by(IncomeRecord.occurred_on)
    )
    return [IncomeDay(d, Decimal(r), Decimal(h), int(n)) for d, r, h, n in await session.execute(stmt)]


async def expenses_by_day(
    session: AsyncSession, user_id: uuid.UUID, first: date, last: date
) -> list[ExpenseDay]:
    stmt = (
        select(ExpenseRecord.occurred_on, func.coalesce(func.sum(ExpenseRecord.amount), 0), func.count())
        .where(ExpenseRecord.user_id == user_id, ExpenseRecord.occurred_on.between(first, last))
        .group_by(ExpenseRecord.occurred_on)
    )
    return [ExpenseDay(d, Decimal(e), int(n)) for d, e, n in await session.execute(stmt)]


async def session_spans(
    session: AsyncSession, user_id: uuid.UUID, start: datetime, end: datetime
) -> list[tuple[datetime, datetime]]:
    """(started_at, ended_at) of sessions that start in [start, end). Bucketed by the caller."""
    stmt = select(WorkSession.started_at, WorkSession.ended_at).where(
        WorkSession.user_id == user_id, WorkSession.started_at >= start, WorkSession.started_at < end
    )
    return [(s, e) for s, e in await session.execute(stmt)]


async def sessions_with_money(
    session: AsyncSession, user_id: uuid.UUID, start: datetime, end: datetime
) -> list[SessionRow]:
    """Sessions starting in [start, end) with the totals of the income and expenses linked to them."""
    income = (
        select(
            IncomeRecord.work_session_id.label("sid"),
            func.sum(IncomeRecord.amount).label("revenue"),
            func.count().label("n"),
        )
        .where(IncomeRecord.user_id == user_id, IncomeRecord.work_session_id.is_not(None))
        .group_by(IncomeRecord.work_session_id)
        .subquery()
    )
    expense = (
        select(ExpenseRecord.work_session_id.label("sid"), func.sum(ExpenseRecord.amount).label("expenses"))
        .where(ExpenseRecord.user_id == user_id, ExpenseRecord.work_session_id.is_not(None))
        .group_by(ExpenseRecord.work_session_id)
        .subquery()
    )
    stmt = (
        select(
            WorkSession.started_at,
            WorkSession.ended_at,
            func.coalesce(income.c.revenue, 0),
            func.coalesce(expense.c.expenses, 0),
            func.coalesce(income.c.n, 0),
        )
        .outerjoin(income, income.c.sid == WorkSession.id)
        .outerjoin(expense, expense.c.sid == WorkSession.id)
        .where(WorkSession.user_id == user_id, WorkSession.started_at >= start, WorkSession.started_at < end)
        .order_by(WorkSession.started_at, WorkSession.id)
    )
    return [SessionRow(s, e, Decimal(r), Decimal(x), int(n)) for s, e, r, x, n in await session.execute(stmt)]


async def unlinked_by_day(
    session: AsyncSession, user_id: uuid.UUID, first: date, last: date
) -> dict[date, UnlinkedDay]:
    """Income and expenses dated [first, last] that are linked to no work session, per date."""
    untimed = IncomeRecord.working_hours.is_(None)
    income = (
        select(
            IncomeRecord.occurred_on,
            func.coalesce(func.sum(IncomeRecord.amount).filter(untimed), 0),
            func.count().filter(untimed),
            func.count().filter(IncomeRecord.working_hours.is_not(None)),
        )
        .where(
            IncomeRecord.user_id == user_id,
            IncomeRecord.work_session_id.is_(None),
            IncomeRecord.occurred_on.between(first, last),
        )
        .group_by(IncomeRecord.occurred_on)
    )
    expense = (
        select(ExpenseRecord.occurred_on, func.coalesce(func.sum(ExpenseRecord.amount), 0), func.count())
        .where(
            ExpenseRecord.user_id == user_id,
            ExpenseRecord.work_session_id.is_(None),
            ExpenseRecord.occurred_on.between(first, last),
        )
        .group_by(ExpenseRecord.occurred_on)
    )
    days: dict[date, UnlinkedDay] = {}
    for d, r, n, timed in await session.execute(income):
        days[d] = UnlinkedDay(revenue=Decimal(r), income_count=int(n), hours_income_count=int(timed))
    for d, x, n in await session.execute(expense):
        u = days.get(d, UnlinkedDay())
        days[d] = UnlinkedDay(u.revenue, u.income_count, u.hours_income_count, Decimal(x), int(n))
    return days
