import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/shift_timer.dart';

/// Keeps the Home timer across app restarts, one entry per account so a second
/// rider on the same phone never sees someone else's timer.
abstract interface class ShiftTimerStore {
  Future<ShiftTimerState> read(String userId);
  Future<void> write(String userId, ShiftTimerState state);
}

final shiftTimerStoreProvider = Provider<ShiftTimerStore>(
  (ref) => SharedPreferencesShiftTimerStore(SharedPreferencesAsync()),
);

/// Stored as `"<start>|<stop>"` (UTC ISO-8601, stop empty while running).
class SharedPreferencesShiftTimerStore implements ShiftTimerStore {
  SharedPreferencesShiftTimerStore(this._prefs);

  final SharedPreferencesAsync _prefs;

  static String _key(String userId) => 'shift_timer.$userId';

  @override
  Future<ShiftTimerState> read(String userId) async =>
      decodeShiftTimer(await _prefs.getString(_key(userId)));

  @override
  Future<void> write(String userId, ShiftTimerState state) {
    final value = encodeShiftTimer(state);
    return value == null
        ? _prefs.remove(_key(userId))
        : _prefs.setString(_key(userId), value);
  }
}

String? encodeShiftTimer(ShiftTimerState state) => switch (state) {
  TimerIdle() => null,
  TimerRunning(:final startedAt) => '${_iso(startedAt)}|',
  TimerStopped(:final startedAt, :final stoppedAt) =>
    '${_iso(startedAt)}|${_iso(stoppedAt)}',
};

/// Anything unreadable counts as "no timer" rather than an error on Home.
ShiftTimerState decodeShiftTimer(String? value) {
  if (value == null) return const TimerIdle();
  final parts = value.split('|');
  if (parts.length != 2) return const TimerIdle();
  final start = DateTime.tryParse(parts[0]);
  if (start == null) return const TimerIdle();
  if (parts[1].isEmpty) return TimerRunning(start);
  final stop = DateTime.tryParse(parts[1]);
  return stop == null ? TimerRunning(start) : TimerStopped(start, stop);
}

String _iso(DateTime t) => t.toUtc().toIso8601String();
