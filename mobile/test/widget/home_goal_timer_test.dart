import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/app.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/widgets/motion.dart';
import 'package:rideros_ai/features/dashboard/presentation/home_screen.dart';
import 'package:rideros_ai/features/profile/domain/rider_profile.dart';
import 'package:rideros_ai/features/profit/data/shift_timer_store.dart';
import 'package:rideros_ai/features/profit/domain/profit_summary.dart';
import 'package:rideros_ai/features/profit/domain/shift_timer.dart';
import 'package:rideros_ai/features/profit/presentation/income_form_screen.dart';
import 'package:rideros_ai/features/profit/presentation/work_session_form_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/file_bundle.dart';
import '../helpers/profit_fakes.dart';
import '../helpers/pump.dart';

final _profile = RiderProfile(
  vehicleType: VehicleType.motorcycle,
  fuelKmPerLiter: Decimal.parse('45.5'),
  timezone: 'Asia/Bangkok',
  isConfigured: true,
);

/// The whole app, signed in, on Home (the timer opens the real session form).
/// A running clock never settles, so [settle] = false pumps a few frames instead.
Future<void> _pumpApp(
  WidgetTester tester,
  List<Override> overrides, {
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        brandIntroEnabledProvider.overrideWithValue(false),
        ...overrides,
      ],
      retry: (retryCount, error) => null,
      child: DefaultAssetBundle(
        bundle: FileAssetBundle(),
        child: const RiderOsApp(),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

/// Lets the running clock tick without waiting for it to settle (it never does).
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late FakeAuthRepository auth;
  late FakeRiderProfileRepository profiles;
  late ProfitFakes profit;

  setUp(() {
    auth = FakeAuthRepository()..restoreUser = testUser;
    profiles = FakeRiderProfileRepository(configured: true, profile: _profile);
    profit = ProfitFakes();
    // Today: ฿513.46 − ฿71.18 = ฿442.28.
    profit.profit.setSummary(
      ProfitPeriod.day,
      metrics(
        revenue: '513.46',
        expenses: '71.18',
        hours: '4.20',
        incomeCount: 1,
        expenseCount: 1,
        sessionCount: 1,
      ),
    );
  });

  Future<void> pumpHome(WidgetTester tester) => pumpScreen(
    tester,
    path: Routes.home,
    screen: const HomeScreen(),
    overrides: fakeRepositories(auth, profiles, profit),
  );

  Finder inToday(Finder f) =>
      find.descendant(of: find.byKey(const Key('home.today')), matching: f);

  group('daily goal', () {
    testWidgets('no goal: the card offers one; saving keeps the profile', (
      tester,
    ) async {
      await pumpHome(tester);
      expect(inToday(find.text(t.goalSetTitle)), findsOneWidget);

      await tapKey(tester, 'goal.set');
      expect(find.text(t.goalSheetTitle), findsOneWidget);
      expect(find.byKey(const Key('goal.remove')), findsNothing);
      await enter(tester, 'goal.amount', '600');
      await tapKey(tester, 'goal.save');

      expect(
        profiles.lastSaved,
        RiderProfileInput.from(_profile)
            .copyWith(dailyGoal: Decimal.fromInt(600)),
      );
      expect(find.text(t.goalSheetTitle), findsNothing);
      expect(find.text(t.goalSaved), findsOneWidget);
      expect(inToday(find.text(t.goalRemaining('฿157.72'))), findsOneWidget);
      expect(inToday(find.text(t.goalTarget('฿600.00'))), findsOneWidget);
      expect(inToday(find.text(t.goalPercent(73))), findsOneWidget);
    });

    testWidgets('reached: check mark and the surplus', (tester) async {
      profiles = FakeRiderProfileRepository(
        configured: true,
        profile: _profile.copyWith(dailyGoal: Decimal.parse('400')),
      );
      await pumpHome(tester);
      expect(inToday(find.text(t.goalReached)), findsOneWidget);
      expect(inToday(find.text(t.goalSurplus('฿42.28'))), findsOneWidget);
      expect(inToday(find.byType(SuccessCheck)), findsOneWidget);
      expect(find.byKey(const Key('goal.percent')), findsNothing);
    });

    testWidgets('a loss shows the whole goal still to earn', (tester) async {
      profit.profit.setSummary(
        ProfitPeriod.day,
        metrics(revenue: '0.00', expenses: '80.00', expenseCount: 1),
      );
      profiles = FakeRiderProfileRepository(
        configured: true,
        profile: _profile.copyWith(dailyGoal: Decimal.parse('500')),
      );
      await pumpHome(tester);
      expect(inToday(find.text(t.goalRemaining('฿580.00'))), findsOneWidget);
      expect(inToday(find.text(t.goalPercent(0))), findsOneWidget);
    });

    testWidgets('edit shows the goal; remove clears it', (tester) async {
      profiles = FakeRiderProfileRepository(
        configured: true,
        profile: _profile.copyWith(dailyGoal: Decimal.parse('600')),
      );
      await pumpHome(tester);
      await tapKey(tester, 'goal.edit');
      expect(
        find.descendant(
          of: find.byKey(const Key('goal.amount')),
          matching: find.text('600'),
        ),
        findsOneWidget,
      );
      await tapKey(tester, 'goal.remove');
      expect(profiles.lastSaved?.dailyGoal, isNull);
      expect(profiles.lastSaved?.vehicleType, VehicleType.motorcycle);
      expect(find.text(t.goalRemoved), findsOneWidget);
      expect(inToday(find.text(t.goalSetTitle)), findsOneWidget);
    });

    testWidgets('validation before saving', (tester) async {
      await pumpHome(tester);
      await tapKey(tester, 'goal.set');
      await tapKey(tester, 'goal.save');
      expect(find.text(t.validationRequired), findsOneWidget);
      await enter(tester, 'goal.amount', '0');
      await tapKey(tester, 'goal.save');
      expect(find.text(t.validationNumberMustBePositive), findsOneWidget);
      await enter(tester, 'goal.amount', '500.005');
      await tapKey(tester, 'goal.save');
      expect(find.text(t.validationNumberTooManyDecimals(2)), findsOneWidget);
      expect(profiles.saves, 0);
    });

    testWidgets('a failed save says why and keeps the sheet', (tester) async {
      profiles.saveError = const NetworkFailure();
      await pumpHome(tester);
      await tapKey(tester, 'goal.set');
      await enter(tester, 'goal.amount', '600');
      await tapKey(tester, 'goal.save');
      expect(find.text(t.failureNetwork), findsOneWidget);
      expect(find.text(t.goalSheetTitle), findsOneWidget);
    });

    testWidgets('profile not loaded: no goal block, figures still shown', (
      tester,
    ) async {
      profiles.fetchError = const NetworkFailure();
      await pumpHome(tester);
      expect(inToday(find.text('฿442.28')), findsOneWidget);
      expect(find.byKey(const Key('goal.set')), findsNothing);
      expect(find.byKey(const Key('goal.edit')), findsNothing);
    });
  });

  group('shift timer', () {
    final start = DateTime(2026, 11, 10, 9, 58, 41); // testNow is 14:07

    void seed(ShiftTimerState state) =>
        profit.timer.entries[testUser.id] = encodeShiftTimer(state)!;

    testWidgets('start: the card turns into a running clock and is stored', (
      tester,
    ) async {
      await pumpHome(tester);
      expect(find.text(t.timerIdleTitle), findsOneWidget);
      await tapKey(tester, 'timer.start', settle: false);
      await _pumpFrames(tester);
      expect(find.byKey(const Key('timer.running')), findsOneWidget);
      expect(find.text('00:00:00'), findsOneWidget);
      expect(find.text(t.timerStartedAt('14:07')), findsOneWidget);
      expect(
        decodeShiftTimer(profit.timer.entries[testUser.id]),
        TimerRunning(testNow()),
      );
    });

    testWidgets('a stored timer keeps counting from its start', (tester) async {
      seed(TimerRunning(start));
      await pumpScreen(
        tester,
        path: Routes.home,
        screen: const HomeScreen(),
        overrides: fakeRepositories(auth, profiles, profit),
        settle: false,
      );
      await _pumpFrames(tester);
      expect(find.text('04:08:19'), findsOneWidget);
      expect(find.text(t.timerStartedAt('09:58')), findsOneWidget);
    });

    testWidgets(
      'stop → session form → saved → income form linked to it → saved',
      (tester) async {
        seed(TimerRunning(start));
        await _pumpApp(
          tester,
          fakeRepositories(auth, profiles, profit),
          settle: false,
        );
        expect(find.byKey(const Key('timer.running')), findsOneWidget);
        await tapKey(tester, 'timer.stop', settle: false);
        await tester.pumpAndSettle();

        expect(find.byType(WorkSessionFormScreen), findsOneWidget);
        await enter(tester, 'session.orders', '12');
        await tapKey(tester, 'session.submit');

        final saved = profit.sessions.lastInput!;
        expect(saved.startedAt, DateTime(2026, 11, 10, 9, 58));
        expect(saved.endedAt, DateTime(2026, 11, 10, 14, 7));
        expect(saved.orderCount, 12);
        // The timer is cleared as soon as the session is stored.
        expect(profit.timer.entries, isEmpty);

        // Next: the income form for that session.
        expect(find.byType(IncomeFormScreen), findsOneWidget);
        expect(find.text(t.incomeForSession('09:58 – 14:07')), findsOneWidget);
        expect(find.byKey(const Key('income.hours')), findsNothing);
        await enter(tester, 'income.amount', '650');
        await tapKey(tester, 'income.submit');

        final income = profit.income.lastInput!;
        expect(income.workSessionId, profit.sessions.items.single.id);
        expect(income.occurredOn, DateTime.utc(2026, 11, 10));
        expect(income.amount, Decimal.parse('650'));
        expect(income.workingHours, isNull);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byKey(const Key('timer.idle')), findsOneWidget);
      },
    );

    testWidgets('skipping the income form goes home without income', (
      tester,
    ) async {
      seed(TimerStopped(start, testNow()));
      await _pumpApp(tester, fakeRepositories(auth, profiles, profit));
      await tapKey(tester, 'timer.save');
      await tapKey(tester, 'session.submit');
      expect(find.byType(IncomeFormScreen), findsOneWidget);

      await tapKey(tester, 'income.skip');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byKey(const Key('timer.idle')), findsOneWidget);
      expect(profit.sessions.items, hasLength(1));
      expect(profit.income.calls, isEmpty);
    });

    testWidgets('leaving the form without saving keeps the stopped timer', (
      tester,
    ) async {
      seed(TimerStopped(start, testNow()));
      await _pumpApp(tester, fakeRepositories(auth, profiles, profit));
      expect(
        find.text(t.timerStoppedRange('4 ชม. 8 นาที', '09:58', '14:07')),
        findsOneWidget,
      );
      await tapKey(tester, 'timer.save');
      expect(find.byType(WorkSessionFormScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('timer.stopped')), findsOneWidget);
      expect(profit.sessions.items, isEmpty);
      expect(profit.timer.entries, isNotEmpty);
    });

    testWidgets('a save error keeps the form and the timer', (tester) async {
      profit.sessions.saveError = const ApiFailure(
        statusCode: 409,
        code: ApiErrorCode.workSessionOverlap,
      );
      seed(TimerStopped(start, testNow()));
      await _pumpApp(tester, fakeRepositories(auth, profiles, profit));
      await tapKey(tester, 'timer.save');
      await tapKey(tester, 'session.submit');
      expect(find.byType(WorkSessionFormScreen), findsOneWidget);
      expect(profit.timer.entries, isNotEmpty);
    });

    testWidgets('resume goes back to counting from the same start', (
      tester,
    ) async {
      seed(TimerStopped(start, testNow()));
      await pumpHome(tester);
      await tapKey(tester, 'timer.resume', settle: false);
      await _pumpFrames(tester);
      expect(find.byKey(const Key('timer.running')), findsOneWidget);
      expect(
        decodeShiftTimer(profit.timer.entries[testUser.id]),
        TimerRunning(start),
      );
    });

    testWidgets('discard asks first, then clears', (tester) async {
      seed(TimerStopped(start, testNow()));
      await pumpHome(tester);
      await tapKey(tester, 'timer.discard');
      expect(find.text(t.timerDiscardTitle), findsOneWidget);
      await tapKey(tester, 'confirm.cancel');
      expect(find.byKey(const Key('timer.stopped')), findsOneWidget);

      await tapKey(tester, 'timer.discard');
      await tapKey(tester, 'confirm.delete');
      expect(find.byKey(const Key('timer.idle')), findsOneWidget);
      expect(profit.timer.entries, isEmpty);
    });

    testWidgets('under a minute: discard or carry on, no form', (tester) async {
      await pumpHome(tester);
      await tapKey(tester, 'timer.start', settle: false);
      await _pumpFrames(tester);
      // The test clock stands still: stopping now is 0 seconds.
      await tapKey(tester, 'timer.stop', settle: false);
      await tester.pumpAndSettle();
      expect(find.text(t.timerTooShortTitle), findsOneWidget);
      await tapKey(tester, 'timer.shortDiscard');
      expect(find.byKey(const Key('timer.idle')), findsOneWidget);
      expect(find.text('route:${Routes.workSessionNew}'), findsNothing);
    });

    testWidgets('over 24 hours: warned, then the form flags the end time', (
      tester,
    ) async {
      seed(
        TimerStopped(testNow().subtract(const Duration(hours: 26)), testNow()),
      );
      await _pumpApp(tester, fakeRepositories(auth, profiles, profit));
      await tapKey(tester, 'timer.save');
      expect(find.text(t.timerTooLongTitle), findsOneWidget);
      await tapKey(tester, 'timer.longContinue');
      expect(find.byType(WorkSessionFormScreen), findsOneWidget);
      expect(find.byKey(const Key('session.timerTooLong')), findsOneWidget);
    });

    testWidgets('an unreadable store just shows the start card', (
      tester,
    ) async {
      profit.timer.readError = Exception('disk');
      await pumpHome(tester);
      expect(find.byKey(const Key('timer.idle')), findsOneWidget);
    });
  });
}
