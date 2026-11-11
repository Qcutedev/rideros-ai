import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/network/paged_result.dart';
import 'package:rideros_ai/core/utils/date_json.dart';
import 'package:rideros_ai/features/profit/domain/profit_period.dart';
import 'package:rideros_ai/features/profit/domain/profit_records.dart';
import 'package:rideros_ai/features/profit/domain/profit_repositories.dart';
import 'package:rideros_ai/features/profit/domain/profit_summary.dart';

Decimal d(String value) => Decimal.parse(value);

final testCreatedAt = DateTime.utc(2026, 11, 10, 3);

/// "Now" in tests: Tuesday 10 Nov 2026, 14:07 local.
DateTime testNow() => DateTime(2026, 11, 10, 14, 7);

ProfitMetrics metrics({
  String revenue = '0.00',
  String expenses = '0.00',
  String? net,
  String hours = '0.00',
  String? revenuePerHour,
  String? netPerHour,
  int incomeCount = 0,
  int expenseCount = 0,
  int sessionCount = 0,
}) {
  final netValue = net ?? (d(revenue) - d(expenses)).toStringAsFixed(2);
  final noHours = d(hours) == Decimal.zero;
  return ProfitMetrics(
    totalRevenue: d(revenue),
    totalExpenses: d(expenses),
    netProfit: d(netValue),
    workingHours: d(hours),
    revenuePerHour: revenuePerHour == null ? null : d(revenuePerHour),
    netProfitPerHour: netPerHour == null ? null : d(netPerHour),
    reason: noHours ? 'no_working_hours' : null,
    incomeCount: incomeCount,
    expenseCount: expenseCount,
    workSessionCount: sessionCount,
  );
}

DateTime _periodEnd(DateTime start, ProfitPeriod period) => switch (period) {
  ProfitPeriod.day => start,
  ProfitPeriod.week => start.add(const Duration(days: 6)),
  ProfitPeriod.month => DateTime.utc(
    start.year,
    start.month + 1,
  ).subtract(const Duration(days: 1)),
};

/// Scriptable [ProfitRepository]. Summaries come from [summaryMetrics] keyed by
/// (period, period start); anything else is empty. "Today" is [today].
class FakeProfitRepository implements ProfitRepository {
  FakeProfitRepository({DateTime? today})
    : today = dateOnly(today ?? testNow());

  DateTime today;
  final Map<(ProfitPeriod, DateTime), ProfitMetrics> summaryMetrics = {};
  final Map<ProfitPeriod, List<ProfitMetrics>> trendMetrics = {};
  Object? summaryError;
  Object? trendsError;
  Completer<void>? gate;
  final calls = <String>[];

  void setSummary(ProfitPeriod period, ProfitMetrics value, {DateTime? on}) =>
      summaryMetrics[(period, periodStart(on ?? today, period))] = value;

  @override
  Future<ProfitSummary> summary(ProfitPeriod period, {DateTime? date}) async {
    calls.add(
      'summary:${period.name}:${date == null ? '-' : formatIsoDate(date)}',
    );
    await gate?.future;
    if (summaryError != null) throw summaryError!;
    final start = periodStart(date ?? today, period);
    return ProfitSummary(
      period: period,
      startDate: start,
      endDate: _periodEnd(start, period),
      timezone: 'Asia/Bangkok',
      currency: 'THB',
      metrics: summaryMetrics[(period, start)] ?? metrics(),
    );
  }

  @override
  Future<ProfitTrends> trends(ProfitPeriod granularity, {DateTime? to}) async {
    calls.add(
      'trends:${granularity.name}:${to == null ? '-' : formatIsoDate(to)}',
    );
    await gate?.future;
    if (trendsError != null) throw trendsError!;
    final values = trendMetrics[granularity] ?? [metrics(), metrics()];
    var start = periodStart(to ?? today, granularity);
    final points = <TrendPoint>[];
    for (final value in values.reversed) {
      points.insert(
        0,
        TrendPoint(
          startDate: start,
          endDate: _periodEnd(start, granularity),
          metrics: value,
        ),
      );
      start = periodStart(start.subtract(const Duration(days: 1)), granularity);
    }
    return ProfitTrends(
      granularity: granularity,
      currency: 'THB',
      points: points,
    );
  }
}

