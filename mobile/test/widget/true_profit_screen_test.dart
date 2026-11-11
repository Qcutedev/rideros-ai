import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/profit/domain/profit_summary.dart';
import 'package:rideros_ai/features/profit/presentation/profit_labels.dart';
import 'package:rideros_ai/features/profit/presentation/true_profit_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/profit_fakes.dart';
import '../helpers/pump.dart';

void main() {
  late ProfitFakes profit;

  setUp(() => profit = ProfitFakes());

  Future<void> pumpProfit(WidgetTester tester, {bool settle = true}) =>
      pumpScreen(
        tester,
        path: Routes.profit,
        screen: const TrueProfitScreen(),
        overrides: fakeRepositories(
          FakeAuthRepository()..restoreUser = testUser,
          FakeRiderProfileRepository(configured: true),
          profit,
        ),
        settle: settle,
      );

  String label(ProfitPeriod period, DateTime start, DateTime end) =>
      periodRangeLabel(t, period, start, end);

  bool nextVisible(WidgetTester tester) => tester
      .widget<Visibility>(
        find.ancestor(
          of: find.byKey(const Key('profit.next')),
          matching: find.byType(Visibility),
        ),
      )
      .visible;

  testWidgets('loading, then the current day', (tester) async {
    profit.profit.gate = Completer<void>();
    await pumpProfit(tester, settle: false);
    await tester.pump();
    expect(find.byKey(const Key('skeleton')), findsOneWidget);
    profit.profit.gate!.complete();
    await tester.pumpAndSettle();

    final today = DateTime.utc(2026, 11, 10);
    expect(find.text(label(ProfitPeriod.day, today, today)), findsOneWidget);
    expect(find.text(t.profitCurrentPeriod), findsOneWidget);
    // The current period has no "next" to tap.
    expect(nextVisible(tester), isFalse);
  });

  testWidgets('empty period and empty trend', (tester) async {
    await pumpProfit(tester);
    expect(find.text(t.profitEmptyPeriod), findsOneWidget);
    expect(find.text(t.profitTrendEmpty), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets('data: detailed figures and the trend chart', (tester) async {
    profit.profit
      ..setSummary(
        ProfitPeriod.day,
        metrics(
          revenue: '1200.00',
          expenses: '200.00',
          hours: '8.00',
          revenuePerHour: '150.00',
          netPerHour: '125.00',
          incomeCount: 3,
          expenseCount: 1,
          sessionCount: 1,
        ),
      )
      ..trendMetrics[ProfitPeriod.day] = [
        metrics(revenue: '500.00', incomeCount: 1),
        metrics(expenses: '80.00', expenseCount: 1),
        metrics(revenue: '1200.00', expenses: '200.00', incomeCount: 3),
      ];
    await pumpProfit(tester);
    expect(find.text('฿1,000.00'), findsOneWidget);
    expect(find.text('฿150.00'), findsOneWidget);
    expect(find.text('฿125.00'), findsOneWidget);
    expect(find.text(t.profitRecordCountsValue(3, 1, 1)), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text(t.profitActualOnlyNote('Asia/Bangkok')), findsOneWidget);
  });

  testWidgets('previous and next walk through days', (tester) async {
    await pumpProfit(tester);
    await tapKey(tester, 'profit.previous');
    final nov9 = DateTime.utc(2026, 11, 9);
    expect(find.text(label(ProfitPeriod.day, nov9, nov9)), findsOneWidget);
    expect(find.text(t.profitCurrentPeriod), findsNothing);
    expect(profit.profit.calls, contains('summary:day:2026-11-09'));

    expect(nextVisible(tester), isTrue);
    await tapKey(tester, 'profit.next');
    expect(find.text(t.profitCurrentPeriod), findsOneWidget);
    expect(nextVisible(tester), isFalse);
    expect(profit.profit.calls.last, 'trends:day:-');
  });

  testWidgets('back to the current period from a past one', (tester) async {
    await pumpProfit(tester);
    expect(find.byKey(const Key('profit.current')), findsNothing);
    await tapKey(tester, 'profit.previous');
    await tapKey(tester, 'profit.previous');
    expect(find.byKey(const Key('profit.current')), findsOneWidget);

    await tapKey(tester, 'profit.current');
    final today = DateTime.utc(2026, 11, 10);
    expect(find.text(label(ProfitPeriod.day, today, today)), findsOneWidget);
    expect(find.text(t.profitCurrentPeriod), findsOneWidget);
    expect(find.byKey(const Key('profit.current')), findsNothing);
    expect(nextVisible(tester), isFalse);
  });

  testWidgets('week and month views', (tester) async {
    await pumpProfit(tester);
    await tester.tap(find.text(t.periodWeek));
    await tester.pumpAndSettle();
    expect(profit.profit.calls, contains('summary:week:-'));
    expect(
      find.text(
        label(
          ProfitPeriod.week,
          DateTime.utc(2026, 11, 9),
          DateTime.utc(2026, 11, 15),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(t.profitTrendTitle(t.periodWeek)), findsOneWidget);

    await tester.tap(find.text(t.periodMonth));
    await tester.pumpAndSettle();
    await tapKey(tester, 'profit.previous');
    expect(profit.profit.calls, contains('summary:month:2026-10-31'));
    expect(
      find.text(
        label(
          ProfitPeriod.month,
          DateTime.utc(2026, 10),
          DateTime.utc(2026, 10, 31),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('error with retry', (tester) async {
    profit.profit.summaryError = const ApiFailure(
      statusCode: 500,
      code: 'internal_error',
    );
    await pumpProfit(tester);
    expect(find.text(t.failureServer), findsOneWidget);

    profit.profit.summaryError = null;
    await tester.tap(find.text(t.commonRetry));
    await tester.pumpAndSettle();
    expect(find.text(t.profitEmptyPeriod), findsOneWidget);
  });

  testWidgets('the records button opens the record list', (tester) async {
    await pumpProfit(tester);
    await tapKey(tester, 'profit.records');
    expect(find.text('route:${Routes.records}'), findsOneWidget);
  });
}
