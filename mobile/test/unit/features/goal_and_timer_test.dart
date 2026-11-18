import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/utils/clock.dart';
import 'package:rideros_ai/features/auth/data/auth_repository_impl.dart';
import 'package:rideros_ai/features/auth/domain/session_state.dart';
import 'package:rideros_ai/features/auth/presentation/session_controller.dart';
import 'package:rideros_ai/features/dashboard/domain/daily_goal.dart';
import 'package:rideros_ai/features/dashboard/presentation/widgets/shift_timer_card.dart';
import 'package:rideros_ai/features/profile/data/rider_profile_repository_impl.dart';
import 'package:rideros_ai/features/profit/data/shift_timer_store.dart';
import 'package:rideros_ai/features/profit/domain/shift_timer.dart';
import 'package:rideros_ai/features/profit/presentation/shift_timer_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/profit_fakes.dart';

GoalProgress _goal(String net, String goal) =>
    GoalProgress(net: Decimal.parse(net), goal: Decimal.parse(goal));

void main() {
  group('GoalProgress', () {
    test('below the goal: what is left, ring part filled', () {
      final p = _goal('442.28', '600');
      expect(p.reached, isFalse);
      expect(p.remaining, Decimal.parse('157.72'));
      expect(p.surplus, Decimal.zero);
      expect(p.percent, 73);
      expect(p.fraction, closeTo(0.737, 0.001));
    });

    test('exactly the goal counts as reached', () {
      final p = _goal('600.00', '600');
      expect(p.reached, isTrue);
      expect(p.remaining, Decimal.zero);
      expect(p.surplus, Decimal.zero);
      expect(p.percent, 100);
      expect(p.fraction, 1);
    });

    test('above the goal: the surplus, ring full', () {
      final p = _goal('642.28', '600');
      expect(p.reached, isTrue);
      expect(p.surplus, Decimal.parse('42.28'));
      expect(p.fraction, 1);
    });

    test('a loss or nothing yet shows an empty ring', () {
      expect(_goal('-80.00', '600').fraction, 0);
      expect(_goal('-80.00', '600').percent, 0);
      expect(_goal('-80.00', '600').remaining, Decimal.parse('680'));
      expect(_goal('0', '600').percent, 0);
    });

    test('percent is exact decimals, rounded down', () {
      // 0.29 * 100 is 28.999… as a double.
      expect(_goal('29', '100').percent, 29);
      expect(_goal('599.99', '600').percent, 99);
    });
  });

  group('SessionDraft', () {
    final start = DateTime(2026, 11, 10, 9, 58, 41);

    test('cut to whole minutes, exact length kept', () {
      final draft = SessionDraft(
        start: start,
        end: start.add(const Duration(hours: 4, minutes: 3, seconds: 30)),
      );
      expect(draft.start, DateTime(2026, 11, 10, 9, 58));
      expect(draft.end, DateTime(2026, 11, 10, 14, 2));
      expect(draft.length, const Duration(hours: 4, minutes: 3, seconds: 30));
      expect(draft.tooShort, isFalse);
      expect(draft.tooLong, isFalse);
    });

    test('under a minute is too short; one minute is not', () {
      expect(
        SessionDraft(
          start: start,
          end: start.add(const Duration(seconds: 59)),
        ).tooShort,
        isTrue,
      );
      final minute = SessionDraft(
        start: start,
        end: start.add(const Duration(minutes: 1)),
      );
      expect(minute.tooShort, isFalse);
      expect(minute.end.difference(minute.start), const Duration(minutes: 1));
    });

    test('over 24 hours is too long; exactly 24 hours is not', () {
      expect(
        SessionDraft(
          start: start,
          end: start.add(const Duration(hours: 24)),
        ).tooLong,
        isFalse,
      );
      expect(
        SessionDraft(
          start: start,
          end: start.add(const Duration(hours: 24, seconds: 1)),
        ).tooLong,
        isTrue,
      );
    });

    test('UTC times are shown in device time', () {
      final utc = DateTime.utc(2026, 11, 10, 3, 0);
      final draft = SessionDraft(
        start: utc,
        end: utc.add(const Duration(hours: 1)),
      );
      expect(draft.start.isUtc, isFalse);
      expect(draft.start, utc.toLocal());
    });
  });

  group('timer states', () {
    test('a clock moved backwards never shows a negative time', () {
      final start = DateTime(2026, 11, 10, 12);
      expect(
        TimerRunning(start).elapsed(start.subtract(const Duration(hours: 1))),
        Duration.zero,
      );
      expect(
        TimerStopped(start, start.subtract(const Duration(minutes: 5))).elapsed,
        Duration.zero,
      );
    });

    test('stored text round-trips; anything unreadable is idle', () {
      final start = DateTime.utc(2026, 11, 10, 3, 4, 5);
      final stop = start.add(const Duration(hours: 2));
      for (final state in [
        const TimerIdle(),
        TimerRunning(start),
        TimerStopped(start, stop),
      ]) {
        expect(decodeShiftTimer(encodeShiftTimer(state)), state);
      }
      expect(encodeShiftTimer(const TimerIdle()), isNull);
      expect(decodeShiftTimer('garbage'), const TimerIdle());
      expect(decodeShiftTimer('not-a-date|'), const TimerIdle());
      expect(decodeShiftTimer('a|b|c'), const TimerIdle());
      expect(
        decodeShiftTimer('${start.toIso8601String()}|bad'),
        TimerRunning(start),
      );
    });

    test('clock label pads and keeps counting past a day', () {
      expect(clockLabel(Duration.zero), '00:00:00');
      expect(
        clockLabel(const Duration(hours: 4, minutes: 5, seconds: 9)),
        '04:05:09',
      );
      expect(clockLabel(const Duration(hours: 26)), '26:00:00');
    });
  });

  group('ShiftTimerController', () {
    late MemoryShiftTimerStore store;
    late DateTime now;

    Future<ProviderContainer> signedIn({String? user}) async {
      final auth = FakeAuthRepository()
        ..restoreUser = user == null ? testUser : testUser.copyWith(id: user);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          riderProfileRepositoryProvider.overrideWithValue(
            FakeRiderProfileRepository(configured: true),
          ),
          shiftTimerStoreProvider.overrideWithValue(store),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      container.listen(sessionControllerProvider, (_, _) {});
      container.listen(shiftTimerProvider, (_, _) {});
      // Session restore, then the timer read.
      while (container.read(sessionControllerProvider) is! SignedIn) {
        await Future<void>.delayed(Duration.zero);
      }
      await container.read(shiftTimerProvider.future);
      return container;
    }

    setUp(() {
      store = MemoryShiftTimerStore();
      now = DateTime(2026, 11, 10, 10);
    });

    test('start, stop, resume, reset; each step is stored', () async {
      final c = await signedIn();
      final timer = c.read(shiftTimerProvider.notifier);
      expect(c.read(shiftTimerProvider).value, const TimerIdle());

      await timer.start();
      expect(c.read(shiftTimerProvider).value, TimerRunning(now));
      expect(store.entries[testUser.id], isNotNull);

      final started = now;
      now = now.add(const Duration(hours: 3));
      final stopped = await timer.stop();
      expect(stopped, TimerStopped(started, now));
      expect(c.read(shiftTimerProvider).value, stopped);

      await timer.resume();
      expect(c.read(shiftTimerProvider).value, TimerRunning(started));

      await timer.reset();
      expect(c.read(shiftTimerProvider).value, const TimerIdle());
      expect(store.entries, isEmpty);
    });

    test(
      'start is ignored while running; stop needs a running timer',
      () async {
        final c = await signedIn();
        final timer = c.read(shiftTimerProvider.notifier);
        expect(await timer.stop(), isNull);
        await timer.start();
        final first = c.read(shiftTimerProvider).value;
        now = now.add(const Duration(minutes: 5));
        await timer.start();
        expect(c.read(shiftTimerProvider).value, first);
      },
    );

    test('a stored timer comes back after a restart', () async {
      store.entries[testUser.id] = encodeShiftTimer(
        TimerRunning(DateTime.utc(2026, 11, 10, 1)),
      )!;
      final c = await signedIn();
      expect(
        c.read(shiftTimerProvider).value,
        TimerRunning(DateTime.utc(2026, 11, 10, 1)),
      );
    });

    test('another account on the phone does not see the timer', () async {
      store.entries['someone-else'] = encodeShiftTimer(
        TimerRunning(DateTime.utc(2026, 11, 10, 1)),
      )!;
      final c = await signedIn();
      expect(c.read(shiftTimerProvider).value, const TimerIdle());
    });

    test('store failures: read gives idle, write keeps it in memory', () async {
      store.readError = Exception('disk');
      final c = await signedIn();
      expect(c.read(shiftTimerProvider).value, const TimerIdle());

      store.writeError = Exception('disk');
      await c.read(shiftTimerProvider.notifier).start();
      expect(c.read(shiftTimerProvider).value, TimerRunning(now));
    });
  });
}
