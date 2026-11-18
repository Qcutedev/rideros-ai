"""TrueProfit use cases: work sessions, income, expenses, summaries and trends."""

import uuid
from dataclasses import asdict
from datetime import UTC, date, datetime, timedelta

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from starlette.concurrency import run_in_threadpool

from app.core.errors import AppError, ConflictError, NotFoundError
from app.core.pagination import InvalidCursorError, Page, decode_cursor, encode_cursor
from app.core.timezones import local_dates_to_utc_range, today_in
from app.modules.profit import calculator as calc
from app.modules.profit import heatmap as hm
from app.modules.profit import patterns as pat
from app.modules.profit import repository as repo
from app.modules.profit import trend_analysis as trend
from app.modules.profit.models import (
    WORK_SESSION_OVERLAP_CONSTRAINT,
    ExpenseRecord,
    IncomeRecord,
    WorkSession,
)
from app.modules.profit.schemas import (
    ExpenseCreate,
    ExpenseOut,
    ExpenseUpdate,
    HeatmapCell,
    IncomeCreate,
    IncomeOut,
    IncomeUpdate,
    PatternGroup,
    ProfitHeatmap,
    ProfitSummary,
    ProfitTrends,
    TrendAnalysisOut,
    TrendPoint,
    WorkPatterns,
    WorkSessionCreate,
    WorkSessionOut,
    WorkSessionUpdate,
)
from app.modules.users.service import Locale, get_locale

MAX_SESSION_LENGTH = timedelta(hours=24)

# Default trend windows when `from` is omitted (counted in buckets, ending at `to`).
_DEFAULT_TREND_POINTS: dict[calc.Period, int] = {"day": 30, "week": 12, "month": 12}


class InvalidTimeRangeError(AppError):
    code = "invalid_time_range"


class InvalidDateRangeError(AppError):
    code = "invalid_date_range"


class InvalidWorkSessionError(AppError):
    code = "invalid_work_session"
    message = "Work session not found"


def _overlap_error() -> ConflictError:
    return ConflictError("Overlaps another work session", code="work_session_overlap")


def _check_date_range(date_from: date | None, date_to: date | None) -> None:
    if date_from is not None and date_to is not None and date_from > date_to:
        raise InvalidDateRangeError("`from` must be on or before `to`")


# ---- work sessions ----


def _check_span(started_at: datetime, ended_at: datetime) -> None:
    if ended_at <= started_at:
        raise InvalidTimeRangeError("ended_at must be after started_at")
    if ended_at - started_at > MAX_SESSION_LENGTH:
        raise InvalidTimeRangeError("A work session can be at most 24 hours", code="work_session_too_long")


async def _commit_session_write(session: AsyncSession) -> None:
    try:
        await session.commit()
    except IntegrityError as exc:  # a concurrent write slipped past the overlap check
        await session.rollback()
        if WORK_SESSION_OVERLAP_CONSTRAINT in str(exc.orig):
            raise _overlap_error() from exc
        raise


async def create_work_session(
    session: AsyncSession, user_id: uuid.UUID, body: WorkSessionCreate
) -> WorkSessionOut:
    _check_span(body.started_at, body.ended_at)
    if await repo.has_overlapping_session(session, user_id, body.started_at, body.ended_at):
        raise _overlap_error()
    row = WorkSession(user_id=user_id, **body.model_dump())
    session.add(row)
    await _commit_session_write(session)
    await session.refresh(row)
    return WorkSessionOut.model_validate(row)


async def _get_work_session(session: AsyncSession, user_id: uuid.UUID, row_id: uuid.UUID) -> WorkSession:
    row = await repo.get_owned(session, WorkSession, user_id, row_id)
    if row is None:
        raise NotFoundError("Work session not found", code="work_session_not_found")
    return row


