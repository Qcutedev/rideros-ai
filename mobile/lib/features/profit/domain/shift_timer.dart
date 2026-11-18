import 'profit_records.dart';

/// The Home "start work" timer. It lives on this device only: the backend sees
/// nothing until the rider saves the work session form that the timer fills in.
sealed class ShiftTimerState {
  const ShiftTimerState();
}

/// No timer: the Home card offers "start work".
final class TimerIdle extends ShiftTimerState {
  const TimerIdle();

  @override
  bool operator ==(Object other) => other is TimerIdle;

  @override
  int get hashCode => 0;
}

/// Counting since [startedAt].
final class TimerRunning extends ShiftTimerState {
  const TimerRunning(this.startedAt);

  final DateTime startedAt;

  Duration elapsed(DateTime now) => _nonNegative(now.difference(startedAt));

  /// Same moment, whether read back from storage in UTC or made in local time.
  @override
  bool operator ==(Object other) =>
      other is TimerRunning && other.startedAt.isAtSameMomentAs(startedAt);

  @override
  int get hashCode => startedAt.microsecondsSinceEpoch.hashCode;
}

/// Stopped but not saved yet: the rider can save it, carry on or throw it away.
final class TimerStopped extends ShiftTimerState {
  const TimerStopped(this.startedAt, this.stoppedAt);

  final DateTime startedAt;
  final DateTime stoppedAt;

  Duration get elapsed => _nonNegative(stoppedAt.difference(startedAt));

  SessionDraft get draft => SessionDraft(start: startedAt, end: stoppedAt);

  @override
  bool operator ==(Object other) =>
      other is TimerStopped &&
      other.startedAt.isAtSameMomentAs(startedAt) &&
      other.stoppedAt.isAtSameMomentAs(stoppedAt);

  @override
  int get hashCode => Object.hash(
    startedAt.microsecondsSinceEpoch,
    stoppedAt.microsecondsSinceEpoch,
  );
}

/// A device clock moved backwards must not show a negative time.
Duration _nonNegative(Duration d) => d.isNegative ? Duration.zero : d;

/// Start and end handed to the work session form. The form works in whole
/// minutes, so both are cut to the minute (a session of at least one minute
/// keeps two different times).
class SessionDraft {
  SessionDraft({required DateTime start, required DateTime end})
    : start = _toMinute(start.toLocal()),
      end = _toMinute(end.toLocal()),
      length = _nonNegative(end.difference(start));

  final DateTime start;
  final DateTime end;

  /// The exact timed length (before cutting to minutes).
  final Duration length;

  /// Shorter than the form can store (start and end in the same minute).
  bool get tooShort => length < const Duration(minutes: 1);

  /// Longer than one work session may be: probably the rider forgot to stop.
  bool get tooLong => length > ProfitLimits.maxSession;

  static DateTime _toMinute(DateTime t) =>
      DateTime(t.year, t.month, t.day, t.hour, t.minute);
}
