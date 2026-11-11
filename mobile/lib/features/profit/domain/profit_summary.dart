import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/date_json.dart';
import '../../../core/utils/decimal_json.dart';

part 'profit_summary.freezed.dart';
part 'profit_summary.g.dart';

/// `period` of `GET /profit/summary` and `granularity` of `GET /profit/trends`.
/// Weeks run Monday–Sunday in the rider's time zone.
enum ProfitPeriod { day, week, month }

/// Actual figures from the rider's own records (never shift-scenario estimates).
@freezed
abstract class ProfitMetrics with _$ProfitMetrics {
  const ProfitMetrics._();

  const factory ProfitMetrics({
    @DecimalConverter() required Decimal totalRevenue,
    @DecimalConverter() required Decimal totalExpenses,
    @DecimalConverter() required Decimal netProfit,
    @DecimalConverter() required Decimal workingHours,

    /// `null` when [workingHours] is 0 ([reason] says why).
    @NullableDecimalConverter() Decimal? revenuePerHour,
    @NullableDecimalConverter() Decimal? netProfitPerHour,
    String? reason,
    required int incomeCount,
    required int expenseCount,
    required int workSessionCount,
  }) = _ProfitMetrics;

  factory ProfitMetrics.fromJson(Map<String, dynamic> json) =>
      _$ProfitMetricsFromJson(json);

  /// Nothing was recorded in the period.
  bool get isEmpty =>
      incomeCount == 0 && expenseCount == 0 && workSessionCount == 0;
}

/// `GET /profit/summary`: one day, ISO week or calendar month.
class ProfitSummary {
  const ProfitSummary({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.timezone,
    required this.currency,
    required this.metrics,
  });

  factory ProfitSummary.fromJson(Map<String, dynamic> json) => ProfitSummary(
    period: ProfitPeriod.values.byName(json['period'] as String),
    startDate: parseIsoDate(json['start_date'] as String),
    endDate: parseIsoDate(json['end_date'] as String),
    timezone: json['timezone'] as String,
    currency: json['currency'] as String,
    metrics: ProfitMetrics.fromJson(json),
  );

  final ProfitPeriod period;
  final DateTime startDate;

  /// Inclusive.
  final DateTime endDate;
  final String timezone;
  final String currency;
  final ProfitMetrics metrics;
}

class TrendPoint {
  const TrendPoint({
    required this.startDate,
    required this.endDate,
    required this.metrics,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
    startDate: parseIsoDate(json['start_date'] as String),
    endDate: parseIsoDate(json['end_date'] as String),
    metrics: ProfitMetrics.fromJson(json),
  );

  final DateTime startDate;
  final DateTime endDate;
  final ProfitMetrics metrics;
}

/// `GET /profit/trends`: one point per bucket, empty buckets included.
class ProfitTrends {
  const ProfitTrends({
    required this.granularity,
    required this.currency,
    required this.points,
  });

  factory ProfitTrends.fromJson(Map<String, dynamic> json) => ProfitTrends(
    granularity: ProfitPeriod.values.byName(json['granularity'] as String),
    currency: json['currency'] as String,
    points: [
      for (final point in json['points'] as List<dynamic>)
        TrendPoint.fromJson(point as Map<String, dynamic>),
    ],
  );

  final ProfitPeriod granularity;
  final String currency;
  final List<TrendPoint> points;

  bool get isEmpty => points.every((p) => p.metrics.isEmpty);
}
