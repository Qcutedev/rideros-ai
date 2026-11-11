import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/profit/domain/profit_records.dart';
import 'package:rideros_ai/features/profit/presentation/income_form_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/profit_fakes.dart';
import '../helpers/pump.dart';

void main() {
  late ProfitFakes profit;

  setUp(() => profit = ProfitFakes());

  Future<void> openNew(WidgetTester tester) => pushScreen(
    tester,
    pattern: Routes.incomeNew,
    location: Routes.incomeNew,
    screen: const IncomeFormScreen(),
    overrides: fakeRepositories(FakeAuthRepository(), null, profit),
  );

  Future<void> openEdit(WidgetTester tester, String id) => pushScreen(
    tester,
    pattern: Routes.incomeEditPattern,
    location: Routes.incomeEdit(id),
    screen: IncomeFormScreen(id: id),
    overrides: fakeRepositories(FakeAuthRepository(), null, profit),
  );

  Future<void> submit(WidgetTester tester) => tapKey(tester, 'income.submit');

  group('validation', () {
    testWidgets('amount is required; nothing is sent', (tester) async {
      await openNew(tester);
      await submit(tester);
      expect(find.text(t.validationRequired), findsOneWidget);
      expect(profit.income.calls, isEmpty);
    });

    for (final (field, input, message) in [
      ('income.amount', 'abc', t.validationNumberInvalid),
      ('income.amount', '1.005', t.validationNumberTooManyDecimals(2)),
      ('income.amount', '-1', t.validationNumberMustNotBeNegative),
      (
        'income.amount',
        '10000000000',
        t.validationNumberTooLarge('9999999999.99'),
      ),
      ('income.hours', '0', t.validationNumberMustBePositive),
      ('income.hours', '24.5', t.validationNumberTooLarge('24')),
      ('income.orders', '1.5', t.validationWholeNumber),
      ('income.orders', '10001', t.validationNumberTooLarge('10000')),
      ('income.distance', '1,000', t.validationNumberInvalid),
      ('income.source', 'x' * 51, null),
    ]) {
      testWidgets('$field "$input"', (tester) async {
        await openNew(tester);
        await enter(tester, 'income.amount', '100');
        await enter(tester, field, input);
        await submit(tester);
        if (message != null) {
          expect(find.text(message), findsOneWidget);
          expect(profit.income.calls, isEmpty);
        } else {
          // maxLength stops typing at the limit: the value is cut to 50.
          expect(profit.income.lastInput!.sourceLabel, 'x' * 50);
        }
      });
    }
  });

  testWidgets('create sends exact decimals, pops and confirms', (tester) async {
    await openNew(tester);
    await enter(tester, 'income.amount', '800.5');
    await enter(tester, 'income.source', '  Grab  ');
    await enter(tester, 'income.hours', '6.25');
    await enter(tester, 'income.orders', '12');
    await enter(tester, 'income.distance', '45.2');
    await enter(tester, 'income.notes', 'rain');
    await submit(tester);

    final input = profit.income.lastInput!;
    expect(input.occurredOn, DateTime.utc(2026, 11, 10));
    expect(input.amount, d('800.5'));
    expect(input.sourceLabel, 'Grab');
    expect(input.workingHours, d('6.25'));
    expect(input.orderCount, 12);
    expect(input.distanceKm, d('45.2'));
    expect(input.notes, 'rain');
    expect(input.workSessionId, isNull);
    expect(find.text('route:${Routes.home}'), findsOneWidget);
    expect(find.text(t.recordSaved), findsOneWidget);
  });

  testWidgets('saving: spinner and no second submit', (tester) async {
    profit.income.saveGate = Completer<void>();
    await openNew(tester);
    await enter(tester, 'income.amount', '100');
    await tapKey(tester, 'income.submit', settle: false);
    await tester.pump();
    await tapKey(tester, 'income.submit', settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    profit.income.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(profit.income.calls, ['create']);
  });

  testWidgets('server error shows a banner and keeps the form', (tester) async {
    profit.income.saveError = const ApiFailure(
      statusCode: 422,
      code: ApiErrorCode.validationError,
    );
    await openNew(tester);
    await enter(tester, 'income.amount', '100');
    await submit(tester);
    expect(find.text(t.failureValidation), findsOneWidget);
    expect(find.byType(IncomeFormScreen), findsOneWidget);
  });

  testWidgets('date picker changes the date', (tester) async {
    await openNew(tester);
    await tapKey(tester, 'income.date');
    await tester.tap(find.text('3'));
    final ok = MaterialLocalizations.of(
      tester.element(find.byType(DatePickerDialog)),
    ).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pumpAndSettle();
    await enter(tester, 'income.amount', '100');
    await submit(tester);
    expect(profit.income.lastInput!.occurredOn, DateTime.utc(2026, 11, 3));
  });

  testWidgets('linking a work session hides hours and sends the id', (
    tester,
  ) async {
    final session = profit.sessions.add(
      WorkSessionInput(
        startedAt: DateTime(2026, 11, 10, 18),
        endedAt: DateTime(2026, 11, 10, 22),
      ),
    );
    await openNew(tester);
    await enter(tester, 'income.amount', '100');
    await enter(tester, 'income.hours', '5');
    await tapKey(tester, 'income.session');
    await tester.tap(find.text('18:00 – 22:00').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('income.hours')), findsNothing);

    await submit(tester);
    expect(profit.income.lastInput!.workSessionId, session.id);
    expect(profit.income.lastInput!.workingHours, isNull);
  });

  testWidgets('session list failure offers a retry', (tester) async {
    profit.sessions.listError = const NetworkFailure();
    await openNew(tester);
    expect(find.text(t.incomeSessionLoadFailed), findsOneWidget);
    profit.sessions.listError = null;
    await tapKey(tester, 'income.session.retry');
    expect(find.byKey(const Key('income.session')), findsOneWidget);
  });

  group('edit', () {
    late Income existing;

    setUp(() {
      existing = profit.income.add(
        IncomeInput(
          occurredOn: DateTime.utc(2026, 11, 8),
          amount: d('800.00'),
          workingHours: d('6.50'),
          sourceLabel: 'LINE MAN',
        ),
      );
    });

    testWidgets('prefills and updates', (tester) async {
      await openEdit(tester, existing.id);
      expect(find.text(t.incomeEditTitle), findsOneWidget);
      expect(find.text('800'), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);
      expect(find.text('LINE MAN'), findsOneWidget);

      await enter(tester, 'income.amount', '900');
      await enter(tester, 'income.source', '');
      await submit(tester);
      expect(profit.income.calls.last, 'update:${existing.id}');
      expect(profit.income.lastInput!.amount, d('900'));
      expect(profit.income.lastInput!.sourceLabel, isNull);
      expect(profit.income.lastInput!.occurredOn, DateTime.utc(2026, 11, 8));
    });

    testWidgets('delete asks first; cancel keeps the record', (tester) async {
      await openEdit(tester, existing.id);
      await tapKey(tester, 'income.delete');
      expect(find.text(t.recordDeleteTitle), findsOneWidget);
      await tapKey(tester, 'confirm.cancel');
      expect(profit.income.calls.where((c) => c.startsWith('delete')), isEmpty);

      await tapKey(tester, 'income.delete');
      await tapKey(tester, 'confirm.delete');
      expect(profit.income.calls.last, 'delete:${existing.id}');
      expect(find.text('route:${Routes.home}'), findsOneWidget);
      expect(find.text(t.recordDeleted), findsOneWidget);
    });

    testWidgets('a missing record shows "not found" with retry', (
      tester,
    ) async {
      await openEdit(tester, 'missing');
      expect(find.text(t.failureNotFound), findsOneWidget);
      expect(find.text(t.commonRetry), findsOneWidget);
    });
  });
}