async def get_work_session(session: AsyncSession, user_id: uuid.UUID, row_id: uuid.UUID) -> WorkSessionOut:
    return WorkSessionOut.model_validate(await _get_work_session(session, user_id, row_id))


async def update_work_session(
    session: AsyncSession, user_id: uuid.UUID, row_id: uuid.UUID, body: WorkSessionUpdate
) -> WorkSessionOut:
    row = await _get_work_session(session, user_id, row_id)
    changes = body.changes()
    # Validate the merged values before touching the row (autoflush would send them to the DB).
    started_at = changes.get("started_at", row.started_at)
    ended_at = changes.get("ended_at", row.ended_at)
    _check_span(started_at, ended_at)  # type: ignore[arg-type]
    if ("started_at" in changes or "ended_at" in changes) and await repo.has_overlapping_session(
        session,
        user_id,
        started_at,  # type: ignore[arg-type]
        ended_at,  # type: ignore[arg-type]
        exclude_id=row.id,
    ):
        raise _overlap_error()
    for field, value in changes.items():
        setattr(row, field, value)
    await _commit_session_write(session)
    await session.refresh(row)
    return WorkSessionOut.model_validate(row)


async def delete_work_session(session: AsyncSession, user_id: uuid.UUID, row_id: uuid.UUID) -> None:
    """Linked income/expense records stay; their work_session_id becomes null (ON DELETE SET NULL)."""
    if not await repo.delete_owned(session, WorkSession, user_id, row_id):
        raise NotFoundError("Work session not found", code="work_session_not_found")
    await session.commit()


async def list_work_sessions(
    session: AsyncSession,
    user_id: uuid.UUID,
    *,
    date_from: date | None,
    date_to: date | None,
    cursor: str | None,
    limit: int,
) -> Page[WorkSessionOut]:
    """`from`/`to` are local dates (rider's time zone) of `started_at`."""
    _check_date_range(date_from, date_to)
    after: repo.SessionCursor | None = None
    if cursor is not None:
        started, row_id = decode_cursor(cursor, 2)
        try:
            after = (datetime.fromisoformat(started), uuid.UUID(row_id))
        except ValueError as exc:
            raise InvalidCursorError() from exc
    start = end = None
    if date_from is not None or date_to is not None:
        zone = (await get_locale(session, user_id)).zone
        if date_from is not None:
            start = local_dates_to_utc_range(date_from, date_from, zone)[0]
        if date_to is not None:
            end = local_dates_to_utc_range(date_to, date_to, zone)[1]
    rows = await repo.list_sessions(session, user_id, start=start, end=end, after=after, limit=limit + 1)
    next_cursor = None
    if len(rows) > limit:
        rows = rows[:limit]
        next_cursor = encode_cursor([rows[-1].started_at.isoformat(), str(rows[-1].id)])
    return Page[WorkSessionOut](
        items=[WorkSessionOut.model_validate(r) for r in rows], next_cursor=next_cursor
    )


# ---- income / expenses ----


async def _check_work_session_link(session: AsyncSession, user_id: uuid.UUID, session_id: object) -> None:
    """A record may only link to the rider's own session. Missing and foreign ids look the same."""
    if session_id is not None and not await repo.owns_work_session(session, user_id, session_id):  # type: ignore[arg-type]
        raise InvalidWorkSessionError(details=[{"loc": ["body", "work_session_id"], "msg": "not found"}])


def _record_cursor(cursor: str | None) -> repo.RecordCursor | None:
    if cursor is None:
        return None
    day, created, row_id = decode_cursor(cursor, 3)
    try:
        return date.fromisoformat(day), datetime.fromisoformat(created), uuid.UUID(row_id)
    except ValueError as exc:
        raise InvalidCursorError() from exc


def _next_record_cursor(rows: list, limit: int) -> tuple[list, str | None]:
    if len(rows) <= limit:
        return rows, None
    rows = rows[:limit]
    last = rows[-1]
    return rows, encode_cursor([last.occurred_on.isoformat(), last.created_at.isoformat(), str(last.id)])


