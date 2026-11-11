import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/network/api_client.dart';
import 'package:rideros_ai/core/network/token_pair.dart';
import 'package:rideros_ai/core/storage/refresh_token_store.dart';
import 'package:rideros_ai/features/profit/data/profit_repositories_impl.dart';
import 'package:rideros_ai/features/profit/domain/profit_records.dart';
import 'package:rideros_ai/features/profit/domain/profit_summary.dart';

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

  test('offline becomes a NetworkFailure', () async {
    adapter.handler = offline;
    await expectLater(
      container.read(profitRepositoryProvider).summary(ProfitPeriod.day),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
