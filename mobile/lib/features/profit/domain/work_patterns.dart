import 'package:decimal/decimal.dart';

import '../../../core/utils/date_json.dart';

/// `status` of `GET /profit/patterns`.
enum PatternStatus {
  ok,

  /// Fewer than [WorkPatterns.minSessions] sessions in the window.
  insufficientData,

  /// Enough sessions, but no grouping beat chance (silhouette, shuffle test,
  /// bootstrap stability). Shown as "no clear pattern yet", never as groups.
  noClearPattern;

  static PatternStatus fromJson(String value) => switch (value) {
    'ok' => ok,
    'insufficient_data' => insufficientData,
    'no_clear_pattern' => noClearPattern,
    _ => throw FormatException('Unknown pattern status: $value'),
  };
}

/// Mean local start: morning 05–11, midday 11–15, evening 15–20, night 20–05.
enum ShiftTimeOfDay { morning, midday, evening, night }

/// Mean length: short < 4 h, medium < 8 h, long ≥ 8 h.
enum ShiftLength { short, medium, long }

/// weekend ≥ 70% of sessions on Sat/Sun, weekday ≤ 30%, otherwise mixed.
enum ShiftDayType { weekday, weekend, mixed }

/// One group of similar work sessions (K-Means on the server).
class PatternGroup {
  const PatternGroup({
    required this.timeOfDay,
    required this.length,
    required this.dayType,
    required this.meanStartMinute,
    required this.meanHours,
    required this.sessionCount,
    required this.share,
    required this.profitSessionCount,
    this.revenuePerHour,
    this.netProfitPerHour,
  });

  factory PatternGroup.fromJson(Map<String, dynamic> json) => PatternGroup(
    timeOfDay: ShiftTimeOfDay.values.byName(json['time_of_day'] as String),
    length: ShiftLength.values.byName(json['length'] as String),
    dayType: ShiftDayType.values.byName(json['day_type'] as String),
    meanStartMinute: json['mean_start_minute'] as int,
    meanHours: Decimal.parse(json['mean_hours'] as String),
    sessionCount: json['session_count'] as int,
    share: (json['share'] as num).toDouble(),
    profitSessionCount: json['profit_session_count'] as int,
    revenuePerHour: _decimalOrNull(json['revenue_per_hour']),
    netProfitPerHour: _decimalOrNull(json['net_profit_per_hour']),
  );

  final ShiftTimeOfDay timeOfDay;
  final ShiftLength length;
  final ShiftDayType dayType;

  /// Local time of day, 0–1439 (circular mean, so 23:00 and 01:00 give 00:00).
  final int meanStartMinute;
  final Decimal meanHours;
  final int sessionCount;

  /// Of all sessions in the window, 0–1.
  final double share;

  /// Sessions with linked income: the per-hour figures are estimated from these.
  final int profitSessionCount;
  final Decimal? revenuePerHour;
  final Decimal? netProfitPerHour;
}

/// `GET /profit/patterns`: groups of the rider's sessions in the last 180 days.
class WorkPatterns {
  const WorkPatterns({
    required this.status,
    required this.windowDays,
    required this.startDate,
    required this.endDate,
    required this.sessionCount,
    required this.minSessions,
    required this.groups,
    required this.currency,
  });

  factory WorkPatterns.fromJson(Map<String, dynamic> json) => WorkPatterns(
    status: PatternStatus.fromJson(json['status'] as String),
    windowDays: json['window_days'] as int,
    startDate: parseIsoDate(json['start_date'] as String),
    endDate: parseIsoDate(json['end_date'] as String),
    sessionCount: json['session_count'] as int,
    minSessions: json['min_sessions'] as int,
    groups: [
      for (final group in json['groups'] as List<dynamic>)
        PatternGroup.fromJson(group as Map<String, dynamic>),
    ],
    currency: json['currency'] as String,
  );

  final PatternStatus status;
  final int windowDays;
  final DateTime startDate;
  final DateTime endDate;
  final int sessionCount;
  final int minSessions;

  /// Largest first; empty unless [status] is [PatternStatus.ok].
  final List<PatternGroup> groups;
  final String currency;

  /// Sessions still to record before patterns are computed (0 when enough).
  int get sessionsMissing =>
      sessionCount >= minSessions ? 0 : minSessions - sessionCount;
}

Decimal? _decimalOrNull(Object? value) =>
    value == null ? null : Decimal.parse(value as String);
