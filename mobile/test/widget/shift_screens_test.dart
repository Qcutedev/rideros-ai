import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/profit/domain/profit_records.dart';
import 'package:rideros_ai/features/shifts/domain/shift_models.dart';
import 'package:rideros_ai/features/shifts/presentation/shift_compare_screen.dart';
import 'package:rideros_ai/features/shifts/presentation/shift_detail_screen.dart';
import 'package:rideros_ai/features/shifts/presentation/shift_form_screen.dart';
import 'package:rideros_ai/features/shifts/presentation/shifts_screen.dart';
import 'package:rideros_ai/features/shifts/presentation/work_session_picker_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/profit_fakes.dart';
import '../helpers/pump.dart';
import '../helpers/shift_fakes.dart';

void main() {
  late FakeShiftRepository shifts;
  late ProfitFakes profit;

  setUp(() {
    shifts = FakeShiftRepository();
    profit = ProfitFakes();
  });

  List<Override> overrides() => fakeRepositories(
    FakeAuthRepository(),
    FakeRiderProfileRepository(configured: true),
    profit,
    shifts,
  );

  /// [days] dates in the last 84 days with working hours.
  void workedDays(int days) {
    for (var i = 0; i < days; i++) {
      profit.profit.dailyMetrics[DateTime.utc(
        2026,
        11,
        10,
      ).subtract(Duration(days: i * 2))] = metrics(
        hours: '4.00',
      );
    }
  }

  group('S-SHIFTS list', () {
    Future<void> pumpList(WidgetTester tester) => pumpScreen(
      tester,
      path: Routes.shifts,
      screen: const ShiftsScreen(),
      overrides: overrides(),
    );

    testWidgets('empty: explains scenarios and offers to create one', (
      tester,
    ) async {
      await pumpList(tester);
      expect(find.text(t.shiftsEmptyTitle), findsOneWidget);
      await tester.tap(find.text(t.shiftsAdd).first);
      await tester.pumpAndSettle();
      expect(find.text('route:${Routes.shiftNew}'), findsOneWidget);
    });

    testWidgets('error then retry', (tester) async {
      shifts.listError = const NetworkFailure();
      await pumpList(tester);
      expect(find.text(t.failureNetwork), findsOneWidget);
      shifts
        ..listError = null
        ..items.add(scenario());
      await tester.tap(find.text(t.commonRetry));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('shift.s-1')), findsOneWidget);
    });

    testWidgets('rows: estimate badge, time, day, method, net and per hour', (
      tester,
    ) async {
      shifts.items.addAll([
        scenario(),
        scenario(id: 's-2', name: 'Loss', net: '-20.00', perHour: '-4.00'),
      ]);
      await pumpList(tester);
      expect(find.text(t.badgeEstimate), findsNWidgets(2));
      expect(
        find.text('17:00–22:00 · วันศุกร์ · ${t.shiftMethodAssumption}'),
        findsNWidgets(2),
      );
      expect(find.text('฿969.50'), findsOneWidget);
      expect(find.text('฿193.90/ชม.'), findsOneWidget);
      expect(find.text('฿-20.00'), findsOneWidget);
      // No ML anywhere.
      expect(find.textContaining('ML'), findsNothing);

      await tester.tap(find.byKey(const Key('shift.s-2')));
      await tester.pumpAndSettle();
      expect(find.text('route:/shifts/scenarios/s-2'), findsOneWidget);
    });

    testWidgets('compare appears from two ticks; at most five', (tester) async {
      shifts.items.addAll([
        for (final id in ['a', 'b', 'c', 'd', 'e', 'f']) scenario(id: id),
      ]);
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpList(tester);
      expect(find.byKey(const Key('shifts.selectedCount')), findsNothing);

      await tapKey(tester, 'shift.b.select');
      expect(find.text(t.shiftsSelectedCount(1)), findsOneWidget);
      expect(find.byKey(const Key('shifts.compare')), findsNothing);

      for (final id in ['a', 'c', 'd', 'e']) {
        await tapKey(tester, 'shift.$id.select');
      }
      expect(find.text(t.shiftsCompareCount(5)), findsOneWidget);
      expect(find.text(t.shiftsMaxSelected), findsOneWidget);
      final sixth = tester.widget<Checkbox>(
        find.byKey(const Key('shift.f.select')),
      );
      expect(sixth.onChanged, isNull);

      // Untick one: the sixth can be ticked again.
      await tapKey(tester, 'shift.e.select');
      expect(
        tester
            .widget<Checkbox>(find.byKey(const Key('shift.f.select')))
            .onChanged,
        isNotNull,
      );

      await tapKey(tester, 'shifts.compare');
      expect(
        find.text('route:${Routes.shiftCompareFor(['b', 'a', 'c', 'd'])}'),
        findsOneWidget,
      );
    });

    testWidgets('clear the selection', (tester) async {
      shifts.items.addAll([scenario(id: 'a'), scenario(id: 'b')]);
      await pumpList(tester);
      await tapKey(tester, 'shift.a.select');
      await tapKey(tester, 'shift.b.select');
      await tapKey(tester, 'shifts.clearSelection');
      expect(find.byKey(const Key('shifts.compare')), findsNothing);
      expect(find.byKey(const Key('shifts.selectedCount')), findsNothing);
    });
  });

  group('S-SHIFT-FORM', () {
    Future<void> pumpNew(WidgetTester tester) => pushScreen(
      tester,
      pattern: Routes.shiftNew,
      location: Routes.shiftNew,
      screen: const ShiftFormScreen(),
      overrides: overrides(),
    );

    testWidgets('required fields are checked before sending', (tester) async {
      await pumpNew(tester);
      await tapKey(tester, 'shiftForm.submit');
      expect(find.text(t.validationRequired), findsNWidgets(3));
      expect(shifts.calls, isEmpty);
    });

    testWidgets('too many decimals and limits per field', (tester) async {
      await pumpNew(tester);
      await enter(tester, 'shiftForm.name', 'Test');
      await enter(tester, 'shiftForm.ordersPerHour', '31');
      await enter(tester, 'shiftForm.incomePerOrder', '45.123');
      await enter(tester, 'shiftForm.fuelKmPerLiter', '0');
      await tapKey(tester, 'shiftForm.submit');
      expect(find.text(t.validationNumberTooLarge('30')), findsOneWidget);
      expect(find.text(t.validationNumberTooManyDecimals(2)), findsOneWidget);
      expect(find.text(t.validationNumberMustBePositive), findsOneWidget);
      expect(shifts.calls, isEmpty);
    });

    testWidgets('new: default 17:00–22:00, saves and opens the details', (
      tester,
    ) async {
      await pumpNew(tester);
      expect(find.text('17:00'), findsOneWidget);
      expect(find.text('22:00'), findsOneWidget);
      expect(find.text(t.sessionDuration('5 ชม.')), findsOneWidget);
      await enter(tester, 'shiftForm.name', '  Friday  ');
      await enter(tester, 'shiftForm.ordersPerHour', '2.5');
      await enter(tester, 'shiftForm.incomePerOrder', '45');
      await enter(tester, 'shiftForm.otherCosts', '60');
      await tapKey(tester, 'shiftForm.submit');

      final input = shifts.lastInput!;
      expect(input.name, 'Friday');
      expect(input.startTime, const ClockTime(17, 0));
      expect(input.estimationMethod, EstimationMethod.assumption);
      expect(input.plannedWeekday, isNull);
      expect(input.assumptions.ordersPerHour.toString(), '2.5');
      expect(input.assumptions.kmPerOrder, isNull);
      expect(input.assumptions.otherCosts.toString(), '60');
      expect(find.text('route:/shifts/scenarios/new-1'), findsOneWidget);
    });

    testWidgets('weekday is optional and Monday first', (tester) async {
      await pumpNew(tester);
      await tapKey(tester, 'shiftForm.weekday');
      expect(find.text('วันจันทร์').last, findsOneWidget);
      await tester.tap(find.text('วันศุกร์').last);
      await tester.pumpAndSettle();
      await enter(tester, 'shiftForm.name', 'Fri');
      await enter(tester, 'shiftForm.ordersPerHour', '2');
      await enter(tester, 'shiftForm.incomePerOrder', '40');
      await tapKey(tester, 'shiftForm.submit');
      expect(shifts.lastInput!.plannedWeekday, 4);
    });

    testWidgets('history needs 5 worked days: only assumption until then', (
      tester,
    ) async {
      workedDays(2);
      await pumpNew(tester);
      expect(find.byKey(const Key('shiftForm.method')), findsNothing);
      expect(find.byKey(const Key('shiftForm.methodFixed')), findsOneWidget);
      expect(find.text(t.shiftHistoryUnavailable(2)), findsOneWidget);
      expect(find.text(t.shiftMethodHistorical), findsNothing);
    });

    testWidgets('historical hides the assumptions and sends fixed costs only', (
      tester,
    ) async {
      workedDays(5);
      await pumpNew(tester);
      await enter(tester, 'shiftForm.ordersPerHour', '2');
      await tapKey(tester, 'shiftForm.method.historical');
      expect(find.byKey(const Key('shiftForm.ordersPerHour')), findsNothing);
      expect(find.text(t.shiftMethodHistoricalHint), findsOneWidget);
      await enter(tester, 'shiftForm.name', 'History');
      await enter(tester, 'shiftForm.otherCosts', '40');
      await tapKey(tester, 'shiftForm.submit');
      final input = shifts.lastInput!;
      expect(input.estimationMethod, EstimationMethod.historical);
      expect(input.assumptions.ordersPerHour, isNull);
      expect(input.assumptions.otherCosts.toString(), '40');
    });

    testWidgets('server error shows a banner and keeps the form', (
      tester,
    ) async {
      shifts.saveError = const ApiFailure(
        statusCode: 400,
        code: 'insufficient_history',
      );
      await pumpNew(tester);
      await enter(tester, 'shiftForm.name', 'X');
      await enter(tester, 'shiftForm.ordersPerHour', '2');
      await enter(tester, 'shiftForm.incomePerOrder', '40');
      await tapKey(tester, 'shiftForm.submit');
      expect(find.text(t.failureInsufficientHistory), findsOneWidget);
      expect(find.byType(ShiftFormScreen), findsOneWidget);
    });

    testWidgets('saving shows a spinner and cannot be sent twice', (
      tester,
    ) async {
      shifts.saveGate = Completer<void>();
      await pumpNew(tester);
      await enter(tester, 'shiftForm.name', 'X');
      await enter(tester, 'shiftForm.ordersPerHour', '2');
      await enter(tester, 'shiftForm.incomePerOrder', '40');
      await tapKey(tester, 'shiftForm.submit', settle: false);
      await tester.tap(find.byKey(const Key('shiftForm.submit')));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(shifts.calls.where((c) => c == 'create'), hasLength(1));
      shifts.saveGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('edit: prefilled; a too short shift is stopped in the app', (
      tester,
    ) async {
      shifts.items.add(
        ShiftScenario.fromJson(
          scenarioJson(start: '10:00:00', end: '10:10:00', duration: 10),
        ),
      );
      await pushScreen(
        tester,
        pattern: Routes.shiftEditPattern,
        location: Routes.shiftEdit('s-1'),
        screen: const ShiftFormScreen(id: 's-1'),
        overrides: overrides(),
      );
      expect(find.text(t.shiftEditTitle), findsOneWidget);
      expect(find.text('Friday evening'), findsOneWidget);
      expect(find.text('2.5'), findsOneWidget);
      // Shown as a hint before saving, as an error after.
      expect(find.text(t.shiftLengthInvalid), findsOneWidget);
      await tapKey(tester, 'shiftForm.submit');
      expect(shifts.calls.where((c) => c.startsWith('update')), isEmpty);
    });

    testWidgets('edit: save updates and returns', (tester) async {
      shifts.items.add(scenario());
      await pushScreen(
        tester,
        pattern: Routes.shiftEditPattern,
        location: Routes.shiftEdit('s-1'),
        screen: const ShiftFormScreen(id: 's-1'),
        overrides: overrides(),
      );
      await enter(tester, 'shiftForm.name', 'Renamed');
      await tapKey(tester, 'shiftForm.submit');
      expect(shifts.calls, contains('update:s-1'));
      expect(shifts.items.single.name, 'Renamed');
      expect(find.text('route:${Routes.home}'), findsOneWidget);
      expect(find.text(t.recordSaved), findsOneWidget);
    });
  });

  group('S-SHIFT-DETAIL', () {
    Future<void> pumpDetail(WidgetTester tester, {String id = 's-1'}) =>
        pushScreen(
          tester,
          pattern: Routes.shiftDetailPattern,
          location: Routes.shiftDetail(id),
          screen: ShiftDetailScreen(id: id),
          overrides: overrides(),
        );

    testWidgets('assumption: figures, sources, inputs, not in TrueProfit', (
      tester,
    ) async {
      shifts.items.add(scenario());
      await pumpDetail(tester);
      expect(find.text('฿969.50'), findsOneWidget);
      expect(find.text('฿1,125.00'), findsOneWidget);
      expect(find.text('฿155.50'), findsOneWidget);
      expect(find.text('฿193.90/ชม.'), findsOneWidget);
      expect(find.byKey(const Key('shift.range')), findsNothing);
      expect(find.text(t.badgeEstimate), findsNWidgets(2));
      await scrollIntoView(tester, find.text(t.shiftDepreciationCost));
      // Fuel values from the profile, depreciation from the scenario.
      expect(find.text(t.shiftSourceProfile), findsOneWidget);
      expect(find.text(t.shiftSourceScenario), findsOneWidget);
      await scrollIntoView(tester, find.byKey(const Key('shift.inputsCard')));
      await scrollIntoView(tester, find.text(t.shiftFieldOtherCosts));
      expect(find.text(t.shiftInputFromProfile), findsNWidgets(3));
      await scrollIntoView(tester, find.byKey(const Key('shift.estimatedAt')));
      expect(find.text(t.shiftNotInTrueProfit), findsOneWidget);
    });

    testWidgets('historical: range, basis and warnings', (tester) async {
      shifts.items.add(
        scenario(
          method: 'historical',
          low: '600.00',
          high: '1100.00',
          details: historicalDetailsJson(
            basis: 'all_days',
            days: 9,
            warnings: [ShiftWarning.fewDaysForWeekday],
          ),
        ),
      );
      await pumpDetail(tester);
      expect(find.text(t.shiftRangeValue('฿600.00', '฿1,100.00')), findsOne);
      await scrollIntoView(
        tester,
        find.byKey(
          const Key('shift.warning.${ShiftWarning.fewDaysForWeekday}'),
        ),
      );
      expect(find.text(t.shiftWarningFewWeekdays), findsOneWidget);
      await scrollIntoView(tester, find.byKey(const Key('shift.basis')));
      expect(find.text(t.shiftBasisAllDays(9)), findsOneWidget);
      expect(find.text(t.shiftHistoricalNote), findsOneWidget);
      expect(find.byKey(const Key('shift.inputsCard')), findsNothing);
    });

    testWidgets('re-estimate: request and snackbar; failure says why', (
      tester,
    ) async {
      shifts.items.add(scenario());
      await pumpDetail(tester);
      await tapKey(tester, 'shift.reEstimate');
      expect(shifts.calls, contains('estimate:s-1'));
      expect(find.text(t.shiftReEstimated), findsOneWidget);
      // The content stays on screen while it reloads (no skeleton).
      expect(find.byKey(const Key('shift.reEstimate')), findsOneWidget);

      shifts.actionError = const ApiFailure(
        statusCode: 400,
        code: 'missing_assumption',
      );
      await tapKey(tester, 'shift.reEstimate');
      expect(find.text(t.failureMissingAssumption), findsOneWidget);
    });

    testWidgets('delete after confirming, then back', (tester) async {
      shifts.items.add(scenario());
      await pumpDetail(tester);
      await tapKey(tester, 'shift.delete');
      expect(find.text(t.shiftDeleteTitle), findsOneWidget);
      await tapKey(tester, 'confirm.cancel');
      expect(shifts.calls.where((c) => c.startsWith('delete')), isEmpty);

      await tapKey(tester, 'shift.delete');
      await tapKey(tester, 'confirm.delete');
      expect(shifts.calls, contains('delete:s-1'));
      expect(find.text('route:${Routes.home}'), findsOneWidget);
      expect(find.text(t.recordDeleted), findsOneWidget);
    });

    testWidgets('edit opens the form', (tester) async {
      shifts.items.add(scenario());
      await pumpDetail(tester);
      await tapKey(tester, 'shift.edit');
      expect(find.text('route:${Routes.shiftEdit('s-1')}'), findsOneWidget);
    });

    testWidgets('link: picker, then the session; unlink', (tester) async {
      shifts.items.add(scenario());
      profit.sessions.items.add(
        WorkSession(
          id: 'w-1',
          startedAt: DateTime(2026, 11, 10, 9),
          endedAt: DateTime(2026, 11, 10, 13, 30),
          createdAt: testCreatedAt,
          updatedAt: testCreatedAt,
        ),
      );
      final router = await pushScreen(
        tester,
        pattern: Routes.shiftDetailPattern,
        location: Routes.shiftDetail('s-1'),
        screen: const ShiftDetailScreen(id: 's-1'),
        overrides: overrides(),
      );
      await scrollIntoView(tester, find.byKey(const Key('shift.link')));
      expect(find.text(t.shiftLinkNone), findsOneWidget);
      await tapKey(tester, 'shift.link');
      expect(find.text('route:${Routes.shiftSessionPicker}'), findsOneWidget);
      // The picker answers with a session.
      router.pop(profit.sessions.items.single);
      await tester.pumpAndSettle();
      expect(shifts.calls, contains('link=w-1:s-1'));
      await scrollIntoView(
        tester,
        find.byKey(const Key('shift.linkedSession')),
      );
      expect(
        find.text('10 พ.ย. 2026 09:00–13:30 (4 ชม. 30 นาที)'),
        findsOneWidget,
      );

      await scrollAndTap(tester, 'shift.unlink');
      expect(shifts.calls, contains('link=none:s-1'));
      await scrollIntoView(tester, find.byKey(const Key('shift.link')));
      expect(find.text(t.shiftLinkNone), findsOneWidget);
    });

    testWidgets('not found: error with retry', (tester) async {
      await pumpDetail(tester, id: 'gone');
      expect(find.text(t.failureNotFound), findsOneWidget);
      expect(find.text(t.commonRetry), findsOneWidget);
    });
  });

  group('S-SHIFT-COMPARE', () {
    testWidgets('both winners marked; may be different scenarios', (
      tester,
    ) async {
      shifts.items.addAll([
        scenario(id: 'a', name: 'Long', net: '900.00', perHour: '100.00'),
        scenario(id: 'b', name: 'Short', net: '500.00', perHour: '125.00'),
      ]);
      await pumpScreen(
        tester,
        path: Routes.shiftCompare,
        initialLocation: Routes.shiftCompareFor(['a', 'b']),
        screen: const ShiftCompareScreen(ids: 'a,b'),
        overrides: overrides(),
      );
      expect(shifts.calls, contains('compare:a,b'));
      expect(find.byKey(const Key('compare.a.bestNet')), findsOneWidget);
      expect(find.byKey(const Key('compare.a.bestPerHour')), findsNothing);
      expect(find.byKey(const Key('compare.b.bestPerHour')), findsOneWidget);
      expect(find.text(t.shiftCompareNote), findsOneWidget);
      expect(find.textContaining('Long\n฿900.00'), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      shifts.compareError = const NetworkFailure();
      await pumpScreen(
        tester,
        path: Routes.shiftCompare,
        screen: const ShiftCompareScreen(ids: 'a,b'),
        overrides: overrides(),
      );
      expect(find.text(t.failureNetwork), findsOneWidget);
    });
  });

  group('work-session picker', () {
    testWidgets('empty: offers to record a session', (tester) async {
      await pumpScreen(
        tester,
        path: Routes.shiftSessionPicker,
        screen: const WorkSessionPickerScreen(),
        overrides: overrides(),
      );
      expect(find.text(t.shiftPickSessionEmptyTitle), findsOneWidget);
      await tester.tap(find.text(t.sessionAdd));
      await tester.pumpAndSettle();
      expect(find.text('route:${Routes.workSessionNew}'), findsOneWidget);
    });

    testWidgets('tapping a session returns it', (tester) async {
      profit.sessions.items.add(
        WorkSession(
          id: 'w-1',
          startedAt: DateTime(2026, 11, 10, 9),
          endedAt: DateTime(2026, 11, 10, 13),
          isDemo: true,
          createdAt: testCreatedAt,
          updatedAt: testCreatedAt,
        ),
      );
      final router = await pumpScreen(
        tester,
        path: Routes.shiftSessionPicker,
        screen: const WorkSessionPickerScreen(),
        overrides: overrides(),
        initialLocation: Routes.home,
      );
      WorkSession? picked;
      unawaited(
        router
            .push<WorkSession>(Routes.shiftSessionPicker)
            .then((s) => picked = s),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.demoLabel), findsOneWidget);
      await tapKey(tester, 'pickSession.w-1');
      expect(picked?.id, 'w-1');
    });
  });
}
