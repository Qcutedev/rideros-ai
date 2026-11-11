import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/features/profit/domain/profit_period.dart';
import 'package:rideros_ai/features/profit/domain/profit_records.dart';
import 'package:rideros_ai/features/profit/domain/profit_summary.dart';
import 'package:rideros_ai/features/profit/domain/session_times.dart';

Decimal d(String v) => Decimal.parse(v);

Map<String, Object?> metricsJson({String hours = '7.50'}) => {
  'total_revenue': '1200.00',
  'total_expenses': '150.50',
  'net_profit': '1049.50',
  'working_hours': hours,
  'revenue_per_hour': hours == '0.00' ? null : '160.00',
  'net_profit_per_hour': hours == '0.00' ? null : '139.93',
  'reason': hours == '0.00' ? 'no_working_hours' : null,
  'income_count': 2,
  'expense_count': 1,
  'work_session_count': 1,
};

void main() {
  test('Income parses decimal strings, dates and nulls', () {
    final income = Income.fromJson({
      'id': 'a',
      'occurred_on': '2026-11-09',
      'amount': '800.00',
      'work_session_id': null,
      'order_count': 12,
      'distance_km': '45.20',
      'working_hours': '6.50',
      'source_label': 'Grab',
      'notes': null,
      'is_demo': true,
      'created_at': '2026-11-09T10:00:00Z',
      'updated_at': '2026-11-09T10:00:00Z',
    });
    expect(income.amount, d('800'));
    expect(income.occurredOn, DateTime.utc(2026, 11, 9));
    expect(income.distanceKm, d('45.2'));
    expect(income.workingHours, d('6.5'));
    expect(income.isDemo, isTrue);
  });

  test('IncomeInput sends every field; decimals as strings, nulls clear', () {
    final json = IncomeInput(
      occurredOn: DateTime.utc(2026, 11, 10),
      amount: d('800.5'),
      orderCount: 3,
    ).toJson();
    expect(json, {
      'occurred_on': '2026-11-10',
      'amount': '800.5',
      'work_session_id': null,
      'order_count': 3,
      'distance_km': null,
      'working_hours': null,
      'source_label': null,
      'notes': null,
    });
  });

  test('ExpenseInput never sends work_session_id (keeps an existing link)', () {
    final json = ExpenseInput(
      occurredOn: DateTime.utc(2026, 11, 10),
      category: ExpenseCategory.maintenance,
      amount: d('250'),
    ).toJson();
    expect(json.containsKey('work_session_id'), isFalse);
    expect(json['category'], 'maintenance');
    expect(json['amount'], '250');
    expect(json['description'], isNull);
  });

  test('Expense parses the category enum', () {
    final expense = Expense.fromJson({
      'id': 'e',
      'occurred_on': '2026-11-10',
      'category': 'fuel',
      'amount': '100.00',
      'work_session_id': 's',
      'description': 'PTT',
      'is_demo': false,
      'created_at': '2026-11-10T10:00:00Z',
      'updated_at': '2026-11-10T10:00:00Z',
    });
    expect(expense.category, ExpenseCategory.fuel);
    expect(expense.workSessionId, 's');
  });

  test('WorkSession reads UTC into local time; input writes offsets', () {
    final session = WorkSession.fromJson({
      'id': 's',
      'started_at': '2026-11-10T11:00:00Z',
      'ended_at': '2026-11-10T15:30:00Z',
      'distance_km': null,
      'order_count': null,
      'notes': null,
      'is_demo': false,
      'created_at': '2026-11-10T10:00:00Z',
      'updated_at': '2026-11-10T10:00:00Z',
    });
    expect(session.startedAt.isUtc, isFalse);
    expect(session.duration, const Duration(hours: 4, minutes: 30));

    final json = WorkSessionInput(
      startedAt: DateTime(2026, 11, 10, 18),
      endedAt: DateTime(2026, 11, 10, 22),
    ).toJson();
    final started = json['started_at']! as String;
    expect(started, matches(RegExp(r'^2026-11-10T18:00:00([+-]\d\d:\d\d|Z)$')));
    expect(
      DateTime.parse(started).isAtSameMomentAs(DateTime(2026, 11, 10, 18)),
      isTrue,
    );
  });

  test('ProfitSummary keeps nulls for per-hour values without hours', () {
    final summary = ProfitSummary.fromJson({
      'period': 'week',
      'start_date': '2026-11-09',
      'end_date': '2026-11-15',
      'timezone': 'Asia/Bangkok',
      'currency': 'THB',
      ...metricsJson(hours: '0.00'),
    });
    expect(summary.period, ProfitPeriod.week);
    expect(summary.endDate, DateTime.utc(2026, 11, 15));
    expect(summary.metrics.netProfit, d('1049.5'));
    expect(summary.metrics.netProfitPerHour, isNull);
    expect(summary.metrics.reason, 'no_working_hours');
    expect(summary.metrics.isEmpty, isFalse);
  });

  test('ProfitTrends parses points; isEmpty when nothing was recorded', () {
    Map<String, Object?> point(String start, int count) => {
      'start_date': start,
      'end_date': start,
      ...metricsJson(),
      'income_count': count,
      'expense_count': 0,
      'work_session_count': 0,
    };
    final trends = ProfitTrends.fromJson({
      'granularity': 'day',
      'start_date': '2026-11-09',
      'end_date': '2026-11-10',
      'timezone': 'Asia/Bangkok',
      'currency': 'THB',
      'points': [point('2026-11-09', 0), point('2026-11-10', 1)],
    });
    expect(trends.points, hasLength(2));
    expect(trends.points.last.startDate, DateTime.utc(2026, 11, 10));
    expect(trends.isEmpty, isFalse);
    expect(
      ProfitTrends.fromJson({
        'granularity': 'day',
        'currency': 'THB',
        'points': [point('2026-11-09', 0)],
      }).isEmpty,
      isTrue,
    );
  });

  group('periodStart mirrors the backend buckets', () {
    final tue = DateTime(2026, 11, 10, 14);
    test(
      'day',
      () => expect(
        periodStart(tue, ProfitPeriod.day),
        DateTime.utc(2026, 11, 10),
      ),
    );
    test('week starts Monday', () {
      expect(periodStart(tue, ProfitPeriod.week), DateTime.utc(2026, 11, 9));
      expect(
        periodStart(DateTime.utc(2026, 11, 15), ProfitPeriod.week),
        DateTime.utc(2026, 11, 9),
      );
      expect(
        periodStart(DateTime.utc(2026, 11, 9), ProfitPeriod.week),
        DateTime.utc(2026, 11, 9),
      );
    });
    test(
      'month',
      () =>
          expect(periodStart(tue, ProfitPeriod.month), DateTime.utc(2026, 11)),
    );
  });

  group('sessionTimes', () {
    final date = DateTime.utc(2026, 11, 10);
    test('same day', () {
      final t = sessionTimes(
        date,
        (hour: 9, minute: 0),
        (hour: 13, minute: 30),
      )!;
      expect(t.start, DateTime(2026, 11, 10, 9));
      expect(t.end, DateTime(2026, 11, 10, 13, 30));
    });
    test('an earlier end time means past midnight', () {
      final t = sessionTimes(
        date,
        (hour: 20, minute: 0),
        (hour: 2, minute: 0),
      )!;
      expect(t.end, DateTime(2026, 11, 11, 2));
      expect(t.end.difference(t.start), const Duration(hours: 6));
    });
    test('crosses the month end', () {
      final t = sessionTimes(
        DateTime.utc(2026, 11, 30),
        (hour: 22, minute: 0),
        (hour: 1, minute: 0),
      )!;
      expect(t.end, DateTime(2026, 12, 1, 1));
    });
    test('equal times are rejected', () {
      expect(
        sessionTimes(date, (hour: 9, minute: 0), (hour: 9, minute: 0)),
        isNull,
      );
    });
  });
}
