import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/routes.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/pickup/domain/pickup_models.dart';
import 'package:rideros_ai/features/pickup/presentation/model_info_screen.dart';
import 'package:rideros_ai/features/pickup/presentation/own_restaurant_form_screen.dart';
import 'package:rideros_ai/features/pickup/presentation/pickup_log_form_screen.dart';
import 'package:rideros_ai/features/pickup/presentation/pickup_logs_screen.dart';
import 'package:rideros_ai/features/pickup/presentation/pickup_search_screen.dart';
import 'package:rideros_ai/features/pickup/presentation/prediction_history_screen.dart';
import 'package:rideros_ai/features/pickup/presentation/prediction_result_screen.dart';
import 'package:rideros_ai/features/pickup/presentation/restaurant_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/pickup_fakes.dart';
import '../helpers/pump.dart';

void main() {
  late FakePickupRepository pickup;

  setUp(() => pickup = FakePickupRepository());

  List<Override> overrides() =>
      fakeRepositories(FakeAuthRepository(), null, null, pickup);

  /// Lets the search debounce fire and the list load.
  Future<void> settleSearch(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  group('search', () {
    Future<void> open(WidgetTester tester) => pumpScreen(
      tester,
      path: Routes.pickup,
      screen: const PickupSearchScreen(),
      overrides: overrides(),
    );

    testWidgets('lists restaurants with source, data level and orders', (
      tester,
    ) async {
      pickup.restaurantItems.add(
        restaurant(id: 'own-9', name: 'Kitchen', own: true),
      );
      await open(tester);
      expect(find.byKey(const Key('pickup.datasetNote')), findsOneWidget);
      // Own restaurants first.
      final own = tester.getTopLeft(find.byKey(const Key('restaurant.own-9')));
      final poi = tester.getTopLeft(find.byKey(const Key('restaurant.r-1')));
      expect(own.dy, lessThan(poi.dy));
      Finder inRow(String id, String text) => find.descendant(
        of: find.byKey(Key('restaurant.$id')),
        matching: find.text(text),
      );
      expect(inRow('own-9', t.badgeOwn), findsOneWidget);
      expect(inRow('r-1', t.badgeDataset), findsOneWidget);
      expect(inRow('own-9', t.dataSufficient), findsNothing);
      expect(find.text(t.dataSufficient), findsOneWidget);
      expect(find.text(t.dataLimited), findsOneWidget);
      expect(find.text(t.pickupOrdersInData('1,267')), findsNWidgets(2));
    });

    testWidgets('search is debounced and sent trimmed', (tester) async {
      await open(tester);
      await tester.enterText(find.byKey(const Key('pickup.search')), ' poi-2 ');
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        pickup.calls.where((c) => c.startsWith('restaurants:poi')),
        isEmpty,
      );
      await settleSearch(tester);
      expect(pickup.calls.last, 'restaurants:poi-2:all:-');
      expect(find.byKey(const Key('restaurant.r-1')), findsNothing);
      expect(find.byKey(const Key('restaurant.r-2')), findsOneWidget);

      await tapKey(tester, 'pickup.search.clear');
      await settleSearch(tester);
      expect(find.byKey(const Key('restaurant.r-1')), findsOneWidget);
    });

    testWidgets('source filter', (tester) async {
      await open(tester);
      await tester.tap(find.text(t.pickupFilterOwn));
      await tester.pumpAndSettle();
      expect(pickup.calls.last, 'restaurants:-:own:-');
      // No own restaurants: empty state offers to add one.
      expect(find.text(t.pickupEmptyTitle), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, t.pickupAddOwn));
      await tester.pumpAndSettle();
      expect(find.text('route:${Routes.ownRestaurantNew}'), findsOneWidget);
    });

    testWidgets('error then retry', (tester) async {
      pickup.listError = const NetworkFailure();
      await open(tester);
      expect(find.text(t.failureNetwork), findsOneWidget);
      pickup.listError = null;
      await tester.tap(find.text(t.commonRetry));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('restaurant.r-1')), findsOneWidget);
    });

    testWidgets('pages load more', (tester) async {
      pickup.pageSize = 1;
      await open(tester);
      expect(find.byKey(const Key('restaurant.r-2')), findsNothing);
      await scrollAndTap(tester, 'pickup.loadMore');
      expect(find.byKey(const Key('restaurant.r-2')), findsOneWidget);
    });

    for (final (key, route) in [
      ('pickup.history', Routes.predictionHistory),
      ('pickup.logs', Routes.pickupLogs),
      ('pickup.model', Routes.modelInfo),
      ('pickup.addOwn', Routes.ownRestaurantNew),
    ]) {
      testWidgets('$key opens $route', (tester) async {
        await open(tester);
        await tapKey(tester, key);
        expect(find.text('route:$route'), findsOneWidget);
      });
    }

    testWidgets('a row opens the restaurant', (tester) async {
      await open(tester);
      await tapKey(tester, 'restaurant.r-1');
      expect(find.text('route:${Routes.restaurant('r-1')}'), findsOneWidget);
    });

    testWidgets('picker mode returns the restaurant, no entry points', (
      tester,
    ) async {
      Restaurant? chosen;
      await pumpScreen(
        tester,
        path: Routes.restaurantPicker,
        screen: PickupSearchScreen(onSelect: (r) => chosen = r),
        overrides: overrides(),
      );
      expect(find.text(t.pickerTitle), findsOneWidget);
      expect(find.byKey(const Key('pickup.history')), findsNothing);
      await tapKey(tester, 'restaurant.r-2');
      expect(chosen?.id, 'r-2');
    });
  });

  group('restaurant', () {
    Future<void> open(WidgetTester tester, String id) => pumpScreen(
      tester,
      path: Routes.restaurantPattern,
      initialLocation: Routes.restaurant(id),
      screen: RestaurantScreen(id: id),
      overrides: overrides(),
    );

    testWidgets('dataset restaurant: predict button, stats, heatmap', (
      tester,
    ) async {
      await open(tester, 'r-1');
      expect(find.text('POI-1'), findsWidgets);
      expect(find.byKey(const Key('restaurant.predict')), findsOneWidget);
      expect(find.text(t.pickupMinutesValue('10.4')), findsOneWidget);
      expect(find.text(t.pickupMinutesRange('7.9', '14')), findsOneWidget);
      expect(find.text('1,267'), findsOneWidget);
      expect(find.text(t.restaurantHourValue('12')), findsOneWidget);

      // Weekday: hours 10-21 have medians; others stay empty (no figure).
      await scrollIntoView(tester, find.byKey(const Key('heatmap.3')));
      expect(find.byTooltip(t.heatmapCellEmpty('03')), findsOneWidget);
      expect(find.byTooltip(t.heatmapCell('10', '8', 40)), findsOneWidget);
      // Weekend: only hour 12.
      await tester.ensureVisible(find.text(t.heatmapWeekend));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.heatmapWeekend));
      await tester.pumpAndSettle();
      expect(find.byTooltip(t.heatmapCell('12', '9.5', 9)), findsOneWidget);
      expect(find.byTooltip(t.heatmapCellEmpty('10')), findsOneWidget);
    });

    testWidgets('predict and log buttons navigate', (tester) async {
      await open(tester, 'r-1');
      await tapKey(tester, 'restaurant.predict');
      expect(find.text('route:${Routes.prediction('r-1')}'), findsOneWidget);
    });

    testWidgets('log button preselects the restaurant', (tester) async {
      await open(tester, 'r-1');
      await scrollAndTap(tester, 'restaurant.log');
      expect(
        find.text(
          'route:${Routes.pickupLogNewFor(restaurantId: 'r-1', name: 'POI-1')}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('own restaurant: no predict button, no dataset stats', (
      tester,
    ) async {
      pickup.restaurantItems.add(
        restaurant(id: 'own-1', name: 'Kitchen', own: true),
      );
      await open(tester, 'own-1');
      expect(find.byKey(const Key('restaurant.predict')), findsNothing);
      expect(find.text(t.restaurantOwnNoPrediction), findsOneWidget);
      expect(find.byKey(const Key('restaurant.stats')), findsNothing);
      expect(find.byKey(const Key('restaurant.waitStats')), findsOneWidget);
    });

    testWidgets('wait stats: fewer than 5 logs shows no figures', (
      tester,
    ) async {
      pickup.waitById['r-1'] = WaitStats.fromJson(waitStatsJson(n: 3));
      await open(tester, 'r-1');
      await scrollIntoView(tester, find.byKey(const Key('waitStats.needMore')));
      expect(find.text(t.waitStatsCount(3)), findsOneWidget);
      expect(find.text(t.waitStatsNeedMore(2)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('restaurant.waitStats')),
          matching: find.text(t.waitStatsMedian),
        ),
        findsNothing,
      );
    });

    testWidgets('wait stats: figures with the confidence label', (
      tester,
    ) async {
      pickup.waitById['r-1'] = WaitStats.fromJson(
        waitStatsJson(n: 7, median: '6.50', p80: '9.25', confidence: 'low'),
      );
      await open(tester, 'r-1');
      await scrollIntoView(
        tester,
        find.byKey(const Key('waitStats.confidence')),
      );
      expect(find.text(t.pickupMinutesValue('6.5')), findsOneWidget);
      expect(find.text(t.pickupMinutesValue('9.3')), findsOneWidget);
      expect(find.text(t.confidenceLow), findsOneWidget);
    });

    testWidgets('wait stats error has its own retry', (tester) async {
      pickup.waitError = const NetworkFailure();
      await open(tester, 'r-1');
      await scrollIntoView(tester, find.byKey(const Key('waitStats.retry')));
      expect(find.text(t.failureNetwork), findsOneWidget);
      pickup.waitError = null;
      await tapKey(tester, 'waitStats.retry');
      expect(find.byKey(const Key('waitStats.needMore')), findsOneWidget);
    });

    testWidgets('error and retry', (tester) async {
      pickup.analyticsError = const ApiFailure(
        statusCode: 404,
        code: 'restaurant_not_found',
      );
      await open(tester, 'r-1');
      expect(find.text(t.failureNotFound), findsOneWidget);
      pickup.analyticsError = null;
      await tester.tap(find.text(t.commonRetry));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('restaurant.predict')), findsOneWidget);
    });
  });

  group('prediction result', () {
    Future<void> open(WidgetTester tester, {bool settle = true}) => pumpScreen(
      tester,
      path: Routes.predictionPattern,
      initialLocation: Routes.prediction('r-1'),
      screen: const PredictionResultScreen(restaurantId: 'r-1'),
      overrides: overrides(),
      settle: settle,
    );

    testWidgets('interval first, midpoint second, warning and disclaimer', (
      tester,
    ) async {
      await open(tester);
      expect(pickup.calls.where((c) => c == 'predict:r-1'), hasLength(1));
      expect(find.text('5–20 นาที'), findsOneWidget);
      expect(find.text(t.predictionMidpoint('11.4')), findsOneWidget);
      expect(find.text(t.predictionCoverage('80')), findsOneWidget);
      expect(find.text(t.badgeEstimate), findsOneWidget);
      expect(find.text(t.predictionWarningForeign), findsOneWidget);
      expect(find.text(t.predictionDisclaimerThai), findsOneWidget);
      expect(
        find.text('Estimate of order-to-pickup time (server text).'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('prediction.meta')), findsOneWidget);
      expect(find.text(t.predictionTitle), findsWidgets);
    });

    testWidgets('limited data adds a second warning', (tester) async {
      pickup.predictWarnings = ['foreign_dataset', 'limited_restaurant_data'];
      await open(tester);
      expect(find.text(t.predictionWarningForeign), findsOneWidget);
      expect(find.text(t.predictionWarningLimited), findsOneWidget);
    });

    testWidgets('loading message, then 503 and retry', (tester) async {
      pickup.predictGate = Completer<void>();
      pickup.predictError = const ApiFailure(
        statusCode: 503,
        code: 'model_unavailable',
      );
      await open(tester, settle: false);
      expect(find.text(t.predictionLoading), findsOneWidget);
      pickup.predictGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text(t.failureModelUnavailable), findsOneWidget);
      pickup
        ..predictGate = null
        ..predictError = null;
      await tester.tap(find.text(t.commonRetry));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('prediction.range')), findsOneWidget);
    });

    testWidgets('own restaurant error is explained', (tester) async {
      pickup.predictError = const ApiFailure(
        statusCode: 400,
        code: 'restaurant_not_supported',
      );
      await open(tester);
      expect(find.text(t.failureRestaurantNotSupported), findsOneWidget);
    });

    testWidgets('predict again asks the model again; log button', (
      tester,
    ) async {
      await open(tester);
      await scrollAndTap(tester, 'prediction.again');
      expect(pickup.calls.where((c) => c == 'predict:r-1'), hasLength(2));
      await scrollAndTap(tester, 'prediction.log');
      expect(
        find.text(
          'route:${Routes.pickupLogNewFor(restaurantId: 'r-1', name: 'POI-1')}',
        ),
        findsOneWidget,
      );
    });
  });

  group('history', () {
    Future<void> open(WidgetTester tester) => pumpScreen(
      tester,
      path: Routes.predictionHistory,
      screen: const PredictionHistoryScreen(),
      overrides: overrides(),
    );

    testWidgets('empty state leads to the search', (tester) async {
      await open(tester);
      expect(find.text(t.historyEmptyTitle), findsOneWidget);
      await tester.tap(find.text(t.historyFindRestaurant));
      await tester.pumpAndSettle();
      expect(find.text('route:${Routes.pickup}'), findsOneWidget);
    });

    testWidgets('rows: restaurant, range, time, estimate badge', (
      tester,
    ) async {
      pickup.predictionItems.addAll([
        Prediction.fromJson(predictionJson(id: 'p-2')),
        Prediction.fromJson(predictionJson(id: 'p-1', name: null)),
      ]);
      await open(tester);
      expect(find.text('POI-1 · 5–20 นาที'), findsOneWidget);
      expect(
        find.text('${t.historyDeletedRestaurant} · 5–20 นาที'),
        findsOneWidget,
      );
      expect(find.text(t.badgeEstimate), findsNWidgets(2));
    });

    testWidgets('error and retry', (tester) async {
      pickup.listError = const NetworkFailure();
      await open(tester);
      expect(find.text(t.failureNetwork), findsOneWidget);
    });
  });

  group('logs', () {
    Future<void> open(WidgetTester tester) => pumpScreen(
      tester,
      path: Routes.pickupLogs,
      screen: const PickupLogsScreen(),
      overrides: overrides(),
    );

    testWidgets('empty state offers to log', (tester) async {
      await open(tester);
      expect(find.text(t.logsEmptyTitle), findsOneWidget);
      await tapKey(tester, 'logs.add');
      expect(find.text('route:${Routes.pickupLogNew}'), findsOneWidget);
    });

    testWidgets('rows and delete after confirming', (tester) async {
      pickup.logItems.add(PickupLog.fromJson(logJson(notes: 'queue')));
      await open(tester);
      expect(find.textContaining(t.logsWait('12')), findsOneWidget);
      expect(find.textContaining('queue'), findsOneWidget);

      await tapKey(tester, 'log.l-1.delete');
      expect(find.text(t.logsDeleteMessage), findsOneWidget);
      await tapKey(tester, 'confirm.cancel');
      expect(pickup.calls.where((c) => c.startsWith('deleteLog')), isEmpty);

      await tapKey(tester, 'log.l-1.delete');
      await tapKey(tester, 'confirm.delete');
      expect(pickup.calls, contains('deleteLog:l-1'));
      expect(find.text(t.recordDeleted), findsOneWidget);
      expect(find.text(t.logsEmptyTitle), findsOneWidget);
    });

    testWidgets('leaving while a delete runs still reports it', (tester) async {
      pickup.logItems.add(PickupLog.fromJson(logJson()));
      final router = await pushScreen(
        tester,
        pattern: Routes.pickupLogs,
        location: Routes.pickupLogs,
        screen: const PickupLogsScreen(),
        overrides: overrides(),
      );
      pickup.saveGate = Completer<void>();
      await tapKey(tester, 'log.l-1.delete');
      await tapKey(tester, 'confirm.delete');
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('route:${Routes.home}'), findsOneWidget);

      pickup.saveGate!.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(t.recordDeleted), findsOneWidget);
      expect(pickup.logItems, isEmpty);
    });

    testWidgets('a failed delete is reported', (tester) async {
      pickup.logItems.add(PickupLog.fromJson(logJson()));
      await open(tester);
      pickup.saveError = const NetworkFailure();
      await tapKey(tester, 'log.l-1.delete');
      await tapKey(tester, 'confirm.delete');
      expect(find.text(t.failureNetwork), findsOneWidget);
      expect(find.byKey(const Key('log.l-1')), findsOneWidget);
    });
  });

  group('log form', () {
    Future<void> open(WidgetTester tester, {ChosenRestaurant? restaurant}) =>
        pushScreen(
          tester,
          pattern: Routes.pickupLogNew,
          location: Routes.pickupLogNew,
          screen: PickupLogFormScreen(restaurant: restaurant),
          overrides: overrides(),
        );

    Future<void> setTime(
      WidgetTester tester,
      String key,
      String h,
      String m,
    ) async {
      await tapKey(tester, key);
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), h);
      await tester.enterText(fields.at(1), m);
      final ok = MaterialLocalizations.of(
        tester.element(find.byType(TimePickerDialog)),
      ).okButtonLabel;
      await tester.tap(find.text(ok));
      await tester.pumpAndSettle();
    }

    testWidgets('defaults: arrived 10 minutes ago, picked up now', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('13:57'), findsOneWidget);
      expect(find.text('14:07'), findsOneWidget);
      expect(find.text(t.logFormWait(t.durationMinutes(10))), findsOneWidget);
    });

    testWidgets('restaurant is required', (tester) async {
      await open(tester);
      await tapKey(tester, 'logForm.submit');
      expect(find.text(t.logFormRestaurantRequired), findsOneWidget);
      expect(pickup.calls, isNot(contains('createLog')));
    });

    testWidgets('choosing a restaurant opens the picker', (tester) async {
      await open(tester);
      await tapKey(tester, 'logForm.restaurant');
      expect(find.text('route:${Routes.restaurantPicker}'), findsOneWidget);
    });

    testWidgets('wait over 3 hours is blocked inline', (tester) async {
      await open(tester, restaurant: (id: 'r-1', name: 'POI-1'));
      // Picked up 13:50 < arrived 13:57: next day, far over 3 hours.
      await setTime(tester, 'logForm.pickedUp', '13', '50');
      expect(find.text(t.logFormWaitTooLong), findsOneWidget);
      await tapKey(tester, 'logForm.submit');
      expect(find.text(t.logFormWaitTooLong), findsOneWidget);
      expect(pickup.calls, isNot(contains('createLog')));
    });

    testWidgets('saves aware times past midnight and closes', (tester) async {
      await open(tester, restaurant: (id: 'r-1', name: 'POI-1'));
      expect(find.text('POI-1'), findsOneWidget);
      await setTime(tester, 'logForm.arrived', '23', '50');
      await setTime(tester, 'logForm.pickedUp', '00', '05');
      expect(find.textContaining(t.logFormNextDay), findsOneWidget);
      await enter(tester, 'logForm.notes', '  long queue ');
      await tapKey(tester, 'logForm.submit');
      final input = pickup.lastLog!;
      expect(input.restaurantId, 'r-1');
      expect(input.arrivedAt, DateTime(2026, 11, 10, 23, 50));
      expect(input.pickedUpAt, DateTime(2026, 11, 11, 0, 5));
      expect(input.notes, 'long queue');
      expect(find.text('route:${Routes.home}'), findsOneWidget);
      expect(find.text(t.recordSaved), findsOneWidget);
    });

    testWidgets('server error stays on the form as a banner', (tester) async {
      pickup.saveError = const ApiFailure(
        statusCode: 400,
        code: 'invalid_pickup_times',
      );
      await open(tester, restaurant: (id: 'r-1', name: 'POI-1'));
      await tapKey(tester, 'logForm.submit');
      expect(find.text(t.failureInvalidPickupTimes), findsOneWidget);
      expect(find.byType(PickupLogFormScreen), findsOneWidget);
    });

    testWidgets('notes length is limited', (tester) async {
      await open(tester, restaurant: (id: 'r-1', name: 'POI-1'));
      await enter(tester, 'logForm.notes', 'x' * 301);
      // maxLength stops typing at 300; nothing to report.
      await tapKey(tester, 'logForm.submit');
      expect(pickup.lastLog!.notes, hasLength(300));
    });
  });

  group('own restaurant form', () {
    Future<void> open(WidgetTester tester) => pushScreen(
      tester,
      pattern: Routes.ownRestaurantNew,
      location: Routes.ownRestaurantNew,
      screen: const OwnRestaurantFormScreen(),
      overrides: overrides(),
    );

    testWidgets('name is required', (tester) async {
      await open(tester);
      await tapKey(tester, 'ownForm.submit');
      expect(find.text(t.validationRequired), findsOneWidget);
      expect(pickup.calls, isNot(contains('createRestaurant')));
    });

    testWidgets('location needs both values within range', (tester) async {
      await open(tester);
      await enter(tester, 'ownForm.name', 'Kitchen');
      await enter(tester, 'ownForm.lat', '13.75');
      await tapKey(tester, 'ownForm.submit');
      expect(find.text(t.ownFormLocationPair), findsOneWidget);

      await enter(tester, 'ownForm.lng', '200');
      await tapKey(tester, 'ownForm.submit');
      expect(find.text(t.validationRange('-180', '180')), findsOneWidget);

      await enter(tester, 'ownForm.lng', 'abc');
      await tapKey(tester, 'ownForm.submit');
      expect(find.text(t.validationNumberInvalid), findsOneWidget);
      expect(pickup.calls, isNot(contains('createRestaurant')));
    });

    testWidgets('saves name only', (tester) async {
      await open(tester);
      await enter(tester, 'ownForm.name', '  Kitchen  ');
      await tapKey(tester, 'ownForm.submit');
      expect(pickup.lastRestaurant, const RestaurantInput(name: 'Kitchen'));
      expect(find.text(t.ownFormSaved), findsOneWidget);
      expect(find.text('route:${Routes.home}'), findsOneWidget);
    });

    testWidgets('saves with a location', (tester) async {
      await open(tester);
      await enter(tester, 'ownForm.name', 'Kitchen');
      await enter(tester, 'ownForm.lat', '-13.5');
      await enter(tester, 'ownForm.lng', '100.25');
      await tapKey(tester, 'ownForm.submit');
      expect(
        pickup.lastRestaurant!.location,
        const Coordinates(lat: -13.5, lng: 100.25),
      );
    });

    testWidgets('spinner while saving; no double submit', (tester) async {
      pickup.saveGate = Completer<void>();
      await open(tester);
      await enter(tester, 'ownForm.name', 'Kitchen');
      await tapKey(tester, 'ownForm.submit', settle: false);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const Key('ownForm.submit')));
      pickup.saveGate!.complete();
      await tester.pumpAndSettle();
      expect(pickup.calls.where((c) => c == 'createRestaurant'), hasLength(1));
    });
  });

  group('model info', () {
    Future<void> open(WidgetTester tester) => pumpScreen(
      tester,
      path: Routes.modelInfo,
      screen: const ModelInfoScreen(),
      overrides: overrides(),
    );

    testWidgets('figures from the API and the acknowledgement', (tester) async {
      await open(tester);
      expect(find.text(t.pickupMinutesValue('4.51')), findsOneWidget);
      expect(find.text(t.pickupMinutesValue('4.64')), findsOneWidget);
      expect(find.textContaining('64,701'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('81.6%'), findsOneWidget);
      expect(find.textContaining('xgboost'), findsOneWidget);
      await scrollIntoView(
        tester,
        find.byKey(const Key('model.acknowledgement')),
      );
      expect(
        find.text('This research was supported by data provided by Meituan.'),
        findsOneWidget,
      );
      expect(find.textContaining('CC BY-NC 4.0'), findsOneWidget);
    });

    testWidgets('server limitations behind an expander', (tester) async {
      await open(tester);
      await scrollAndTap(tester, 'model.serverLimitations');
      expect(find.text('Not food preparation time.'), findsOneWidget);
    });

    testWidgets('503 shows the reason and retry', (tester) async {
      pickup.modelError = const ApiFailure(
        statusCode: 503,
        code: 'model_unavailable',
      );
      await open(tester);
      expect(find.text(t.failureModelUnavailable), findsOneWidget);
      pickup.modelError = null;
      await tester.tap(find.text(t.commonRetry));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('model.what')), findsOneWidget);
    });
  });
}
