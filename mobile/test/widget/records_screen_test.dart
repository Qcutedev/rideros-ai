import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/profit/domain/profit_records.dart';
import 'package:rideros_ai/features/profit/presentation/records_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/profit_fakes.dart';
import '../helpers/pump.dart';

void main() {
  late ProfitFakes profit;

  setUp(() => profit = ProfitFakes());

  Future<void> pumpRecords(
    WidgetTester tester, {
    RecordsTab tab = RecordsTab.income,
  }) => pumpScreen(
    tester,
    path: Routes.records,
    screen: RecordsScreen(initialTab: tab),
    overrides: fakeRepositories(
      FakeAuthRepository()..restoreUser = testUser,
      FakeRiderProfileRepository(configured: true),
      profit,
    ),
  );

  IncomeInput income(String amount, [int day = 10]) => IncomeInput(
    occurredOn: DateTime.utc(2026, 11, day),
    amount: d(amount),
    sourceLabel: 'Grab',
    orderCount: 12,
  );

  testWidgets('empty income list with a working call to action', (
    tester,
  ) async {
    await pumpRecords(tester);
    expect(find.text(t.incomeEmptyTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, t.incomeAdd));
    await tester.pumpAndSettle();
    expect(find.text('route:${Routes.incomeNew}'), findsOneWidget);
  });

  testWidgets('income items, DEMO label and opening one', (tester) async {
    profit.income.add(income('800.5', 9));
    final demo = profit.income.add(income('1200'));
    profit.income.items[0] = demo.copyWith(isDemo: true);
    await pumpRecords(tester);

    expect(find.text('800.50'), findsOneWidget);
    expect(find.text('1,200.00'), findsOneWidget);
    expect(find.text(t.demoLabel), findsOneWidget);
    expect(find.textContaining('Grab'), findsNWidgets(2));
    expect(find.textContaining(t.ordersValue(12)), findsNWidgets(2));

    await tester.tap(find.text('1,200.00'));
    await tester.pumpAndSettle();
    expect(find.text('route:/income/${demo.id}'), findsOneWidget);
  });

  testWidgets('load more appends the next page until the end', (tester) async {
    profit.income.pageSize = 2;
    for (final amount in ['1', '2', '3']) {
      profit.income.add(income(amount));
    }
    await pumpRecords(tester);
    expect(find.text('1.00'), findsNothing);

    await tapKey(tester, 'records.loadMore');
    expect(find.text('1.00'), findsOneWidget);
    expect(find.text(t.recordsEnd), findsOneWidget);
  });

  testWidgets('a failed next page keeps the list and retries', (tester) async {
    profit.income.pageSize = 1;
    profit.income
      ..add(income('1'))
      ..add(income('2'));
    await pumpRecords(tester);
    profit.income.listError = const NetworkFailure();
    await tapKey(tester, 'records.loadMore');
    expect(find.text('2.00'), findsOneWidget);
    expect(find.text(t.failureNetwork), findsOneWidget);

    profit.income.listError = null;
    await tapKey(tester, 'records.loadMoreRetry');
    expect(find.text('1.00'), findsOneWidget);
  });

  testWidgets('first page error with retry', (tester) async {
    profit.income.listError = const NetworkFailure(isTimeout: true);
    await pumpRecords(tester);
    expect(find.text(t.failureTimeout), findsOneWidget);
    profit.income.listError = null;
    await tester.tap(find.text(t.commonRetry));
    await tester.pumpAndSettle();
    expect(find.text(t.incomeEmptyTitle), findsOneWidget);
  });

  testWidgets('tabs switch the list and the add button', (tester) async {
    profit.expenses.add(
      ExpenseInput(
        occurredOn: DateTime.utc(2026, 11, 10),
        category: ExpenseCategory.fuel,
        amount: d('150'),
        description: 'PTT',
      ),
    );
    await pumpRecords(tester);
    expect(find.text(t.incomeAdd), findsWidgets);

    await tapKey(tester, 'records.tab.expenses');
    expect(find.text('150.00'), findsOneWidget);
    expect(find.textContaining(t.expenseCategoryFuel), findsOneWidget);
    await tapKey(tester, 'records.add');
    expect(find.text('route:${Routes.expenseNew}'), findsOneWidget);
  });

  testWidgets('sessions tab shows times, length and past midnight', (
    tester,
  ) async {
    profit.sessions.add(
      WorkSessionInput(
        startedAt: DateTime(2026, 11, 9, 20),
        endedAt: DateTime(2026, 11, 10, 1, 30),
        orderCount: 9,
      ),
    );
    await pumpRecords(tester, tab: RecordsTab.sessions);
    expect(find.textContaining(t.sessionEndsNextDay('01:30')), findsOneWidget);
    expect(find.textContaining('20:00'), findsOneWidget);
    expect(find.textContaining(t.durationHoursMinutes(5, 30)), findsOneWidget);
    await tapKey(tester, 'records.add');
    expect(find.text('route:${Routes.workSessionNew}'), findsOneWidget);
  });

  testWidgets('empty sessions tab', (tester) async {
    await pumpRecords(tester, tab: RecordsTab.sessions);
    expect(find.text(t.sessionEmptyTitle), findsOneWidget);
  });
}
