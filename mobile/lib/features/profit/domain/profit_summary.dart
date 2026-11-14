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
    this.movingAverage,
    this.trend,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
    startDate: parseIsoDate(json['start_date'] as String),
    endDate: parseIsoDate(json['end_date'] as String),
    metrics: ProfitMetrics.fromJson(json),
    movingAverage: const NullableDecimalConverter().fromJson(
      json['net_profit_moving_average'],
    ),
    trend: const NullableDecimalConverter().fromJson(json['net_profit_trend']),
  );

  final DateTime startDate;
  final DateTime endDate;
  final ProfitMetrics metrics;

  /// Trailing mean of net profit over [TrendAnalysis.window] buckets; `null` where it is not defined.
  final Decimal? movingAverage;

  /// Value of the fitted linear trend; `null` unless the trend is [TrendDirection.up] or `down`.
  final Decimal? trend;
}

enum TrendStatus { ok, insufficientData }

enum TrendDirection { up, down, flat }

/// `analysis` of `GET /profit/trends`: moving average + linear trend of net profit from the
/// rider's own records. The direction is only up/down when the slope is significant (p < 0.05).
class TrendAnalysis {
  const TrendAnalysis({
    required this.status,
    required this.window,
    required this.activeBuckets,
    required this.minActiveBuckets,
    this.direction,
    this.slopePerBucket,
  });

  factory TrendAnalysis.fromJson(Map<String, dynamic> json) => TrendAnalysis(
    status: json['status'] == 'ok'
        ? TrendStatus.ok
        : TrendStatus.insufficientData,
    window: json['moving_average_window'] as int,
    activeBuckets: json['active_buckets'] as int,
    minActiveBuckets: json['min_active_buckets'] as int,
    direction: switch (json['direction']) {
      final String name => TrendDirection.values.byName(name),
      _ => null,
    },
    slopePerBucket: const NullableDecimalConverter().fromJson(
      json['slope_per_bucket'],
    ),
  );

  final TrendStatus status;
  final int window;
  final int activeBuckets;
  final int minActiveBuckets;
  final TrendDirection? direction;
  final Decimal? slopePerBucket;
}

/// `GET /profit/trends`: one point per bucket, empty buckets included.
class ProfitTrends {
  const ProfitTrends({
    required this.granularity,
    required this.currency,
    required this.points,
    this.analysis,
  });

  factory ProfitTrends.fromJson(Map<String, dynamic> json) => ProfitTrends(
    granularity: ProfitPeriod.values.byName(json['granularity'] as String),
    currency: json['currency'] as String,
    points: [
      for (final point in json['points'] as List<dynamic>)
        TrendPoint.fromJson(point as Map<String, dynamic>),
    ],
    analysis: switch (json['analysis']) {
      final Map<String, dynamic> analysis => TrendAnalysis.fromJson(analysis),
      _ => null,
    },
  );

  final ProfitPeriod granularity;
  final String currency;
  final List<TrendPoint> points;

  /// `null` from a server older than the trend analysis.
  final TrendAnalysis? analysis;

  bool get isEmpty => points.every((p) => p.metrics.isEmpty);
}
