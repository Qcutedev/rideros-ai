import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/errors/failure_messages.dart';
import 'package:rideros_ai/core/network/api_client.dart';
import 'package:rideros_ai/core/network/token_pair.dart';
import 'package:rideros_ai/core/storage/refresh_token_store.dart';
import 'package:rideros_ai/core/utils/clock.dart';
import 'package:rideros_ai/features/auth/data/auth_repository_impl.dart';
import 'package:rideros_ai/features/profit/data/profit_repositories_impl.dart';
import 'package:rideros_ai/features/profit/domain/profit_summary.dart';
import 'package:rideros_ai/features/profit/presentation/profit_providers.dart';
import 'package:rideros_ai/features/shifts/data/shift_repository_impl.dart';
import 'package:rideros_ai/features/shifts/domain/shift_models.dart';
import 'package:rideros_ai/features/shifts/presentation/shift_labels.dart';
import 'package:rideros_ai/features/shifts/presentation/shift_providers.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fakes.dart';
import '../../helpers/profit_fakes.dart';
import '../../helpers/pump.dart';
import '../../helpers/shift_fakes.dart';

final _input = ShiftScenarioInput(
  name: 'Late night',
  startTime: const ClockTime(22, 0),
  endTime: const ClockTime(2, 30),
  estimationMethod: EstimationMethod.assumption,
  assumptions: ShiftAssumptions(
    ordersPerHour: Decimal.parse('2.5'),
    incomePerOrder: Decimal.parse('45'),
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('th'));

  group('times', () {
    test('ClockTime reads HH:MM:SS and writes HH:MM', () {
      expect(ClockTime.parse('07:05:00'), const ClockTime(7, 5));
      expect(ClockTime.parse('17:30').format(), '17:30');
      expect(const ClockTime(0, 0).format(), '00:00');
      expect(() => ClockTime.parse('1700'), throwsFormatException);
    });

    test('length: an end at or before the start is the next day', () {
      expect(shiftMinutes(const ClockTime(17, 0), const ClockTime(22, 0)), 300);
      expect(shiftMinutes(const ClockTime(22, 0), const ClockTime(2, 30)), 270);
      expect(shiftMinutes(const ClockTime(9, 0), const ClockTime(9, 0)), 0);
    });

    test('valid length is 30 minutes to 16 hours', () {
      expect(isValidShiftLength(29), isFalse);
      expect(isValidShiftLength(30), isTrue);
      expect(isValidShiftLength(960), isTrue);
      expect(isValidShiftLength(961), isFalse);
      expect(isValidShiftLength(0), isFalse);
    });
  });

  group('models', () {
    test('assumption scenario: decimals, details and sources', () {
      final s = ShiftScenario.fromJson(scenarioJson());
      expect(s.startTime, const ClockTime(17, 0));
      expect(s.endTime, const ClockTime(22, 0));
      expect(s.crossesMidnight, isFalse);
      expect(s.plannedWeekday, 4);
      expect(s.estimationMethod, EstimationMethod.assumption);
      expect(s.isEstimate, isTrue);
      expect(s.assumptions.ordersPerHour, Decimal.parse('2.5'));
      expect(s.assumptions.fuelKmPerLiter, isNull);
      expect(s.estimatedNetProfit, Decimal.parse('969.50'));
      expect(s.estimatedNetProfitPerHour, Decimal.parse('193.90'));
      expect(s.hasRange, isFalse);
      final d = s.estimateDetails;
      expect(d.expectedOrders, Decimal.parse('12.5'));
      expect(d.fuelCost, Decimal.parse('130.5'));
      expect(d.sources['depreciation_per_km'], 'scenario');
      expect(d.warnings, isEmpty);
    });

    test('historical scenario: range, basis and window', () {
      final s = ShiftScenario.fromJson(
        scenarioJson(
          method: 'historical',
          start: '22:00:00',
          end: '02:00:00',
          low: '600.00',
          high: '1100.00',
          details: historicalDetailsJson(warnings: ['x']),
        ),
      );
      expect(s.crossesMidnight, isTrue);
      expect(s.hasRange, isTrue);
      final d = s.estimateDetails;
      expect(d.usesSameWeekday, isTrue);
      expect(d.nDays, 6);
      expect(d.windowStart, DateTime.utc(2026, 8, 19));
      expect(d.revenuePerHour, Decimal.parse('210'));
      expect(d.warnings, ['x']);
    });

    test(
      'input JSON: HH:MM times, null weekday sent, empty assumptions not',
      () {
        final json = _input.toJson();
        expect(json['start_time'], '22:00');
        expect(json['end_time'], '02:30');
        expect(json.containsKey('planned_weekday'), isTrue);
        expect(json['planned_weekday'], isNull);
        expect(json['estimation_method'], 'assumption');
        expect(json['assumptions'], {
          'orders_per_hour': '2.5',
          'income_per_order': '45',
        });
        expect(json.containsKey('actual_work_session_id'), isFalse);
      },
    );

    test('comparison keeps the order and both winners', () {
      final c = ShiftComparison.fromJson({
        'scenarios': [scenarioJson(id: 'b'), scenarioJson(id: 'a')],
        'best_net_profit_id': 'a',
        'best_net_profit_per_hour_id': 'b',
      });
      expect(c.scenarios.map((s) => s.id), ['b', 'a']);
      expect(c.bestNetProfitId, 'a');
      expect(c.bestNetProfitPerHourId, 'b');
    });
  });

  group('labels', () {
    test('weekday 0 is Monday, null is every day', () {
      expect(weekdayLabel(t, 0), 'วันจันทร์');
      expect(weekdayLabel(t, 6), 'วันอาทิตย์');
      expect(plannedDayLabel(t, null), t.shiftAnyDay);
    });

    test('ML is never named as an available method', () {
      expect(methodLabel(t, EstimationMethod.ml), t.shiftMethodUnavailable);
    });

    test('warnings and failures have Thai text', () {
      expect(
        warningLabel(t, ShiftWarning.distanceCostsNotIncluded),
        t.shiftWarningDistance,
      );
      expect(warningLabel(t, 'new_code'), t.shiftWarningOther('new_code'));
      for (final (code, text) in [
        ('invalid_shift_length', t.failureInvalidShiftLength),
        ('missing_assumption', t.failureMissingAssumption),
        ('insufficient_history', t.failureInsufficientHistory),
        ('estimation_method_unavailable', t.failureEstimationMethodUnavailable),
      ]) {
        expect(
          failureMessage(t, ApiFailure(statusCode: 400, code: code)),
          text,
        );
      }
      expect(
        failureMessage(
          t,
          const ApiFailure(statusCode: 404, code: 'shift_scenario_not_found'),
        ),
        t.failureNotFound,
      );
    });

    test('money with the profile currency, plain without', () {
      expect(shiftMoney(Decimal.parse('1049.5'), 'THB'), '฿1,049.50');
      expect(shiftMoney(Decimal.parse('-80'), null), '-80.00');
    });
  });

  group('repository over HTTP', () {
    late FakeHttpAdapter adapter;
    late ProviderContainer container;

    setUp(() async {
      adapter = FakeHttpAdapter((o) => json(200, scenarioJson()));
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

    Map<String, dynamic> body(RequestOptions r) =>
        (r.data is String ? jsonDecode(r.data as String) : r.data)
            as Map<String, dynamic>;

    test('list with cursor', () async {
      adapter.handler = (o) => json(200, {
        'items': [scenarioJson()],
        'next_cursor': null,
      });
      final page = await container
          .read(shiftRepositoryProvider)
          .list(cursor: 'c-1');
      final r = adapter.requests.single;
      expect(r.method, 'GET');
      expect(r.path, '/shift-scenarios');
      expect(r.queryParameters, {'cursor': 'c-1'});
      expect(r.headers['Authorization'], 'Bearer access-1');
      expect(page.items.single.name, 'Friday evening');
      expect(page.hasMore, isFalse);
    });

    test('create, update, re-estimate, link, delete', () async {
      final repo = container.read(shiftRepositoryProvider);
      await repo.create(_input);
      await repo.update('s-1', _input);
      await repo.reEstimate('s-1');
      await repo.linkWorkSession('s-1', 'w-1');
      await repo.linkWorkSession('s-1', null);
      adapter.handler = (o) => json(204);
      await repo.delete('s-1');
      expect(
        [for (final r in adapter.requests) '${r.method} ${r.path}'],
        [
          'POST /shift-scenarios',
          'PATCH /shift-scenarios/s-1',
          'POST /shift-scenarios/s-1/estimate',
          'PATCH /shift-scenarios/s-1',
          'PATCH /shift-scenarios/s-1',
          'DELETE /shift-scenarios/s-1',
        ],
      );
      expect(body(adapter.requests[0])['start_time'], '22:00');
      expect(body(adapter.requests[3]), {'actual_work_session_id': 'w-1'});
      expect(body(adapter.requests[4]), {'actual_work_session_id': null});
    });

    test('compare sends the ids in order', () async {
      adapter.handler = (o) => json(200, {
        'scenarios': [scenarioJson(id: 'b'), scenarioJson(id: 'a')],
        'best_net_profit_id': 'b',
        'best_net_profit_per_hour_id': 'b',
      });
      final c = await container.read(shiftRepositoryProvider).compare([
        'b',
        'a',
      ]);
      final r = adapter.requests.single;
      expect(r.path, '/shift-scenarios/compare');
      expect(body(r), {
        'ids': ['b', 'a'],
      });
      expect(c.bestNetProfitId, 'b');
    });

    test('server errors become typed failures', () async {
      adapter.handler = (o) => apiError(400, 'invalid_shift_length');
      await expectLater(
        container.read(shiftRepositoryProvider).create(_input),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            'invalid_shift_length',
          ),
        ),
      );
    });

    test('trends with an explicit window sends from', () async {
      adapter.handler = (o) => json(200, {
        'granularity': 'day',
        'start_date': '2026-08-19',
        'end_date': '2026-11-10',
        'timezone': 'Asia/Bangkok',
        'currency': 'THB',
        'points': <Object>[],
      });
      await container
          .read(profitRepositoryProvider)
          .trends(ProfitPeriod.day, from: DateTime.utc(2026, 8, 19));
      expect(adapter.requests.single.queryParameters, {
        'granularity': 'day',
        'from': '2026-08-19',
      });
    });
  });

  group('providers', () {
    late FakeShiftRepository repo;
    late FakeProfitRepository profit;
    late ProviderContainer container;

    setUp(() {
      repo = FakeShiftRepository(
        items: [
          scenario(id: 'a'),
          scenario(id: 'b'),
          scenario(id: 'c'),
          scenario(id: 'd'),
          scenario(id: 'e'),
          scenario(id: 'f'),
        ],
      );
      profit = FakeProfitRepository();
      container = ProviderContainer.test(
        retry: (retryCount, error) => null,
        overrides: [
          shiftRepositoryProvider.overrideWithValue(repo),
          profitRepositoryProvider.overrideWithValue(profit),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          clockProvider.overrideWithValue(testNow),
        ],
      );
    });

    test('selection keeps the pick order and stops at five', () {
      container.listen(shiftSelectionProvider, (_, _) {});
      final selection = container.read(shiftSelectionProvider.notifier);
      for (final id in ['c', 'a', 'b', 'd', 'e', 'f']) {
        selection.toggle(id);
      }
      expect(container.read(shiftSelectionProvider), ['c', 'a', 'b', 'd', 'e']);
      selection.toggle('a');
      expect(container.read(shiftSelectionProvider), ['c', 'b', 'd', 'e']);
      selection.remove('zzz');
      selection.remove('d');
      expect(container.read(shiftSelectionProvider), ['c', 'b', 'e']);
      selection.clear();
      expect(container.read(shiftSelectionProvider), isEmpty);
    });

    test('worked days: the last 84 days with hours > 0', () async {
      final today = DateTime.utc(2026, 11, 10);
      profit.dailyMetrics[today] = metrics(hours: '4.00');
      profit.dailyMetrics[today.subtract(const Duration(days: 83))] = metrics(
        hours: '1.50',
      );
      profit.dailyMetrics[today.subtract(const Duration(days: 84))] = metrics(
        hours: '8.00', // outside the window
      );
      profit.dailyMetrics[today.subtract(const Duration(days: 3))] = metrics(
        revenue: '100.00', // income without hours
      );
      container.listen(workedHistoryDaysProvider, (_, _) {});
      expect(await container.read(workedHistoryDaysProvider.future), 2);
      expect(profit.calls.single, 'trends:day:2026-08-19..-');

      // A TrueProfit change asks again.
      container.read(profitDataRevisionProvider.notifier).bump();
      await container.read(workedHistoryDaysProvider.future);
      expect(profit.calls, hasLength(2));
    });

    test('save returns the estimate and reloads the list', () async {
      container.listen(shiftListProvider, (_, _) {});
      await container.read(shiftListProvider.future);
      final controller = container.read(shiftFormProvider.notifier);
      expect(await controller.save(null, _input), isTrue);
      expect(controller.saved!.name, 'Late night');
      expect(controller.saved!.durationMinutes, 270);
      final list = await container.read(shiftListProvider.future);
      expect(list.items.first.name, 'Late night');
      expect(repo.calls.where((c) => c.startsWith('list')), hasLength(2));
    });

    test(
      'delete drops the id from the selection even if the screen closed',
      () async {
        container.listen(shiftSelectionProvider, (_, _) {});
        container.read(shiftSelectionProvider.notifier)
          ..toggle('a')
          ..toggle('b');
        repo.actionGate = Completer<void>();
        final sub = container.listen(shiftDetailActionProvider, (_, _) {});
        final pending = container
            .read(shiftDetailActionProvider.notifier)
            .delete('a');
        sub.close();
        await container.pump();
        repo.actionGate!.complete();
        expect(await pending, isTrue);
        expect(container.read(shiftSelectionProvider), ['b']);
        expect(container.read(shiftDataRevisionProvider), 1);
      },
    );

    test('a failed re-estimate keeps the typed failure', () async {
      repo.actionError = const ApiFailure(
        statusCode: 400,
        code: 'insufficient_history',
      );
      container.listen(shiftDetailActionProvider, (_, _) {});
      final ok = await container
          .read(shiftDetailActionProvider.notifier)
          .reEstimate('a');
      expect(ok, isFalse);
      expect(
        container.read(shiftDetailActionProvider).error,
        isA<ApiFailure>(),
      );
      expect(container.read(shiftDataRevisionProvider), 0);
    });
  });
}
