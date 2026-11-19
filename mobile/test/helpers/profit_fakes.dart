import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/network/paged_result.dart';
import 'package:rideros_ai/core/utils/date_json.dart';
import 'package:rideros_ai/features/profit/data/pending_record_store.dart';
import 'package:rideros_ai/features/profit/data/shift_timer_store.dart';
import 'package:rideros_ai/features/profit/domain/pending_record.dart';
import 'package:rideros_ai/features/profit/domain/profit_heatmap.dart';
import 'package:rideros_ai/features/profit/domain/profit_period.dart';
import 'package:rideros_ai/features/profit/domain/profit_records.dart';
import 'package:rideros_ai/features/profit/domain/profit_repositories.dart';
import 'package:rideros_ai/features/profit/domain/profit_summary.dart';
import 'package:rideros_ai/features/profit/domain/shift_timer.dart';
import 'package:rideros_ai/features/profit/domain/work_patterns.dart';

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

/// `GET /profit/patterns` result for tests (window: 180 days ending [testNow]).
WorkPatterns workPatterns({
  PatternStatus status = PatternStatus.insufficientData,
  int sessions = 0,
  List<PatternGroup> groups = const [],
}) => WorkPatterns(
  status: status,
  windowDays: 180,
  startDate: DateTime.utc(2026, 5, 15),
  endDate: DateTime.utc(2026, 11, 10),
  sessionCount: sessions,
  minSessions: 30,
  groups: groups,
  currency: 'THB',
);

PatternGroup patternGroup({
  ShiftTimeOfDay time = ShiftTimeOfDay.evening,
  ShiftLength length = ShiftLength.short,
  ShiftDayType days = ShiftDayType.weekday,
  int startMinute = 18 * 60 + 30,
  String hours = '3.1',
  int count = 25,
  double share = 0.676,
  int paid = 25,
  String? netPerHour = '80.25',
}) => PatternGroup(
  timeOfDay: time,
  length: length,
  dayType: days,
  meanStartMinute: startMinute,
  meanHours: d(hours),
  sessionCount: count,
  share: share,
  profitSessionCount: paid,
  revenuePerHour: netPerHour == null ? null : d(netPerHour) + d('20'),
  netProfitPerHour: netPerHour == null ? null : d(netPerHour),
);

/// `GET /profit/heatmap` result for tests (window: 90 days ending [testNow]).
ProfitHeatmap profitHeatmap({
  HeatmapStatus status = HeatmapStatus.insufficientData,
  int sessions = 0,
  List<HeatmapCell> cells = const [],
  String? netPerHour,
  String hours = '0.0',
  int excludedSessions = 0,
  int excludedIncome = 0,
  int excludedExpenses = 0,
}) => ProfitHeatmap(
  status: status,
  windowDays: 90,
  startDate: DateTime.utc(2026, 8, 13),
  endDate: DateTime.utc(2026, 11, 10),
  slotHours: 2,
  sessionCount: sessions,
  minSessions: 10,
  minCellSessions: 2,
  minCellHours: 1,
  excludedSessionCount: excludedSessions,
  excludedIncomeCount: excludedIncome,
  excludedExpenseCount: excludedExpenses,
  hours: d(hours),
  netProfitPerHour: netPerHour == null ? null : d(netPerHour),
  cells: cells,
  currency: 'THB',
);

