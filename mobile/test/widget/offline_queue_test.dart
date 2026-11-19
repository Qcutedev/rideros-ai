import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/app.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/dashboard/presentation/home_screen.dart';
import 'package:rideros_ai/features/profile/domain/rider_profile.dart';
import 'package:rideros_ai/features/profile/presentation/profile_screen.dart';
import 'package:rideros_ai/features/profit/data/shift_timer_store.dart';
import 'package:rideros_ai/features/profit/domain/pending_record.dart';
import 'package:rideros_ai/features/profit/domain/profit_summary.dart';
import 'package:rideros_ai/features/profit/domain/shift_timer.dart';
import 'package:rideros_ai/features/profit/presentation/income_form_screen.dart';
import 'package:rideros_ai/features/profit/presentation/pending_records_screen.dart';
import 'package:rideros_ai/features/profit/presentation/true_profit_screen.dart';
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

/// The whole app, signed in, on Home.
Future<void> _pumpApp(WidgetTester tester, List<Override> overrides) async {
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
  await tester.pumpAndSettle();
}

PendingRecord _income(String id, {String amount = '250', String? session}) =>
    PendingRecord(
      id: id,
      kind: PendingKind.income,
      body: {
        'occurred_on': '2026-11-10',
        'amount': amount,
        'work_session_id': session,
      },
      queuedAt: DateTime.utc(2026, 11, 10, 7),
    );

/// 10:00–14:00 in the device's time zone, so the label reads the same on CI (UTC).
PendingRecord _session(String id) => PendingRecord(
  id: id,
  kind: PendingKind.workSession,
  body: {
    'started_at': DateTime(2026, 11, 10, 10).toUtc().toIso8601String(),
    'ended_at': DateTime(2026, 11, 10, 14).toUtc().toIso8601String(),
  },
  queuedAt: DateTime.utc(2026, 11, 10, 7),
);

