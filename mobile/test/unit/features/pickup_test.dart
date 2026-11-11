import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/network/api_client.dart';
import 'package:rideros_ai/core/network/token_pair.dart';
import 'package:rideros_ai/core/storage/refresh_token_store.dart';
import 'package:rideros_ai/features/pickup/data/pickup_repository_impl.dart';
import 'package:rideros_ai/features/pickup/domain/pickup_models.dart';
import 'package:rideros_ai/features/pickup/domain/pickup_times.dart';
import 'package:rideros_ai/features/pickup/presentation/pickup_labels.dart';
import 'package:rideros_ai/features/pickup/presentation/pickup_providers.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pickup_fakes.dart';
import '../../helpers/pump.dart';

void main() {
  group('models', () {
    test('analytics: decimals as strings, 24 cells per day type', () {
      final a = RestaurantAnalytics.fromJson(analyticsJson());
      expect(a.restaurant.supportsPrediction, isTrue);
      expect(a.dataAvailability, DataAvailability.sufficient);
      expect(a.overall!.medianMin, Decimal.parse('10.433'));
      expect(a.overall!.peakHour, 12);
      expect(a.byHour['weekday'], hasLength(24));
      expect(a.byHour['weekday']![3].medianMin, isNull);
      expect(a.byHour['weekday']![10].medianMin, Decimal.parse('8'));
    });

    test('own restaurant: no overall, location kept', () {
      final r = Restaurant.fromJson(
        restaurantJson(own: true, location: {'lat': 13.75, 'lng': 100.5}),
      );
      expect(r.isOwn, isTrue);
      expect(r.supportsPrediction, isFalse);
      expect(r.dataAvailability, isNull);
      expect(r.location, const Coordinates(lat: 13.75, lng: 100.5));
      final a = RestaurantAnalytics.fromJson(
        analyticsJson(restaurant: restaurantJson(own: true)),
      );
      expect(a.overall, isNull);
    });

    test('prediction: interval, warnings, local requested time', () {
      final p = Prediction.fromJson(
        predictionJson(
          warnings: ['foreign_dataset', 'limited_restaurant_data'],
        ),
      );
      expect(p.interval.low, Decimal.parse('5.04'));
      expect(p.interval.high, Decimal.parse('19.99'));
      expect(p.interval.nominalCoverage, 0.8);
      expect(p.requestedAt.isUtc, isFalse);
      expect(p.requestedAt, DateTime.utc(2026, 11, 10, 7, 7).toLocal());
      expect(p.warnings, hasLength(2));
    });

    test('model info getters read the server maps', () {
      final m = ModelInfo.fromJson(modelInfoJson());
      expect(m.testMae, closeTo(4.5088, 1e-4));
      expect(m.baselineMae, closeTo(4.6359, 1e-4));
      expect(m.testOrders, 64701);
      expect(m.algorithm, 'xgboost');
      expect(m.nominalCoverage, 0.8);
      expect(m.testCoverage, closeTo(0.816, 1e-3));
      expect(m.meanWidthMinutes, closeTo(14.95, 1e-2));
    });

    test('model info without baseline or coverage gives nulls', () {
      final json = modelInfoJson()
        ..['baseline_test_metrics'] = null
        ..['interval'] = <String, Object?>{};
      final m = ModelInfo.fromJson(json);
      expect(m.baselineMae, isNull);
      expect(m.testCoverage, isNull);
    });

    test('pickup log input sends offsets and null notes', () {
      final json = PickupLogInput(
        restaurantId: 'r-1',
        arrivedAt: DateTime.utc(2026, 11, 10, 7),
        pickedUpAt: DateTime.utc(2026, 11, 10, 7, 12),
      ).toJson();
      expect(json, {
        'restaurant_id': 'r-1',
        'arrived_at': '2026-11-10T07:00:00Z',
        'picked_up_at': '2026-11-10T07:12:00Z',
        'notes': null,
      });
    });
  });

  group('pickupTimes', () {
    final day = DateTime.utc(2026, 11, 10);

    test('same day', () {
      final t = pickupTimes(day, (hour: 18, minute: 0), (hour: 18, minute: 12));
      expect(t.arrivedAt, DateTime(2026, 11, 10, 18));
      expect(t.pickedUpAt, DateTime(2026, 11, 10, 18, 12));
      expect(isWaitTooLong(t.arrivedAt, t.pickedUpAt), isFalse);
    });

    test('equal times are a wait of 0', () {
      final t = pickupTimes(day, (hour: 9, minute: 5), (hour: 9, minute: 5));
      expect(t.pickedUpAt, t.arrivedAt);
    });

    test('pickup before arrival means the next day', () {
      final t = pickupTimes(day, (hour: 23, minute: 50), (hour: 0, minute: 10));
      expect(t.pickedUpAt, DateTime(2026, 11, 11, 0, 10));
      expect(isWaitTooLong(t.arrivedAt, t.pickedUpAt), isFalse);
    });

    test('3 hours is allowed, a minute more is not', () {
      final ok = pickupTimes(day, (hour: 12, minute: 0), (hour: 15, minute: 0));
      expect(isWaitTooLong(ok.arrivedAt, ok.pickedUpAt), isFalse);
      final tooLong = pickupTimes(
        day,
        (hour: 12, minute: 0),
        (hour: 15, minute: 1),
      );
      expect(isWaitTooLong(tooLong.arrivedAt, tooLong.pickedUpAt), isTrue);
      // Earlier clock time = next day = far over 3 hours.
      final wrapped = pickupTimes(
        day,
        (hour: 14, minute: 0),
        (hour: 13, minute: 50),
      );
      expect(isWaitTooLong(wrapped.arrivedAt, wrapped.pickedUpAt), isTrue);
    });
  });

  group('labels', () {
    test('interval widened outwards to whole minutes', () {
      final interval = PredictionInterval(
        low: Decimal.parse('5.04'),
        high: Decimal.parse('19.99'),
      );
      expect(minutesRange(t, interval), '5–20 นาที');
      final exact = PredictionInterval(
        low: Decimal.parse('6'),
        high: Decimal.parse('21'),
      );
      expect(minutesRange(t, exact), '6–21 นาที');
    });

    test('minutes1 keeps one decimal at most', () {
      expect(minutes1(Decimal.parse('10.433')), '10.4');
      expect(minutes1(Decimal.parse('12.00')), '12');
      expect(minutes1(Decimal.parse('13.992')), '14');
    });

    test('foreign_dataset always first and never twice', () {
      final p = Prediction.fromJson(
        predictionJson(
          warnings: ['limited_restaurant_data', 'foreign_dataset'],
        ),
      );
      expect(predictionWarnings(p), [
        'foreign_dataset',
        'limited_restaurant_data',
      ]);
      final none = Prediction.fromJson(predictionJson(warnings: []));
      expect(predictionWarnings(none), ['foreign_dataset']);
      expect(
        predictionWarningText(t, 'something_new'),
        t.predictionWarningOther('something_new'),
      );
    });
  });

  group('repository over HTTP', () {
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

    test('restaurants sends q, source and cursor', () async {
      adapter.handler = (o) => json(200, {
        'items': [restaurantJson()],
        'next_cursor': 'n-1',
      });
      final page = await container
          .read(pickupRepositoryProvider)
          .restaurants(
            query: 'POI',
            source: RestaurantSourceFilter.own,
            cursor: 'c-0',
          );
      final r = adapter.requests.single;
      expect(r.path, '/pickup/restaurants');
      expect(r.queryParameters, {
        'q': 'POI',
        'source': 'user',
        'cursor': 'c-0',
      });
      expect(r.headers['Authorization'], 'Bearer access-1');
      expect(page.items.single.name, 'POI-1');
      expect(page.hasMore, isTrue);
    });

    test('restaurants without filters sends nothing', () async {
      adapter.handler = (o) =>
          json(200, {'items': <Object>[], 'next_cursor': null});
      await container.read(pickupRepositoryProvider).restaurants();
      expect(adapter.requests.single.queryParameters, isEmpty);
    });

    test(
      'predict posts the restaurant only; 503 is model_unavailable',
      () async {
        adapter.handler = (o) => json(201, predictionJson());
        final p = await container.read(pickupRepositoryProvider).predict('r-1');
        expect(adapter.requests.single.method, 'POST');
        expect(adapter.requests.single.path, '/pickup/predictions');
        expect(adapter.requests.single.data, {'restaurant_id': 'r-1'});
        expect(p.modelVersion, '1.0.0');

        adapter.handler = (o) => apiError(503, 'model_unavailable');
        await expectLater(
          container.read(pickupRepositoryProvider).predict('r-1'),
          throwsA(
            isA<ApiFailure>().having(
              (f) => f.code,
              'code',
              ApiErrorCode.modelUnavailable,
            ),
          ),
        );
      },
    );

    test(
      'analytics, wait stats, model, logs, delete hit their paths',
      () async {
        adapter.handler = (o) => switch ((o.method, o.path)) {
          ('GET', '/pickup/restaurants/r-1/analytics') => json(
            200,
            analyticsJson(),
          ),
          ('GET', '/pickup/restaurants/r-1/wait-stats') => json(
            200,
            waitStatsJson(n: 6, median: '7.50', p80: '9.00', confidence: 'low'),
          ),
          ('GET', '/pickup/model') => json(200, modelInfoJson()),
          ('GET', '/pickup/logs') => json(200, {
            'items': [logJson()],
            'next_cursor': null,
          }),
          ('GET', '/pickup/predictions') => json(200, {
            'items': [predictionJson()],
            'next_cursor': null,
          }),
          ('DELETE', '/pickup/logs/l-1') => json(204),
          _ => json(404),
        };
        final repo = container.read(pickupRepositoryProvider);
        expect((await repo.analytics('r-1')).overall!.nOrders, 1267);
        final wait = await repo.waitStats('r-1');
        expect(wait.confidence, WaitConfidence.low);
        expect(wait.medianMinutes, Decimal.parse('7.5'));
        expect((await repo.modelInfo()).version, '1.0.0');
        expect(
          (await repo.logs()).items.single.waitMinutes,
          Decimal.fromInt(12),
        );
        expect((await repo.predictions()).items, hasLength(1));
        await repo.deleteLog('l-1');
        expect(adapter.requests.last.method, 'DELETE');
      },
    );

    test('create log and restaurant post JSON; errors are typed', () async {
      adapter.handler = (o) => switch (o.path) {
        '/pickup/logs' => apiError(400, 'pickup_wait_too_long'),
        '/pickup/restaurants' => json(
          201,
          restaurantJson(id: 'own-1', name: 'Kitchen', own: true),
        ),
        _ => json(404),
      };
      final repo = container.read(pickupRepositoryProvider);
      final created = await repo.createRestaurant(
        const RestaurantInput(
          name: 'Kitchen',
          location: Coordinates(lat: 13.7, lng: 100.5),
        ),
      );
      expect(adapter.requests.last.data, {
        'name': 'Kitchen',
        'location': {'lat': 13.7, 'lng': 100.5},
      });
      expect(created.isOwn, isTrue);
      await expectLater(
        repo.createLog(
          PickupLogInput(
            restaurantId: 'r-1',
            arrivedAt: DateTime.utc(2026),
            pickedUpAt: DateTime.utc(2026, 1, 1, 4),
          ),
        ),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            ApiErrorCode.pickupWaitTooLong,
          ),
        ),
      );
    });
  });

  group('providers', () {
    late FakePickupRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = FakePickupRepository();
      container = ProviderContainer.test(
        retry: (retryCount, error) => null,
        overrides: [pickupRepositoryProvider.overrideWithValue(repo)],
      );
    });

    test('restaurant list per query; a new log reloads wait stats', () async {
      const query = RestaurantQuery(
        text: 'poi-2',
        source: RestaurantSourceFilter.dataset,
      );
      container.listen(restaurantListProvider(query), (_, _) {});
      final state = await container.read(restaurantListProvider(query).future);
      expect(state.items.map((r) => r.id), ['r-2']);
      expect(repo.calls.last, 'restaurants:poi-2:dataset:-');

      container.listen(waitStatsProvider('r-1'), (_, _) {});
      await container.read(waitStatsProvider('r-1').future);
      final before = repo.calls.where((c) => c == 'wait:r-1').length;
      final ok = await container
          .read(pickupLogFormProvider.notifier)
          .createLog(
            PickupLogInput(
              restaurantId: 'r-1',
              arrivedAt: DateTime(2026, 11, 10, 12),
              pickedUpAt: DateTime(2026, 11, 10, 12, 8),
            ),
          );
      expect(ok, isTrue);
      await container.read(waitStatsProvider('r-1').future);
      expect(repo.calls.where((c) => c == 'wait:r-1').length, before + 1);
    });

    test('a delete still refreshes when its screen closed meanwhile', () async {
      repo.logItems.add(PickupLog.fromJson(logJson()));
      repo.saveGate = Completer<void>();
      final sub = container.listen(pickupLogDeleteProvider, (_, _) {});
      final pending = container
          .read(pickupLogDeleteProvider.notifier)
          .deleteLog('l-1');
      sub.close();
      await container.pump();
      repo.saveGate!.complete();
      expect(await pending, isTrue);
      expect(container.read(pickupDataRevisionProvider), 1);
      expect(repo.logItems, isEmpty);
    });

    test('a failed save keeps the typed failure', () async {
      repo.saveError = const ApiFailure(
        statusCode: 400,
        code: 'invalid_pickup_times',
      );
      final ok = await container
          .read(ownRestaurantFormProvider.notifier)
          .createRestaurant(const RestaurantInput(name: 'X'));
      expect(ok, isFalse);
      expect(
        container.read(ownRestaurantFormProvider).error,
        isA<ApiFailure>(),
      );
    });
  });
}
