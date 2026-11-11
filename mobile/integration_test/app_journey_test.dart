// Phase 4 end-to-end journey: the real app on the emulator against the real
// API (`docker compose up`). Every step goes through the UI.
//
// Run from `mobile/` (see README "End-to-end test"):
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_journey_test.dart -d emulator-5554
//
// What the screens showed is sent to the host driver as `reportData`; the driver
// checks it against PostgreSQL and then deletes the test account.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rideros_ai/app/app.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/features/profit/presentation/true_profit_screen.dart';
import 'package:rideros_ai/l10n/app_localizations_th.dart';
import 'package:rideros_ai/main.dart' as app;

final t = AppLocalizationsTh();

/// The password of every throwaway E2E account (the driver logs in with it to
/// delete the account afterwards).
const e2ePassword = 'e2e journey pass 2026';

/// A dataset restaurant with "sufficient" data in the shipped import.
const restaurantName = 'POI-203';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // A tap that lands on something else (e.g. a closing menu) fails at once.
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('Register → Login → Dashboard → Pickup → Income → Expense → Profit → '
      'Scenarios → Compare', (tester) async {
    final report = <String, Object?>{};
    final email = 'e2e+${DateTime.now().millisecondsSinceEpoch}@example.com';
    report['email'] = email;
    report['password'] = e2ePassword;

    // A stored refresh token from an earlier run would skip the login.
    await const FlutterSecureStorage().deleteAll();
    app.main();
    await waitForIntro(tester);

    // 1. Register (no tokens) → back on Login.
    await tapOn(tester, byKey('login.register'));
    await type(tester, 'register.displayName', 'E2E Rider');
    await type(tester, 'register.email', email);
    await type(tester, 'register.password', e2ePassword);
    await type(tester, 'register.confirm', e2ePassword);
    await tapOn(tester, byKey('register.submit'));

    // Registering signs in at once → Onboarding (no rider profile yet).
    await pumpUntil(tester, byKey('onboarding.submit'));
    await pickDropdown(tester, 'onboarding.vehicleType', t.vehicleMotorcycle);
    await type(tester, 'onboarding.fuelKmPerLiter', '40');
    await type(tester, 'onboarding.fuelPrice', '38.5');
    await type(tester, 'onboarding.depreciation', '0.6');
    await tapOn(tester, byKey('onboarding.submit'));
    await pumpUntil(tester, byKey('home.empty'));

    // 2. Log out, then log in with the new account.
    await tapOn(tester, byKey('nav.profile'));
    await tapOn(tester, byKey('profile.logout'));
    await type(tester, 'login.email', email);
    await type(tester, 'login.password', e2ePassword);
    await tapOn(tester, byKey('login.submit'));

    // 3. Dashboard of a new account (the profile was saved, so no onboarding).
    await pumpUntil(tester, byKey('home.empty'));
    report['home_empty_shown'] = true;

    // 4. Pickup prediction for a dataset restaurant.
    await tapOn(tester, byKey('nav.pickup'));
    await type(tester, 'pickup.search', restaurantName);
    // The result row (`restaurant.<id>`), not the search field's own text.
    final row = find.ancestor(
      of: find.text(restaurantName),
      matching: find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            RegExp(r'^restaurant\.[0-9a-f-]{36}$')
                .hasMatch((w.key! as ValueKey<String>).value),
      ),
    );
    await tapOn(tester, row.first);
    await tapOn(tester, byKey('restaurant.predict'));
    await pumpUntil(tester, byKey('prediction.range'));
    report['prediction'] = {
      'restaurant': restaurantName,
      'range': textOf(tester, byKey('prediction.range')),
      'midpoint': textOf(tester, byKey('prediction.midpoint')),
      'warnings': [
        for (final e
            in find
                .byWidgetPredicate(
                  (w) =>
                      w.key is ValueKey<String> &&
                      (w.key! as ValueKey<String>).value.startsWith(
                        'prediction.warning.',
                      ),
                )
                .evaluate())
          (e.widget.key! as ValueKey<String>).value.substring(
            'prediction.warning.'.length,
          ),
      ],
    };
    await backTo(tester, byKey('nav.home'));
    await tapOn(tester, byKey('nav.home'));

    // 5. Add income (today, 5 hours).
    await tapOn(tester, byKey('home.addIncome'));
    await type(tester, 'income.amount', '850.50');
    await type(tester, 'income.source', 'E2E Food');
    await type(tester, 'income.hours', '5');
    await type(tester, 'income.orders', '12');
    await type(tester, 'income.distance', '40.5');
    await tapOn(tester, byKey('income.submit'));
    await pumpUntil(tester, byKey('home.today'));

    // 6. Add expense (today, fuel).
    await tapOn(tester, byKey('home.addExpense'));
    await pickDropdown(tester, 'expense.category', t.expenseCategoryFuel);
    await type(tester, 'expense.amount', '120.25');
    await type(tester, 'expense.description', 'E2E fuel');
    await tapOn(tester, byKey('expense.submit'));

    final today = byKey('home.today');
    await pumpUntil(
      tester,
      find.descendant(of: today, matching: find.text('฿730.25')),
      reason: 'home net after both records',
    );
    report['home_today_net'] = textOf(
      tester,
      find.descendant(of: today, matching: byKey('metrics.net')),
    );

    // 7. View profit (day view).
    await tapOn(tester, byKey('home.openProfit'));
    final profit = find.byType(TrueProfitScreen);
    await pumpUntil(
      tester,
      find.descendant(of: profit, matching: find.text('฿850.50')),
      reason: 'TrueProfit revenue',
    );
    report['profit_day'] = {
      'period': textOf(tester, byKey('profit.periodLabel')),
      'net': textOf(
        tester,
        find.descendant(of: profit, matching: byKey('metrics.net')).first,
      ),
      'revenue': valueAfter(tester, profit, t.profitRevenue),
      'expenses': valueAfter(tester, profit, t.profitExpenses),
      'hours': valueAfter(tester, profit, t.profitWorkingHours),
      'net_per_hour': valueAfter(tester, profit, t.profitNetPerHour),
    };

    // 8. Create two scenarios (assumption method, default 17:00–22:00).
    await tapOn(tester, byKey('nav.shifts'));
    final a = await createScenario(
      tester,
      name: 'E2E Evening A',
      ordersPerHour: '2.5',
      incomePerOrder: '45',
      kmPerOrder: '3',
    );
    final b = await createScenario(
      tester,
      name: 'E2E Evening B',
      ordersPerHour: '2',
      incomePerOrder: '60',
      kmPerOrder: '4',
      otherCosts: '20',
    );

    // 9. Compare both.
    await tapOn(tester, byKey('shift.$a.select'));
    await tapOn(tester, byKey('shift.$b.select'));
    await tapOn(tester, byKey('shifts.compare'));
    await pumpUntil(tester, byKey('compare.$a'));
    await pumpUntil(tester, byKey('compare.$b'));
    Map<String, String> card(String id) {
      final scope = byKey('compare.$id');
      return {
        'revenue': valueAfter(tester, scope, t.shiftEstimatedRevenue),
        'expenses': valueAfter(tester, scope, t.shiftEstimatedExpenses),
        'net': valueAfter(tester, scope, t.shiftNetEstimate),
        'per_hour': valueAfter(tester, scope, t.shiftPerHourEstimate),
      };
    }

    report['compare'] = {
      'scenarios': {a: card(a), b: card(b)},
      'best_net': valueAfter(tester, byKey('compare.bestNet'), t.shiftBestNet),
    };

    binding.reportData = report;
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Finder byKey(String key) => find.byKey(Key(key));

/// Pumps real frames until [finder] matches (network calls finish in real time).
/// When nothing appears for a while, scrolls the page down: rows below the fold
/// of a lazy list are not built until they are scrolled near.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  String? reason,
  bool scroll = true,
}) async {
  final end = DateTime.now().add(timeout);
  var ticks = 0;
  while (!_found(finder)) {
    if (DateTime.now().isAfter(end)) {
      throw TestFailure('Timed out waiting for ${reason ?? finder}');
    }
    await tester.pump(const Duration(milliseconds: 100));
    if (scroll && ++ticks % 15 == 0) await _scrollPage(tester);
  }
}