/// One heat map cell; `netPerHour: null` = below the cell minimum.
HeatmapCell heatCell(
  int weekday,
  int slot, {
  String? netPerHour = '150.00',
  String hours = '6.0',
  int count = 3,
}) => HeatmapCell(
  weekday: weekday,
  slot: slot,
  hours: d(hours),
  sessionCount: count,
  revenuePerHour: netPerHour == null ? null : d(netPerHour) + d('20'),
  netProfitPerHour: netPerHour == null ? null : d(netPerHour),
);

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

  /// `analysis` of trends requests without `from`; per-point moving average / trend line values
  /// line up with [trendMetrics] (missing entries are `null`).
  TrendAnalysis? trendAnalysis;
  List<Decimal?> trendAverages = [];
  List<Decimal?> trendLine = [];

  /// Daily points of a trends request with `from` (date-only keys).
  final Map<DateTime, ProfitMetrics> dailyMetrics = {};
  Object? summaryError;
  Object? trendsError;
  WorkPatterns patternsResult = workPatterns();
  Object? patternsError;
  ProfitHeatmap heatmapResult = profitHeatmap();
  Object? heatmapError;
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
  Future<ProfitTrends> trends(
    ProfitPeriod granularity, {
    DateTime? from,
    DateTime? to,
  }) async {
    calls.add(
      'trends:${granularity.name}:'
      '${from == null ? '' : '${formatIsoDate(from)}..'}'
      '${to == null ? '-' : formatIsoDate(to)}',
    );
    await gate?.future;
    if (trendsError != null) throw trendsError!;
    if (from != null) {
      // Explicit window: one daily point per date, from [dailyMetrics].
      final points = <TrendPoint>[];
      for (
        var day = dateOnly(from);
        !day.isAfter(to ?? today);
        day = day.add(const Duration(days: 1))
      ) {
        points.add(
          TrendPoint(
            startDate: day,
            endDate: day,
            metrics: dailyMetrics[day] ?? metrics(),
          ),
        );
      }
      return ProfitTrends(
        granularity: granularity,
        currency: 'THB',
        points: points,
      );
    }
    final values = trendMetrics[granularity] ?? [metrics(), metrics()];
    var start = periodStart(to ?? today, granularity);
    final points = <TrendPoint>[];
    for (var i = values.length - 1; i >= 0; i--) {
      points.insert(
        0,
        TrendPoint(
          startDate: start,
          endDate: _periodEnd(start, granularity),
          metrics: values[i],
          movingAverage: i < trendAverages.length ? trendAverages[i] : null,
          trend: i < trendLine.length ? trendLine[i] : null,
        ),
      );
      start = periodStart(start.subtract(const Duration(days: 1)), granularity);
    }
    return ProfitTrends(
      granularity: granularity,
      currency: 'THB',
      points: points,
      analysis: trendAnalysis,
    );
  }

  @override
  Future<WorkPatterns> patterns() async {
    calls.add('patterns');
    await gate?.future;
    if (patternsError != null) throw patternsError!;
    return patternsResult;
  }

  @override
  Future<ProfitHeatmap> heatmap() async {
    calls.add('heatmap');
    await gate?.future;
    if (heatmapError != null) throw heatmapError!;
    return heatmapResult;
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
  String? lastCreateId;
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
  Future<T> create(I input, {String? id}) async {
    calls.add('create');
    lastInput = input;
    lastCreateId = id;
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    final record = build(id ?? _newId(), input, null);
    items.insert(0, record);
    return record;
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
  final timer = MemoryShiftTimerStore();
  final pendingStore = MemoryPendingRecordStore();
  final sender = FakePendingRecordSender();
}

/// The offline queue's storage without the device.
class MemoryPendingRecordStore implements PendingRecordStore {
  final entries = <String, String>{};
  Object? readError;
  Object? writeError;
  int writes = 0;

  List<PendingRecord> of(String userId) =>
      decodePendingRecords(entries[userId]);

  @override
  Future<List<PendingRecord>> read(String userId) async {
    if (readError != null) throw readError!;
    return decodePendingRecords(entries[userId]);
  }

  @override
  Future<void> write(String userId, List<PendingRecord> items) async {
    writes++;
    if (writeError != null) throw writeError!;
    final value = encodePendingRecords(items);
    value == null ? entries.remove(userId) : entries[userId] = value;
  }
}

/// Records what the queue sends. [errors]: thrown by the next sends, in order
/// (`null` = that send succeeds); then [error] for every send.
class FakePendingRecordSender implements PendingRecordSender {
  final sent = <PendingRecord>[];
  final errors = <Object?>[];
  Object? error;
  Completer<void>? gate;
  int attempts = 0;

  @override
  Future<void> send(PendingRecord item) async {
    attempts++;
    await gate?.future;
    final failure = errors.isNotEmpty ? errors.removeAt(0) : error;
    if (failure != null) throw failure;
    sent.add(item);
  }
}

/// The Home timer store without the device: entries per user id, as encoded on disk.
class MemoryShiftTimerStore implements ShiftTimerStore {
  final entries = <String, String>{};
  Object? readError;
  Object? writeError;
  int writes = 0;

  @override
  Future<ShiftTimerState> read(String userId) async {
    if (readError != null) throw readError!;
    return decodeShiftTimer(entries[userId]);
  }

  @override
  Future<void> write(String userId, ShiftTimerState state) async {
    writes++;
    if (writeError != null) throw writeError!;
    final value = encodeShiftTimer(state);
    value == null ? entries.remove(userId) : entries[userId] = value;
  }
}
