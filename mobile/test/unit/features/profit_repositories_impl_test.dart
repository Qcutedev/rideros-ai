import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/network/api_client.dart';
import 'package:rideros_ai/core/network/token_pair.dart';
import 'package:rideros_ai/core/storage/refresh_token_store.dart';
import 'package:rideros_ai/features/profit/data/profit_repositories_impl.dart';
import 'package:rideros_ai/features/profit/domain/profit_heatmap.dart';
import 'package:rideros_ai/features/profit/domain/profit_records.dart';
import 'package:rideros_ai/features/profit/domain/profit_summary.dart';
import 'package:rideros_ai/features/profit/domain/work_patterns.dart';

import '../../helpers/fake_http_adapter.dart';

Map<String, Object?> incomeJson(String id) => {
  'id': id,
  'occurred_on': '2026-11-10',
  'amount': '800.00',
  'work_session_id': null,
  'order_count': null,
  'distance_km': null,
  'working_hours': null,
  'source_label': null,
  'notes': null,
  'is_demo': false,
  'created_at': '2026-11-10T10:00:00Z',
  'updated_at': '2026-11-10T10:00:00Z',
};

Map<String, Object?> metricsJson() => {
  'total_revenue': '0.00',
  'total_expenses': '0.00',
  'net_profit': '0.00',
  'working_hours': '0.00',
  'revenue_per_hour': null,
  'net_profit_per_hour': null,
  'reason': 'no_working_hours',
  'income_count': 0,
  'expense_count': 0,
  'work_session_count': 0,
};