/// `finder.first` throws while nothing matches yet: that counts as not found.
bool _found(Finder finder) {
  try {
    return finder.evaluate().isNotEmpty;
  } on StateError {
    return false;
  }
}

/// Drags the tallest visible vertical list (the page body, not a text field).
Future<void> _scrollPage(WidgetTester tester) async {
  Element? page;
  var height = 0.0;
  for (final e
      in find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .evaluate()) {
    final box = e.renderObject;
    if (box is RenderBox && box.hasSize && box.size.height >= height) {
      height = box.size.height;
      page = e;
    }
  }
  if (page == null) return;
  await tester.drag(
    find.byElementPredicate((e) => identical(e, page)),
    const Offset(0, -300),
    warnIfMissed: false,
  );
  await tester.pump(const Duration(milliseconds: 300));
}

/// The ride intro blocks taps until it has left.
Future<void> waitForIntro(WidgetTester tester) async {
  await pumpUntil(
    tester,
    find.byType(RiderOsApp),
    timeout: const Duration(seconds: 60),
  );
  final overlay = find.byWidgetPredicate(
    (w) => w is AbsorbPointer && w.child is BlockSemantics,
  );
  final end = DateTime.now().add(const Duration(seconds: 60));
  while (overlay.evaluate().isNotEmpty) {
    if (DateTime.now().isAfter(end)) throw TestFailure('Intro never ended');
    await tester.pump(const Duration(milliseconds: 100));
  }
  await pumpUntil(tester, byKey('login.email'));
}