async def create_income(session: AsyncSession, user_id: uuid.UUID, body: IncomeCreate) -> IncomeOut:
    await _check_work_session_link(session, user_id, body.work_session_id)
    row = await repo.add(session, IncomeRecord(user_id=user_id, **body.model_dump()))
    await session.commit()
    return IncomeOut.model_validate(row)


async def _get_income(session: AsyncSession, user_id: uuid.UUID, row_id: uuid.UUID) -> IncomeRecord:
    row = await repo.get_owned(session, IncomeRecord, user_id, row_id)
    if row is None:
        raise NotFoundError("Income record not found", code="income_not_found")
    return row


async def get_income(session: AsyncSession, user_id: uuid.UUID, row_id: uuid.UUID) -> IncomeOut:
    return IncomeOut.model_validate(await _get_income(session, user_id, row_id))


async def update_income(
    session: AsyncSession, user_id: uuid.UUID, row_id: uuid.UUID, body: IncomeUpdate
) -> IncomeOut:
    row = await _get_income(session, user_id, row_id)
    changes = body.changes()
    if "work_session_id" in changes:
        await _check_work_session_link(session, user_id, changes["work_session_id"])
    for field, value in changes.items():
        setattr(row, field, value)
    await session.commit()
    await session.refresh(row)
    return IncomeOut.model_validate(row)


async def delete_income(session: AsyncSession, user_id: uuid.UUID, row_id: uuid.UUID) -> None:
    if not await repo.delete_owned(session, IncomeRecord, user_id, row_id):
        raise NotFoundError("Income record not found", code="income_not_found")
    await session.commit()


async def list_income(
    session: AsyncSession,
    user_id: uuid.UUID,
    *,
    date_from: date | None,
    date_to: date | None,
    work_session_id: uuid.UUID | None,
    cursor: str | None,
    limit: int,
) -> Page[IncomeOut]:
    _check_date_range(date_from, date_to)
    rows = await repo.list_income(
        session,
        user_id,
        date_from=date_from,
        date_to=date_to,
        work_session_id=work_session_id,
        after=_record_cursor(cursor),
        limit=limit + 1,
    )
    rows, next_cursor = _next_record_cursor(rows, limit)
    return Page[IncomeOut](items=[IncomeOut.model_validate(r) for r in rows], next_cursor=next_cursor)


async def create_expense(session: AsyncSession, user_id: uuid.UUID, body: ExpenseCreate) -> ExpenseOut:
    await _check_work_session_link(session, user_id, body.work_session_id)
    row = await repo.add(session, ExpenseRecord(user_id=user_id, **body.model_dump()))
    await session.commit()
    return ExpenseOut.model_validate(row)


async def _get_expense(session: AsyncSession, user_id: uuid.UUID, row_id: uuid.UUID) -> ExpenseRecord:
    row = await repo.get_owned(session, ExpenseRecord, user_id, row_id)
    if row is None:
        raise NotFoundError("Expense record not found", code="expense_not_found")
    return row


async def get_expense(session: AsyncSession, user_id: uuid.UUID, row_id: uuid.UUID) -> ExpenseOut:
    return ExpenseOut.model_validate(await _get_expense(session, user_id, row_id))


async def update_expense(
    session: AsyncSession, user_id: uuid.UUID, row_id: uuid.UUID, body: ExpenseUpdate
) -> ExpenseOut:
    row = await _get_expense(session, user_id, row_id)
    changes = body.changes()
    if "work_session_id" in changes:
        await _check_work_session_link(session, user_id, changes["work_session_id"])
    for field, value in changes.items():
        setattr(row, field, value)
    await session.commit()
    await session.refresh(row)
    return ExpenseOut.model_validate(row)


