import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/clock.dart';
import '../../auth/domain/session_state.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/shift_timer_store.dart';
import '../domain/shift_timer.dart';

/// The signed-in rider's Home timer, read from and saved to this device.
final shiftTimerProvider =
    AsyncNotifierProvider<ShiftTimerController, ShiftTimerState>(
      ShiftTimerController.new,
    );

class ShiftTimerController extends AsyncNotifier<ShiftTimerState> {
  @override
  Future<ShiftTimerState> build() async {
    final userId = ref.watch(_userIdProvider);
    if (userId == null) return const TimerIdle();
    try {
      return await ref.read(shiftTimerStoreProvider).read(userId);
    } on Object {
      // The timer is a convenience: an unreadable store means "no timer".
      return const TimerIdle();
    }
  }

  DateTime _now() => ref.read(clockProvider)();

  Future<void> start() async {
    if (state.value is TimerIdle) await _set(TimerRunning(_now()));
  }

  /// Stops a running timer and returns the stopped state (`null` if none ran).
  Future<TimerStopped?> stop() async {
    final current = state.value;
    if (current is! TimerRunning) return null;
    final stopped = TimerStopped(current.startedAt, _now());
    await _set(stopped);
    return stopped;
  }

  /// Carries on counting from the original start (a stop by mistake).
  Future<void> resume() async {
    final current = state.value;
    if (current is TimerStopped) await _set(TimerRunning(current.startedAt));
  }

  /// Throws the timer away, or clears it after its work session was saved.
  Future<void> reset() => _set(const TimerIdle());

  Future<void> _set(ShiftTimerState next) async {
    state = AsyncData(next);
    final userId = ref.read(_userIdProvider);
    if (userId == null) return;
    try {
      await ref.read(shiftTimerStoreProvider).write(userId, next);
    } on Object {
      // Kept in memory; only a restart would lose it.
    }
  }
}

final _userIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionControllerProvider);
  return session is SignedIn ? session.user.id : null;
});
