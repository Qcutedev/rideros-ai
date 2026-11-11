import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/profit/domain/profit_records.dart';
import 'package:rideros_ai/features/profit/presentation/expense_form_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/profit_fakes.dart';
import '../helpers/pump.dart';

void main() {
  late ProfitFakes profit;

  setUp(() => profit = ProfitFakes());

  Future<void> open(WidgetTester tester, {String? id}) => pushScreen(
    tester,
    pattern: id == null ? Routes.expenseNew : Routes.expenseEditPattern,
    location: id == null ? Routes.expenseNew : Routes.expenseEdit(id),
    screen: ExpenseFormScreen(id: id),
    overrides: fakeRepositories(FakeAuthRepository(), null, profit),
  );

  Future<void> pickCategory(WidgetTester tester, String label) async {
    await tapKey(tester, 'expense.category');
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('category and amount are required', (tester) async {
    await open(tester);
    await tapKey(tester, 'expense.submit');
    expect(find.text(t.validationRequired), findsNWidgets(2));
    expect(profit.expenses.calls, isEmpty);
  });

  testWidgets('description longer than 500 is cut at the limit', (
    tester,
  ) async {
    await open(tester);
    await pickCategory(tester, t.expenseCategoryOther);
    await enter(tester, 'expense.amount', '10');
    await enter(tester, 'expense.description', 'y' * 600);
    await tapKey(tester, 'expense.submit');
    expect(profit.expenses.lastInput!.description, hasLength(500));
  });

  testWidgets('create sends category, amount and description', (tester) async {
    await open(tester);
    await pickCategory(tester, t.expenseCategoryFuel);
    await enter(tester, 'expense.amount', '150.75');
    await enter(tester, 'expense.description', ' PTT ');
    await tapKey(tester, 'expense.submit');

    final input = profit.expenses.lastInput!;
    expect(input.category, ExpenseCategory.fuel);
    expect(input.amount, d('150.75'));
    expect(input.description, 'PTT');
    expect(input.occurredOn, DateTime.utc(2026, 11, 10));
    expect(find.text('route:${Routes.home}'), findsOneWidget);
  });

  testWidgets('server failure banner', (tester) async {
    profit.expenses.saveError = const NetworkFailure();
    await open(tester);
    await pickCategory(tester, t.expenseCategoryMaintenance);
    await enter(tester, 'expense.amount', '300');
    await tapKey(tester, 'expense.submit');
    expect(find.text(t.failureNetwork), findsOneWidget);
    expect(find.byType(ExpenseFormScreen), findsOneWidget);
  });

  testWidgets('edit prefills, changes category, deletes', (tester) async {
    final existing = profit.expenses.add(
      ExpenseInput(
        occurredOn: DateTime.utc(2026, 11, 1),
        category: ExpenseCategory.fuel,
        amount: d('120.00'),
      ),
    );
    await open(tester, id: existing.id);
    expect(find.text(t.expenseEditTitle), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text(t.expenseCategoryFuel), findsOneWidget);

    await pickCategory(tester, t.expenseCategoryDepreciation);
    await tapKey(tester, 'expense.submit');
    expect(profit.expenses.calls.last, 'update:${existing.id}');
    expect(profit.expenses.lastInput!.category, ExpenseCategory.depreciation);
  });

  testWidgets('delete after confirming', (tester) async {
    final existing = profit.expenses.add(
      ExpenseInput(
        occurredOn: DateTime.utc(2026, 11, 1),
        category: ExpenseCategory.other,
        amount: d('5'),
      ),
    );
    await open(tester, id: existing.id);
    await tapKey(tester, 'expense.delete');
    await tapKey(tester, 'confirm.delete');
    expect(profit.expenses.items, isEmpty);
    expect(find.text(t.recordDeleted), findsOneWidget);
  });

  testWidgets('a failed delete stays on the form with the reason', (
    tester,
  ) async {
    final existing = profit.expenses.add(
      ExpenseInput(
        occurredOn: DateTime.utc(2026, 11, 1),
        category: ExpenseCategory.other,
        amount: d('5'),
      ),
    );
    profit.expenses.deleteError = const ApiFailure(
      statusCode: 404,
      code: 'expense_not_found',
    );
    await open(tester, id: existing.id);
    await tapKey(tester, 'expense.delete');
    await tapKey(tester, 'confirm.delete');
    expect(find.text(t.failureNotFound), findsOneWidget);
    expect(find.byType(ExpenseFormScreen), findsOneWidget);
  });
}