async def delete_expense(session: AsyncSession, user_id: uuid.UUID, row_id: uuid.UUID) -> None:
    if not await repo.delete_owned(session, ExpenseRecord, user_id, row_id):
        raise NotFoundError("Expense record not found", code="expense_not_found")
    await session.commit()


async def list_expenses(
    session: AsyncSession,
    user_id: uuid.UUID,
    *,
    date_from: date | None,
    date_to: date | None,
    category: str | None,
    cursor: str | None,
    limit: int,
) -> Page[ExpenseOut]:
    _check_date_range(date_from, date_to)
    rows = await repo.list_expenses(
        session,
        user_id,
        date_from=date_from,
        date_to=date_to,
        category=category,
        after=_record_cursor(cursor),
        limit=limit + 1,
    )
    rows, next_cursor = _next_record_cursor(rows, limit)
    return Page[ExpenseOut](items=[ExpenseOut.model_validate(r) for r in rows], next_cursor=next_cursor)


# ---- summaries / trends ----


async def daily_totals(
    session: AsyncSession, user_id: uuid.UUID, first: date, last: date, locale: Locale
) -> dict[date, calc.Totals]:
    days: dict[date, calc.Totals] = {}
    for inc in await repo.income_by_day(session, user_id, first, last):
        t = days.setdefault(inc.day, calc.Totals())
        t.revenue += inc.revenue
        t.unlinked_hours += inc.unlinked_hours
        t.income_count += inc.count
    for exp in await repo.expenses_by_day(session, user_id, first, last):
        t = days.setdefault(exp.day, calc.Totals())
        t.expenses += exp.expenses
        t.expense_count += exp.count
    start, end = local_dates_to_utc_range(first, last, locale.zone)
    for started_at, ended_at in await repo.session_spans(session, user_id, start, end):
        local_day = started_at.astimezone(locale.zone).date()  # counts on the day it started
        days.setdefault(local_day, calc.Totals()).add_session(ended_at - started_at)
    return days


async def summary(
    session: AsyncSession, user_id: uuid.UUID, *, period: calc.Period, on: date | None
) -> ProfitSummary:
    locale = await get_locale(session, user_id)
    first, last = calc.bucket_range(on or today_in(locale.zone), period)
    total = calc.Totals()
    for t in (await daily_totals(session, user_id, first, last, locale)).values():
        total.add(t)
    metrics = calc.compute_metrics(total)
    return ProfitSummary(
        period=period,
        start_date=first,
        end_date=last,
        timezone=locale.timezone,
        currency=locale.currency,
        **asdict(metrics),
    )


async def trends(
    session: AsyncSession,
    user_id: uuid.UUID,
    *,
    granularity: calc.Period,
    date_from: date | None,
    date_to: date | None,
) -> ProfitTrends:
    locale = await get_locale(session, user_id)
    last_day = date_to or today_in(locale.zone)
    if date_from is None:
        start = calc.bucket_start(last_day, granularity)
        for _ in range(_DEFAULT_TREND_POINTS[granularity] - 1):
            start = calc.bucket_start(start - timedelta(days=1), granularity)
        date_from = start
    _check_date_range(date_from, last_day)
    if calc.count_buckets(date_from, last_day, granularity) > calc.MAX_TREND_POINTS:
        raise InvalidDateRangeError(
            f"Range too large: at most {calc.MAX_TREND_POINTS} points per request", code="range_too_large"
        )
    buckets = calc.buckets_between(date_from, last_day, granularity)
    first, last = buckets[0][0], buckets[-1][1]
    per_bucket: dict[date, calc.Totals] = {b0: calc.Totals() for b0, _ in buckets}
    for day, t in (await daily_totals(session, user_id, first, last, locale)).items():
        per_bucket[calc.bucket_start(day, granularity)].add(t)
    metrics = [calc.compute_metrics(per_bucket[b0]) for b0, _ in buckets]
    analysis = trend.analyse(
        [m.net_profit for m in metrics],
        [m.income_count + m.expense_count + m.work_session_count > 0 for m in metrics],
        granularity,
    )
    points = [
        TrendPoint(
            start_date=b0,
            end_date=b1,
            net_profit_moving_average=analysis.moving_average[i],
            net_profit_trend=analysis.trend_line[i],
            **asdict(m),
        )
        for i, ((b0, b1), m) in enumerate(zip(buckets, metrics, strict=True))
    ]
    return ProfitTrends(
        granularity=granularity,
        start_date=first,
        end_date=last,
        timezone=locale.timezone,
        currency=locale.currency,
        points=points,
        analysis=TrendAnalysisOut(
            status=analysis.status,
            moving_average_window=analysis.moving_average_window,
            active_buckets=analysis.active_buckets,
            min_active_buckets=analysis.min_active_buckets,
            direction=analysis.direction,
            slope_per_bucket=analysis.slope_per_bucket,
            p_value=analysis.p_value,
        ),
    )