/// In-memory [RecordRepository]: newest first, [pageSize] per page, scriptable errors.
class FakeRecordRepository<T, I> implements RecordRepository<T, I> {
  FakeRecordRepository({
    required this.build,
    required this.dateOf,
    required this.idOf,
    this.pageSize = 50,
  });

  final T Function(String id, I input, T? previous) build;
  final DateTime Function(T record) dateOf;
  final String Function(T record) idOf;
  int pageSize;

  /// Newest first.
  final items = <T>[];
  Object? listError;
  Object? getError;
  Object? saveError;
  Object? deleteError;
  Completer<void>? saveGate;
  Completer<void>? listGate;
  final calls = <String>[];
  I? lastInput;
  int _next = 1;

  String _newId() => 'id-${_next++}';

  T add(I input) {
    final record = build(_newId(), input, null);
    items.insert(0, record);
    return record;
  }

  @override
  Future<PagedResult<T>> list({
    String? cursor,
    DateTime? from,
    DateTime? to,
  }) async {
    calls.add(
      'list:${cursor ?? '-'}:${from == null ? '-' : formatIsoDate(from)}',
    );
    await listGate?.future;
    if (listError != null) throw listError!;
    final matching = items.where((r) {
      final day = dateOnly(dateOf(r));
      return (from == null || !day.isBefore(from)) &&
          (to == null || !day.isAfter(to));
    }).toList();
    final offset = cursor == null ? 0 : int.parse(cursor);
    final page = matching.skip(offset).take(pageSize).toList();
    final end = offset + page.length;
    return PagedResult(
      items: page,
      nextCursor: end < matching.length ? '$end' : null,
    );
  }

  @override
  Future<T> get(String id) async {
    calls.add('get:$id');
    if (getError != null) throw getError!;
    return items.firstWhere(
      (r) => idOf(r) == id,
      orElse: () => throw const ApiFailure(statusCode: 404, code: 'not_found'),
    );
  }

  @override
  Future<T> create(I input) async {
    calls.add('create');
    lastInput = input;
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    return add(input);
  }

  @override
  Future<T> update(String id, I input) async {
    calls.add('update:$id');
    lastInput = input;
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    final index = items.indexWhere((r) => idOf(r) == id);
    final updated = build(id, input, items[index]);
    items[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    calls.add('delete:$id');
    if (deleteError != null) throw deleteError!;
    items.removeWhere((r) => idOf(r) == id);
  }
}

FakeRecordRepository<Income, IncomeInput> fakeIncomeRepository() =>
    FakeRecordRepository(
      dateOf: (r) => r.occurredOn,
      idOf: (r) => r.id,
      build: (id, i, previous) => Income(
        id: id,
        occurredOn: i.occurredOn,
        amount: i.amount,
        workSessionId: i.workSessionId,
        orderCount: i.orderCount,
        distanceKm: i.distanceKm,
        workingHours: i.workingHours,
        sourceLabel: i.sourceLabel,
        notes: i.notes,
        isDemo: previous is Income && previous.isDemo,
        createdAt: testCreatedAt,
        updatedAt: testCreatedAt,
      ),
    );

FakeRecordRepository<Expense, ExpenseInput> fakeExpenseRepository() =>
    FakeRecordRepository(
      dateOf: (r) => r.occurredOn,
      idOf: (r) => r.id,
      build: (id, i, previous) => Expense(
        id: id,
        occurredOn: i.occurredOn,
        category: i.category,
        amount: i.amount,
        workSessionId: previous is Expense ? previous.workSessionId : null,
        description: i.description,
        createdAt: testCreatedAt,
        updatedAt: testCreatedAt,
      ),
    );

FakeRecordRepository<WorkSession, WorkSessionInput> fakeSessionRepository() =>
    FakeRecordRepository(
      dateOf: (r) => r.startedAt,
      idOf: (r) => r.id,
      build: (id, i, previous) => WorkSession(
        id: id,
        startedAt: i.startedAt,
        endedAt: i.endedAt,
        distanceKm: i.distanceKm,
        orderCount: i.orderCount,
        notes: i.notes,
        createdAt: testCreatedAt,
        updatedAt: testCreatedAt,
      ),
    );

/// All TrueProfit fakes, so a test can script and inspect them.
class ProfitFakes {
  final profit = FakeProfitRepository();
  final income = fakeIncomeRepository();
  final expenses = fakeExpenseRepository();
  final sessions = fakeSessionRepository();
}