/// Real dio + interceptor + repositories against a fake HTTP adapter.
void main() {
  late FakeHttpAdapter adapter;
  late ProviderContainer container;

  setUp(() async {
    adapter = FakeHttpAdapter((o) => json(404));
    container = ProviderContainer.test(
      retry: (retryCount, error) => null,
      overrides: [
        refreshTokenStoreProvider.overrideWithValue(
          InMemoryRefreshTokenStore(),
        ),
        baseDioProvider.overrideWith(
          (ref) =>
              Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
                ..httpClientAdapter = adapter,
        ),
      ],
    );
    await container
        .read(sessionTokenManagerProvider)
        .save(
          TokenPair(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
            expiresIn: 900,
            refreshExpiresAt: DateTime.utc(2026, 12, 10),
          ),
        );
  });

  test('list sends cursor and inclusive dates, parses the page', () async {
    adapter.handler = (o) => json(200, {
      'items': [incomeJson('a'), incomeJson('b')],
      'next_cursor': 'next-1',
    });
    final page = await container
        .read(incomeRepositoryProvider)
        .list(
          cursor: 'c-0',
          from: DateTime.utc(2026, 11, 1),
          to: DateTime.utc(2026, 11, 10),
        );
    final request = adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.path, '/income');
    expect(request.queryParameters, {
      'cursor': 'c-0',
      'from': '2026-11-01',
      'to': '2026-11-10',
    });
    expect(request.headers['Authorization'], 'Bearer access-1');
    expect(page.items.map((i) => i.id), ['a', 'b']);
    expect(page.hasMore, isTrue);
  });

  test('list without filters sends no query parameters', () async {
    adapter.handler = (o) =>
        json(200, {'items': <Object>[], 'next_cursor': null});
    final page = await container.read(expenseRepositoryProvider).list();
    expect(adapter.requests.single.path, '/expenses');
    expect(adapter.requests.single.queryParameters, isEmpty);
    expect(page.hasMore, isFalse);
  });

  test('create posts JSON, update patches, delete deletes', () async {
    adapter.handler = (o) => switch (o.method) {
      'DELETE' => json(204),
      'POST' => json(201, incomeJson('new')),
      _ => json(200, incomeJson('a')),
    };
    final repo = container.read(incomeRepositoryProvider);
    final input = IncomeInput(
      occurredOn: DateTime.utc(2026, 11, 10),
      amount: Decimal.parse('800'),
    );
    expect((await repo.create(input)).id, 'new');
    await repo.update('a', input);
    await repo.delete('a');
    final [create, update, delete] = adapter.requests;
    expect((create.method, create.path), ('POST', '/income'));
    expect((create.data as Map)['amount'], '800');
    expect((update.method, update.path), ('PATCH', '/income/a'));
    expect((delete.method, delete.path), ('DELETE', '/income/a'));
  });

  test('a missing record maps to a typed 404 failure', () async {
    adapter.handler = (o) => apiError(404, 'work_session_not_found');
    await expectLater(
      container.read(workSessionRepositoryProvider).get('x'),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.statusCode, 'status', 404)
            .having((f) => f.code, 'code', 'work_session_not_found'),
      ),
    );
  });

  test('a 409 overlap keeps its code', () async {
    adapter.handler = (o) => apiError(409, ApiErrorCode.workSessionOverlap);
    await expectLater(
      container
          .read(workSessionRepositoryProvider)
          .create(
            WorkSessionInput(
              startedAt: DateTime.utc(2026, 11, 10, 1),
              endedAt: DateTime.utc(2026, 11, 10, 5),
            ),
          ),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.code,
          'code',
          ApiErrorCode.workSessionOverlap,
        ),
      ),
    );
    expect(
      (adapter.requests.single.data as Map)['started_at'],
      '2026-11-10T01:00:00Z',
    );
  });

  test('summary and trends send period/date and granularity/to', () async {
    adapter.handler = (o) => o.path == '/profit/summary'
        ? json(200, {
            'period': 'month',
            'start_date': '2026-10-01',
            'end_date': '2026-10-31',
            'timezone': 'Asia/Bangkok',
            'currency': 'THB',
            ...metricsJson(),
          })
        : json(200, {
            'granularity': 'month',
            'start_date': '2025-11-01',
            'end_date': '2026-10-31',
            'timezone': 'Asia/Bangkok',
            'currency': 'THB',
            'points': [
              {
                'start_date': '2026-10-01',
                'end_date': '2026-10-31',
                ...metricsJson(),
              },
            ],
          });
    final repo = container.read(profitRepositoryProvider);
    final summary = await repo.summary(
      ProfitPeriod.month,
      date: DateTime.utc(2026, 10, 15),
    );
    final trends = await repo.trends(
      ProfitPeriod.month,
      to: DateTime.utc(2026, 10, 15),
    );
    await repo.summary(ProfitPeriod.day);
    expect(adapter.requests[0].queryParameters, {
      'period': 'month',
      'date': '2026-10-15',
    });
    expect(adapter.requests[1].queryParameters, {
      'granularity': 'month',
      'to': '2026-10-15',
    });
    expect(adapter.requests[2].queryParameters, {'period': 'day'});
    expect(summary.endDate, DateTime.utc(2026, 10, 31));
    expect(trends.points.single.startDate, DateTime.utc(2026, 10));
  });

  test('patterns parses groups, codes and nullable estimates', () async {
    adapter.handler = (o) => json(200, {
      'status': 'ok',
      'window_days': 180,
      'start_date': '2026-05-15',
      'end_date': '2026-11-10',
      'session_count': 37,
      'min_sessions': 30,
      'k': 2,
      'silhouette': 0.71,
      'null_silhouette': 0.42,
      'stability': 1.0,
      'groups': [
        {
          'time_of_day': 'evening',
          'length': 'short',
          'day_type': 'weekday',
          'mean_start_minute': 1110,
          'mean_hours': '3.2',
          'weekend_share': 0.0,
          'session_count': 25,
          'share': 0.676,
          'profit_session_count': 25,
          'revenue_per_hour': '92.59',
          'net_profit_per_hour': '74.07',
        },
        {
          'time_of_day': 'morning',
          'length': 'long',
          'day_type': 'weekend',
          'mean_start_minute': 540,
          'mean_hours': '8.5',
          'weekend_share': 1.0,
          'session_count': 12,
          'share': 0.324,
          'profit_session_count': 0,
          'revenue_per_hour': null,
          'net_profit_per_hour': null,
        },
      ],
      'timezone': 'Asia/Bangkok',
      'currency': 'THB',
    });
    final patterns = await container.read(profitRepositoryProvider).patterns();
    expect(adapter.requests.single.path, '/profit/patterns');
    expect(patterns.status, PatternStatus.ok);
    expect(patterns.sessionsMissing, 0);
    final [evening, weekend] = patterns.groups;
    expect(evening.timeOfDay, ShiftTimeOfDay.evening);
    expect(evening.netProfitPerHour, Decimal.parse('74.07'));
    expect(evening.meanStartMinute, 1110);
    expect(weekend.dayType, ShiftDayType.weekend);
    expect(weekend.length, ShiftLength.long);
    expect(weekend.netProfitPerHour, isNull);
    expect(weekend.meanHours, Decimal.parse('8.5'));
  });

  test('patterns: insufficient data counts the missing sessions', () async {
    adapter.handler = (o) => json(200, {
      'status': 'insufficient_data',
      'window_days': 180,
      'start_date': '2026-05-15',
      'end_date': '2026-11-10',
      'session_count': 12,
      'min_sessions': 30,
      'k': null,
      'silhouette': null,
      'null_silhouette': null,
      'stability': null,
      'groups': <Object>[],
      'timezone': 'Asia/Bangkok',
      'currency': 'THB',
    });
    final patterns = await container.read(profitRepositoryProvider).patterns();
    expect(patterns.status, PatternStatus.insufficientData);
    expect(patterns.sessionsMissing, 18);
    expect(patterns.groups, isEmpty);
  });

  Map<String, Object?> heatmapJson({
    String status = 'ok',
    int sessions = 14,
    List<Object> cells = const [],
  }) => {
    'status': status,
    'window_days': 90,
    'start_date': '2026-08-13',
    'end_date': '2026-11-10',
    'slot_hours': 2,
    'session_count': sessions,
    'min_sessions': 10,
    'min_cell_sessions': 2,
    'min_cell_hours': 1,
    'excluded_session_count': 3,
    'excluded_income_count': 2,
    'excluded_expense_count': 1,
    'hours': '42.5',
    'revenue_per_hour': '190.00',
    'net_profit_per_hour': '160.40',
    'cells': cells,
    'timezone': 'Asia/Bangkok',
    'currency': 'THB',
  };

  test('heatmap parses cells, counts and nullable estimates', () async {
    adapter.handler = (o) => json(
      200,
      heatmapJson(
        cells: [
          {
            'weekday': 0,
            'slot': 9,
            'hours': '20.0',
            'session_count': 10,
            'revenue_per_hour': '200.00',
            'net_profit_per_hour': '180.00',
          },
          {
            'weekday': 4,
            'slot': 11,
            'hours': '0.5',
            'session_count': 1,
            'revenue_per_hour': null,
            'net_profit_per_hour': null,
          },
        ],
      ),
    );
    final map = await container.read(profitRepositoryProvider).heatmap();
    expect(adapter.requests.single.path, '/profit/heatmap');
    expect(map.status, HeatmapStatus.ok);
    expect(map.slotsPerDay, 12);
    expect(map.sessionsMissing, 0);
    expect(map.startDate, DateTime.utc(2026, 8, 13));
    expect((map.excludedSessionCount, map.excludedIncomeCount), (3, 2));
    expect(map.excludedExpenseCount, 1);
    expect(map.hours, Decimal.parse('42.5'));
    expect(map.netProfitPerHour, Decimal.parse('160.40'));
    final monday = map.cellAt(0, 9)!;
    expect(monday.netProfitPerHour, Decimal.parse('180.00'));
    expect(monday.revenuePerHour, Decimal.parse('200.00'));
    expect((monday.sessionCount, monday.hasEstimate), (10, true));
    final thin = map.cellAt(4, 11)!;
    expect((thin.hasEstimate, thin.revenuePerHour), (false, null));
    expect(map.cellAt(1, 0), isNull);
  });

  test('heatmap: unknown status is a format error', () async {
    adapter.handler = (o) => json(200, heatmapJson(status: 'maybe'));
    await expectLater(
      container.read(profitRepositoryProvider).heatmap(),
      throwsA(isA<AppFailure>()),
    );
  });

  test('offline becomes a NetworkFailure', () async {
    adapter.handler = offline;
    await expectLater(
      container.read(profitRepositoryProvider).summary(ProfitPeriod.day),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
