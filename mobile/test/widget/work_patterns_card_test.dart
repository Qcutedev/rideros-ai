import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/widgets/status_views.dart';
import 'package:rideros_ai/features/profit/domain/work_patterns.dart';
import 'package:rideros_ai/features/profit/presentation/profit_providers.dart';
import 'package:rideros_ai/features/profit/presentation/true_profit_screen.dart';
import 'package:rideros_ai/features/profit/presentation/widgets/work_patterns_card.dart';

import '../helpers/fakes.dart';
import '../helpers/profit_fakes.dart';
import '../helpers/pump.dart';

void main() {
  late ProfitFakes profit;

  setUp(() => profit = ProfitFakes());

  Future<void> pumpCard(WidgetTester tester, {bool settle = true}) =>
      pumpScreen(
        tester,
        path: Routes.profit,
        screen: const Scaffold(
          body: SingleChildScrollView(child: WorkPatternsCard()),
        ),
        overrides: fakeRepositories(
          FakeAuthRepository()..restoreUser = testUser,
          FakeRiderProfileRepository(configured: true),
          profit,
        ),
        settle: settle,
      );

  final evening = patternGroup();
  final weekendDays = patternGroup(
    time: ShiftTimeOfDay.morning,
    length: ShiftLength.long,
    days: ShiftDayType.weekend,
    startMinute: 9 * 60,
    hours: '8.5',
    count: 12,
    share: 0.324,
    paid: 0,
    netPerHour: null,
  );

  testWidgets('loading skeleton, then too few sessions with progress', (
    tester,
  ) async {
    profit.profit
      ..gate = Completer<void>()
      ..patternsResult = workPatterns(sessions: 12);
    await pumpCard(tester, settle: false);
    await tester.pump();
    expect(find.byType(SkeletonBox), findsOneWidget);
    profit.profit.gate!.complete();
    await tester.pumpAndSettle();

    expect(find.text(t.patternsTitle), findsOneWidget);
    expect(find.text(t.patternsInsufficient(18)), findsOneWidget);
    expect(find.text(t.patternsProgress(12, 30, 180)), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('patterns.progress')),
    );
    expect(bar.value, closeTo(0.4, 1e-9));
  });

  testWidgets('no clear pattern says so instead of showing groups', (
    tester,
  ) async {
    profit.profit.patternsResult = workPatterns(
      status: PatternStatus.noClearPattern,
      sessions: 41,
    );
    await pumpCard(tester);
    expect(find.text(t.patternsNoClear(41, 180)), findsOneWidget);
    expect(find.byKey(const Key('patterns.group.0')), findsNothing);
  });

  testWidgets('groups: name, start, share and estimated net profit/hour', (
    tester,
  ) async {
    profit.profit.patternsResult = workPatterns(
      status: PatternStatus.ok,
      sessions: 37,
      groups: [evening, weekendDays],
    );
    await pumpCard(tester);

    final first = find.byKey(const Key('patterns.group.0'));
    final second = find.byKey(const Key('patterns.group.1'));
    String name(String time, String length, String hours, String days) =>
        t.patternsGroupName(time, length, hours, days);

    expect(
      find.descendant(
        of: first,
        matching: find.text(
          name(
            t.patternsTimeEvening,
            t.patternsLengthShort,
            '3.1',
            t.patternsDayWeekday,
          ),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: first,
        matching: find.text(t.patternsGroupDetail('18:30', 25, 68)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: first, matching: find.text('฿80.25')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: first, matching: find.text(t.badgeEstimate)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: first,
        matching: find.text(t.patternsPerHourBasis(25)),
      ),
      findsOneWidget,
    );

    // No linked income: a dash and why, never a made-up number.
    expect(
      find.descendant(
        of: second,
        matching: find.text(
          name(
            t.patternsTimeMorning,
            t.patternsLengthLong,
            '8.5',
            t.patternsDayWeekend,
          ),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: second, matching: find.text(t.profitNotAvailable)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: second,
        matching: find.text(t.patternsNoLinkedIncome),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: second, matching: find.text(t.badgeEstimate)),
      findsNothing,
    );
    expect(find.text(t.patternsNote(180)), findsOneWidget);
  });

  testWidgets('an error stays inside the card', (tester) async {
    profit.profit.patternsError = const ApiFailure(
      statusCode: 500,
      code: 'internal_error',
    );
    await pumpCard(tester);
    expect(find.byKey(const Key('patterns.error')), findsOneWidget);
    expect(find.text(t.failureServer), findsOneWidget);
  });

  testWidgets('reloads after a record change', (tester) async {
    await pumpCard(tester);
    expect(profit.profit.calls.where((c) => c == 'patterns'), hasLength(1));
    profit.profit.patternsResult = workPatterns(sessions: 29);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkPatternsCard)),
    );
    container.read(profitDataRevisionProvider.notifier).bump();
    await tester.pumpAndSettle();
    expect(profit.profit.calls.where((c) => c == 'patterns'), hasLength(2));
    expect(find.text(t.patternsInsufficient(1)), findsOneWidget);
  });

  testWidgets('the TrueProfit screen shows the card below the trend', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      path: Routes.profit,
      screen: const TrueProfitScreen(),
      overrides: fakeRepositories(
        FakeAuthRepository()..restoreUser = testUser,
        FakeRiderProfileRepository(configured: true),
        profit,
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('patterns.insufficient')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(t.patternsInsufficient(30)), findsOneWidget);
  });

  test('startTimeLabel pads hours and minutes', () {
    expect(startTimeLabel(0), '00:00');
    expect(startTimeLabel(9 * 60 + 5), '09:05');
    expect(startTimeLabel(23 * 60 + 59), '23:59');
  });
}