void main() {
  late FakeAuthRepository auth;
  late FakeRiderProfileRepository profiles;
  late ProfitFakes profit;

  setUp(() {
    auth = FakeAuthRepository()..restoreUser = testUser;
    profiles = FakeRiderProfileRepository(configured: true, profile: _profile);
    profit = ProfitFakes();
    profit.profit.setSummary(
      ProfitPeriod.day,
      metrics(revenue: '513.46', expenses: '71.18', incomeCount: 1),
    );
  });

  List<Override> overrides() => fakeRepositories(auth, profiles, profit);

  /// Records already waiting on the device; the first automatic run fails.
  void seedQueue(List<PendingRecord> items) {
    profit.pendingStore.entries[testUser.id] = encodePendingRecords(items)!;
    profit.sender.error = const NetworkFailure();
  }

  Finder banner() => find.byKey(const Key('pending.banner'));

  /// Home is a lazy list: after a form, scroll back up to the banner (a row
  /// above the viewport counts as offstage for finders).
  Future<void> scrollToBanner(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      banner(),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no connection: the form closes saying it is kept, Home shows '
      'the banner', (tester) async {
    profit.income.saveError = const NetworkFailure();
    profit.sender.error = const NetworkFailure();
    await _pumpApp(tester, overrides());
    expect(banner(), findsNothing);

    await scrollAndTap(tester, 'home.addIncome');
    expect(find.byType(IncomeFormScreen), findsOneWidget);
    await enter(tester, 'income.amount', '250');
    await tapKey(tester, 'income.submit');

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text(t.recordQueued), findsOneWidget);
    await scrollToBanner(tester);
    expect(find.text(t.pendingBannerWaiting(1)), findsOneWidget);
    final stored = profit.pendingStore.of(testUser.id).single;
    expect(stored.kind, PendingKind.income);
    expect(stored.body['amount'], '250');
  });

  testWidgets('banner → queue → send now: sent, banner gone', (tester) async {
    seedQueue([_income('a')]);
    await _pumpApp(tester, overrides());
    expect(find.text(t.pendingBannerWaiting(1)), findsOneWidget);

    await tester.tap(banner());
    await tester.pumpAndSettle();
    expect(find.byType(PendingRecordsScreen), findsOneWidget);
    expect(find.text('${t.incomeTitle} 250.00'), findsOneWidget);
    expect(find.textContaining('\n${t.pendingStatusWaiting}'), findsOneWidget);
    expect(find.text(t.pendingIntro), findsOneWidget);

    profit.sender.error = null;
    await tapKey(tester, 'pending.sendNow');
    expect(profit.sender.sent.single.id, 'a');
    expect(find.byKey(const Key('pending.empty')), findsOneWidget);
    expect(profit.pendingStore.entries, isEmpty);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(banner(), findsNothing);
  });

  testWidgets('a refused record says why; deleting its session asks first '
      'and takes the linked income along', (tester) async {
    seedQueue([
      _session('s1').failed(409, 'work_session_overlap'),
      _income('i1', session: 's1').failed(0, linkedSessionFailedCode),
      _income('i2', amount: '80'),
    ]);
    await _pumpApp(tester, overrides());
    expect(find.text(t.pendingBannerFailed(2)), findsOneWidget);

    await tester.tap(banner());
    await tester.pumpAndSettle();
    expect(find.text(t.pendingFailedHint), findsOneWidget);
    expect(
      find.textContaining(t.pendingStatusFailed(t.failureWorkSessionOverlap)),
      findsOneWidget,
    );
    expect(
      find.textContaining(t.pendingStatusFailed(t.failureLinkedSessionFailed)),
      findsOneWidget,
    );
    expect(find.text('${t.sessionTitle} 10:00 – 14:00'), findsOneWidget);

    await tapKey(tester, 'pending.delete.s1');
    expect(find.text(t.pendingDeleteTitle), findsOneWidget);
    expect(find.text(t.pendingDeleteLinkedMessage(1)), findsOneWidget);
    await tapKey(tester, 'confirm.cancel');
    expect(find.byKey(const Key('pending.s1')), findsOneWidget);

    await tapKey(tester, 'pending.delete.s1');
    await tapKey(tester, 'confirm.delete');
    expect(find.byKey(const Key('pending.s1')), findsNothing);
    expect(find.byKey(const Key('pending.i1')), findsNothing);
    expect(find.byKey(const Key('pending.i2')), findsOneWidget);
    expect(find.text(t.pendingFailedHint), findsNothing);
    expect(profit.pendingStore.of(testUser.id).map((i) => i.id), ['i2']);

    await tapKey(tester, 'pending.delete.i2');
    expect(find.text(t.pendingDeleteMessage), findsOneWidget);
    await tapKey(tester, 'confirm.delete');
    expect(find.byKey(const Key('pending.empty')), findsOneWidget);
  });

  testWidgets('timer without a connection: the session and its income both '
      'wait, linked', (tester) async {
    final start = DateTime(2026, 11, 10, 9, 58, 41); // testNow is 14:07
    profit.timer.entries[testUser.id] = encodeShiftTimer(
      TimerStopped(start, testNow()),
    )!;
    profit.sessions.saveError = const NetworkFailure();
    profit.sessions.listError = const NetworkFailure(); // picker cannot load
    profit.sender.error = const NetworkFailure();
    await _pumpApp(tester, overrides());

    await tapKey(tester, 'timer.save');
    await tapKey(tester, 'session.submit');
    expect(find.byType(WorkSessionFormScreen), findsNothing);
    expect(profit.timer.entries, isEmpty);

    // The income form offers the queued session although the list failed.
    expect(find.byType(IncomeFormScreen), findsOneWidget);
    expect(find.text(t.incomeForSession('09:58 – 14:07')), findsOneWidget);
    expect(find.text(t.incomeSessionLoadFailed), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('income.session')),
        matching: find.text('09:58 – 14:07'),
      ),
      findsOneWidget,
    );
    await enter(tester, 'income.amount', '650');
    await tapKey(tester, 'income.submit');

    expect(find.byType(HomeScreen), findsOneWidget);
    await scrollToBanner(tester);
    expect(find.text(t.pendingBannerWaiting(2)), findsOneWidget);
    expect(profit.income.calls, isEmpty); // its session is not on the server
    final queue = profit.pendingStore.of(testUser.id);
    expect(queue.map((i) => i.kind), [
      PendingKind.workSession,
      PendingKind.income,
    ]);
    expect(queue.last.workSessionId, queue.first.id);
    expect(queue.last.body['occurred_on'], '2026-11-10');
    expect(queue.last.body['working_hours'], isNull);
  });

  testWidgets('back in the foreground: sends what waits', (tester) async {
    seedQueue([_income('a')]);
    await _pumpApp(tester, overrides());
    expect(banner(), findsOneWidget);

    profit.sender.error = null;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(profit.sender.sent.single.id, 'a');
    expect(banner(), findsNothing);
  });

  testWidgets('TrueProfit shows the banner too', (tester) async {
    seedQueue([_income('a'), _income('b')]);
    await pumpScreen(
      tester,
      path: Routes.profit,
      screen: const TrueProfitScreen(),
      overrides: overrides(),
    );
    expect(find.text(t.pendingBannerWaiting(2)), findsOneWidget);
    await tester.tap(banner());
    await tester.pumpAndSettle();
    expect(find.text('route:${Routes.pendingRecords}'), findsOneWidget);
  });

  testWidgets(
    'logout with records waiting asks first; they stay on the phone',
    (tester) async {
      seedQueue([_income('a')]);
      await pumpScreen(
        tester,
        path: Routes.profile,
        screen: const ProfileScreen(),
        overrides: overrides(),
      );

      await scrollAndTap(tester, 'profile.logout');
      expect(find.text(t.pendingLogoutTitle), findsOneWidget);
      expect(find.text(t.pendingLogoutMessage(1)), findsOneWidget);
      await tester.tap(find.text(t.commonCancel));
      await tester.pumpAndSettle();
      expect(auth.calls, isNot(contains('logout')));

      await scrollAndTap(tester, 'profile.logout');
      await tapKey(tester, 'logout.pendingConfirm');
      expect(auth.calls, contains('logout'));
      expect(profit.pendingStore.of(testUser.id).single.id, 'a');
    },
  );

  testWidgets('logout with an empty queue asks nothing', (tester) async {
    await pumpScreen(
      tester,
      path: Routes.profile,
      screen: const ProfileScreen(),
      overrides: overrides(),
    );
    await scrollAndTap(tester, 'profile.logout');
    expect(find.text(t.pendingLogoutTitle), findsNothing);
    expect(auth.calls, contains('logout'));
  });
}