/// Taps [finder] once it can receive the tap: during a page transition or while
/// a menu closes the tap would land elsewhere (fatal, see `main`), so retry.
Future<void> tapOn(WidgetTester tester, Finder finder) async {
  await pumpUntil(tester, finder);
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (true) {
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 200));
    try {
      await tester.tap(finder);
      break;
    } on FlutterError {
      if (DateTime.now().isAfter(end)) rethrow;
      await tester.pump(const Duration(milliseconds: 300));
    }
  }
  await tester.pump(const Duration(milliseconds: 400));
}

/// Opens the dropdown [key], picks [label] and waits until the menu has closed.
Future<void> pickDropdown(WidgetTester tester, String key, String label) async {
  await tapOn(tester, byKey(key));
  await tapOn(tester, find.text(label).last);
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (find.text(label).evaluate().length > 1) {
    if (DateTime.now().isAfter(end)) throw TestFailure('Menu stayed open');
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> type(WidgetTester tester, String key, String text) async {
  final finder = byKey(key);
  await pumpUntil(tester, finder);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await tester.pump();
}

String textOf(WidgetTester tester, Finder finder) {
  final text = tester.widget<Text>(finder);
  return text.data ?? text.textSpan!.toPlainText();
}

/// The text right after [label] inside [scope] (label/value tiles and rows).
String valueAfter(WidgetTester tester, Finder scope, String label) {
  final texts = [
    for (final w in tester.widgetList<Text>(
      find.descendant(of: scope, matching: find.byType(Text)),
    ))
      w.data ?? w.textSpan?.toPlainText() ?? '',
  ];
  final i = texts.indexOf(label);
  if (i < 0 || i + 1 >= texts.length) {
    throw TestFailure('No value after "$label" in $texts');
  }
  return texts[i + 1];
}

/// Pops routes (system back) until [finder] is on screen.
Future<void> backTo(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 5 && finder.evaluate().isEmpty; i++) {
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
  }
  await pumpUntil(tester, finder);
}

/// Creates a scenario from the list, returns its id (from the details route),
/// and goes back to the list.
Future<String> createScenario(
  WidgetTester tester, {
  required String name,
  required String ordersPerHour,
  required String incomePerOrder,
  required String kmPerOrder,
  String? otherCosts,
}) async {
  await tapOn(tester, byKey('shifts.add'));
  await type(tester, 'shiftForm.name', name);
  await type(tester, 'shiftForm.ordersPerHour', ordersPerHour);
  await type(tester, 'shiftForm.incomePerOrder', incomePerOrder);
  await type(tester, 'shiftForm.kmPerOrder', kmPerOrder);
  if (otherCosts != null) {
    await type(tester, 'shiftForm.otherCosts', otherCosts);
  }
  await tapOn(tester, byKey('shiftForm.submit'));
  await pumpUntil(tester, byKey('shift.header'));

  final container = ProviderScope.containerOf(
    tester.element(find.byType(RiderOsApp)),
  );
  final path = container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .path;
  final match = RegExp(r'^/shifts/scenarios/([0-9a-f-]+)$').firstMatch(path);
  if (match == null) throw TestFailure('Not on scenario details: $path');

  await backTo(tester, byKey('shifts.add'));
  return match.group(1)!;
}