# ---- work patterns ----


async def work_patterns(
    session: AsyncSession, user_id: uuid.UUID, *, now: datetime | None = None
) -> WorkPatterns:
    """K-Means groups of the sessions that started in the last WINDOW_DAYS local days (incl. today)."""
    locale = await get_locale(session, user_id)
    last = (now or datetime.now(UTC)).astimezone(locale.zone).date()
    first = last - timedelta(days=pat.WINDOW_DAYS - 1)
    start, end = local_dates_to_utc_range(first, last, locale.zone)
    rows = await repo.sessions_with_money(session, user_id, start, end)
    # ~0.3–0.9 s of CPU on a miss, so off the event loop; unchanged data hits the cache.
    result = await run_in_threadpool(pat.find_patterns_cached, tuple(rows), locale.zone)
    return WorkPatterns(
        status=result.status,
        window_days=pat.WINDOW_DAYS,
        start_date=first,
        end_date=last,
        session_count=result.session_count,
        min_sessions=pat.MIN_SESSIONS,
        k=result.k,
        silhouette=result.silhouette,
        null_silhouette=result.null_silhouette,
        stability=result.stability,
        groups=[PatternGroup.model_validate(g, from_attributes=True) for g in result.groups],
        timezone=locale.timezone,
        currency=locale.currency,
    )


# ---- profit heat map ----


async def heatmap(session: AsyncSession, user_id: uuid.UUID, *, now: datetime | None = None) -> ProfitHeatmap:
    """Net profit per hour by weekday × slot over the last WINDOW_DAYS local days (incl. today)."""
    locale = await get_locale(session, user_id)
    last = (now or datetime.now(UTC)).astimezone(locale.zone).date()
    first = last - timedelta(days=hm.WINDOW_DAYS - 1)
    start, end = local_dates_to_utc_range(first, last, locale.zone)
    rows = await repo.sessions_with_money(session, user_id, start, end)
    unlinked = await repo.unlinked_by_day(session, user_id, first, last)
    result = hm.build(rows, unlinked, locale.zone)  # a few segments per session: cheap, no cache
    return ProfitHeatmap(
        status=result.status,
        window_days=hm.WINDOW_DAYS,
        start_date=first,
        end_date=last,
        slot_hours=hm.SLOT_HOURS,
        session_count=result.session_count,
        min_sessions=hm.MIN_SESSIONS,
        min_cell_sessions=hm.MIN_CELL_SESSIONS,
        min_cell_hours=hm.MIN_CELL_HOURS,
        excluded_session_count=result.excluded_session_count,
        excluded_income_count=result.excluded_income_count,
        excluded_expense_count=result.excluded_expense_count,
        hours=result.hours,
        revenue_per_hour=result.revenue_per_hour,
        net_profit_per_hour=result.net_profit_per_hour,
        cells=[HeatmapCell.model_validate(c, from_attributes=True) for c in result.cells],
        timezone=locale.timezone,
        currency=locale.currency,
    )
