import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/profit/domain/profit_records.dart';
import 'package:rideros_ai/features/profit/presentation/work_session_form_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/profit_fakes.dart';
import '../helpers/pump.dart';

void main() {
  late ProfitFakes profit;

  setUp(() => profit = ProfitFakes());

  Future<void> open(WidgetTester tester, {String? id}) => pushScreen(
    tester,
    pattern: id == null ? Routes.workSessionNew : Routes.workSessionEditPattern,
    location: id == null ? Routes.workSessionNew : Routes.workSessionEdit(id),
    screen: WorkSessionFormScreen(id: id),
    overrides: fakeRepositories(FakeAuthRepository(), null, profit),
  );

  WorkSession existing(DateTime start, DateTime end) =>
      profit.sessions.add(WorkSessionInput(startedAt: start, endedAt: end));

  testWidgets('new: the four hours up to now, in 5-minute steps', (
    tester,
  ) async {
    await open(tester); // now = 10 Nov 14:07
    expect(find.text('10:05'), findsOneWidget);
    expect(find.text('14:05'), findsOneWidget);
    expect(
      find.textContaining(t.sessionDuration(t.durationHours(4))),
      findsOneWidget,
    );

    await enter(tester, 'session.orders', '9');
    await enter(tester, 'session.distance', '38.5');
    await tapKey(tester, 'session.submit');
    final input = profit.sessions.lastInput!;
    expect(input.startedAt, DateTime(2026, 11, 10, 10, 5));
    expect(input.endedAt, DateTime(2026, 11, 10, 14, 5));
    expect(input.orderCount, 9);
    expect(input.distanceKm, d('38.5'));
    expect(find.text('route:${Routes.home}'), findsOneWidget);
  });

  testWidgets('field validation', (tester) async {
    await open(tester);
    await enter(tester, 'session.orders', '-2');
    await enter(tester, 'session.distance', '1.234');
    await tapKey(tester, 'session.submit');
    expect(find.text(t.validationNumberMustNotBeNegative), findsOneWidget);
    expect(find.text(t.validationNumberTooManyDecimals(2)), findsOneWidget);
    expect(profit.sessions.calls, isEmpty);
  });

  testWidgets('edit: a shift past midnight keeps its next-day end', (
    tester,
  ) async {
    final session = existing(
      DateTime(2026, 11, 9, 20),
      DateTime(2026, 11, 10, 2),
    );
    await open(tester, id: session.id);
    expect(find.text(t.sessionEditTitle), findsOneWidget);
    expect(find.textContaining(t.sessionCrossesMidnight), findsOneWidget);

    await enter(tester, 'session.notes', 'late shift');
    await tapKey(tester, 'session.submit');
    expect(profit.sessions.calls.last, 'update:${session.id}');
    expect(profit.sessions.lastInput!.startedAt, DateTime(2026, 11, 9, 20));
    expect(profit.sessions.lastInput!.endedAt, DateTime(2026, 11, 10, 2));
    expect(profit.sessions.lastInput!.notes, 'late shift');
  });

  testWidgets('equal start and end times are rejected', (tester) async {
    final session = existing(
      DateTime(2026, 11, 9, 9),
      DateTime(2026, 11, 10, 9),
    );
    await open(tester, id: session.id);
    expect(find.text(t.sessionTimesEqual), findsNothing);
    await tapKey(tester, 'session.submit');
    expect(find.text(t.sessionTimesEqual), findsOneWidget);
    expect(profit.sessions.calls.where((c) => c.startsWith('update')), isEmpty);
  });

  testWidgets('overlap with another session is explained', (tester) async {
    profit.sessions.saveError = const ApiFailure(
      statusCode: 409,
      code: ApiErrorCode.workSessionOverlap,
    );
    await open(tester);
    await tapKey(tester, 'session.submit');
    expect(find.text(t.failureWorkSessionOverlap), findsOneWidget);
  });

  testWidgets('changing the end time with the picker', (tester) async {
    await open(tester);
    await tapKey(tester, 'session.end');
    expect(find.byType(TimePickerDialog), findsOneWidget);
    // Type the time instead of dragging the dial.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '23');
    await tester.enterText(fields.at(1), '30');
    final ok = MaterialLocalizations.of(
      tester.element(find.byType(TimePickerDialog)),
    ).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pumpAndSettle();
    expect(find.text('23:30'), findsOneWidget);

    await tapKey(tester, 'session.submit');
    expect(profit.sessions.lastInput!.endedAt, DateTime(2026, 11, 10, 23, 30));
  });

  testWidgets('delete after confirming', (tester) async {
    final session = existing(
      DateTime(2026, 11, 10, 8),
      DateTime(2026, 11, 10, 12),
    );
    await open(tester, id: session.id);
    await tapKey(tester, 'session.delete');
    await tapKey(tester, 'confirm.delete');
    expect(profit.sessions.items, isEmpty);
  });
}
