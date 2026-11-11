import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/dashboard/presentation/home_screen.dart';
import 'package:rideros_ai/features/profit/domain/profit_summary.dart';

import '../helpers/fakes.dart';
import '../helpers/profit_fakes.dart';
import '../helpers/pump.dart';

void main() {
  late FakeAuthRepository auth;
  late ProfitFakes profit;

  setUp(() {
    auth = FakeAuthRepository()..restoreUser = testUser;
    profit = ProfitFakes();
  });

  Future<void> pumpHome(WidgetTester tester, {bool settle = true}) =>
      pumpScreen(
        tester,
        path: Routes.home,
        screen: const HomeScreen(),
        overrides: fakeRepositories(
          auth,
          FakeRiderProfileRepository(configured: true),
          profit,
        ),
        settle: settle,
      );

  testWidgets('loading while today and this week are fetched', (tester) async {
    profit.profit.gate = Completer<void>();
    await pumpHome(tester, settle: false);
    await tester.pump();
    expect(find.byKey(const Key('skeleton')), findsOneWidget);
    // Shortcuts work while the numbers load.
    expect(find.byKey(const Key('home.addIncome')), findsOneWidget);
    profit.profit.gate!.complete();
    await tester.pumpAndSettle();
    expect(profit.profit.calls, ['summary:day:-', 'summary:week:-']);
  });

  testWidgets('error shows the reason and retry reloads', (tester) async {
    profit.profit.summaryError = const NetworkFailure();
    await pumpHome(tester);
    expect(find.text(t.failureNetwork), findsOneWidget);

    profit.profit.summaryError = null;
    await tester.tap(find.text(t.commonRetry));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home.empty')), findsOneWidget);
  });

  testWidgets('empty: no records today or this week', (tester) async {
    await pumpHome(tester);
    expect(find.text(t.homeGreeting(testUser.displayName)), findsOneWidget);
    expect(find.text(t.homeEmptyTitle), findsOneWidget);
    expect(find.byKey(const Key('home.today')), findsNothing);
  });

  testWidgets('data: today and this week with server figures', (tester) async {
    profit.profit
      ..setSummary(
        ProfitPeriod.day,
        metrics(
          revenue: '1200.00',
          expenses: '150.50',
          hours: '7.50',
          revenuePerHour: '160.00',
          netPerHour: '139.93',
          incomeCount: 2,
          expenseCount: 1,
          sessionCount: 1,
        ),
      )
      ..setSummary(
        ProfitPeriod.week,
        metrics(revenue: '5000.00', expenses: '6000.00', incomeCount: 5),
      );
    await pumpHome(tester);

    final today = find.byKey(const Key('home.today'));
    expect(
      find.descendant(of: today, matching: find.text('฿1,049.50')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: today, matching: find.text('฿139.93')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: today,
        matching: find.text(t.profitHoursValue('7.5')),
      ),
      findsOneWidget,
    );
    final week = find.byKey(const Key('home.week'));
    expect(
      find.descendant(of: week, matching: find.text('฿-1,000.00')),
      findsOneWidget,
    );
    // No hours this week: per-hour is not invented.
    expect(
      find.descendant(of: week, matching: find.text(t.profitNoWorkingHours)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: week, matching: find.text(t.profitNotAvailable)),
      findsOneWidget,
    );
  });

  for (final (key, route) in [
    ('home.addIncome', Routes.incomeNew),
    ('home.addExpense', Routes.expenseNew),
    ('home.addSession', Routes.workSessionNew),
    ('home.openProfit', Routes.profit),
  ]) {
    testWidgets('$key opens $route', (tester) async {
      await pumpHome(tester);
      await tapKey(tester, key);
      expect(find.text('route:$route'), findsOneWidget);
    });
  }

  testWidgets('logout ends the session', (tester) async {
    await pumpHome(tester);
    await tapKey(tester, 'home.logout');
    expect(auth.calls, contains('logout'));
  });
}
