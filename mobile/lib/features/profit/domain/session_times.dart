/// A time of day without a date (the form's start and end pickers).
typedef ClockTime = ({int hour, int minute});

/// Start and end of a work session entered as a start date plus two times of day, in
/// the device's time zone. An end at or before the start means the next day
/// (a shift past midnight). Equal times give `null`: the length would be ambiguous
/// (0 or 24 hours), so the form asks for a different end.
({DateTime start, DateTime end})? sessionTimes(
  DateTime date,
  ClockTime start,
  ClockTime end,
) {
  if (start == end) return null;
  final startAt = DateTime(
    date.year,
    date.month,
    date.day,
    start.hour,
    start.minute,
  );
  final crossesMidnight =
      end.hour * 60 + end.minute < start.hour * 60 + start.minute;
  final endAt = DateTime(
    date.year,
    date.month,
    date.day + (crossesMidnight ? 1 : 0),
    end.hour,
    end.minute,
  );
  return (start: startAt, end: endAt);
}
