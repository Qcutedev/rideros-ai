import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/date_json.dart';
import '../../../core/utils/decimal_json.dart';

part 'pickup_models.freezed.dart';
part 'pickup_models.g.dart';

/// Limits of `backend/app/modules/pickup` (models + service).
abstract final class PickupLimits {
  static const restaurantNameMaxLength = 120;
  static const searchMaxLength = 120;
  static const notesMaxLength = 300;

  /// `pickup_wait_too_long` above this.
  static const maxWait = Duration(hours: 3);
}

/// How many dataset orders back a restaurant's statistics: sufficient >= 30,
/// limited 5-29, insufficient <= 4.
@JsonEnum(fieldRename: FieldRename.snake)
enum DataAvailability { sufficient, limited, insufficient }

/// `GET /pickup/restaurants?source=`.
enum RestaurantSourceFilter {
  all(null),
  dataset('dataset'),
  own('user');

  const RestaurantSourceFilter(this.query);

  /// Query value; `null` = no filter.
  final String? query;
}

@freezed
abstract class Coordinates with _$Coordinates {
  const factory Coordinates({required double lat, required double lng}) =
      _Coordinates;

  factory Coordinates.fromJson(Map<String, dynamic> json) =>
      _$CoordinatesFromJson(json);
}

/// A dataset restaurant (shared, `POI-<id>`, from Meituan data of a Chinese city)
/// or one the rider created for the Pickup Log.
@freezed
abstract class Restaurant with _$Restaurant {
  const factory Restaurant({
    required String id,
    required String source,
    required String name,
    required bool isOwn,

    /// Only dataset restaurants are known to the model.
    required bool supportsPrediction,
    DataAvailability? dataAvailability,
    int? nOrders,

    /// Only for the rider's own restaurants.
    Coordinates? location,
    required DateTime createdAt,
  }) = _Restaurant;

  factory Restaurant.fromJson(Map<String, dynamic> json) =>
      _$RestaurantFromJson(json);
}

/// `POST /pickup/restaurants`.
@Freezed(fromJson: false, toJson: true)
abstract class RestaurantInput with _$RestaurantInput {
  const factory RestaurantInput({required String name, Coordinates? location}) =
      _RestaurantInput;
}

/// Order-to-Pickup minutes of one hour (or of all orders) in the dataset.
@freezed
abstract class StatCell with _$StatCell {
  const factory StatCell({
    required int hour,
    required int nOrders,
    @NullableDecimalConverter() Decimal? medianMin,
    @NullableDecimalConverter() Decimal? p25Min,
    @NullableDecimalConverter() Decimal? p75Min,
    @NullableDecimalConverter() Decimal? p90Min,
  }) = _StatCell;

  factory StatCell.fromJson(Map<String, dynamic> json) =>
      _$StatCellFromJson(json);
}

@freezed
abstract class OverallStats with _$OverallStats {
  const factory OverallStats({
    required int nOrders,
    @NullableDecimalConverter() Decimal? medianMin,
    @NullableDecimalConverter() Decimal? p25Min,
    @NullableDecimalConverter() Decimal? p75Min,
    @NullableDecimalConverter() Decimal? p90Min,
    int? peakHour,
  }) = _OverallStats;

  factory OverallStats.fromJson(Map<String, dynamic> json) =>
      _$OverallStatsFromJson(json);
}

/// `GET /pickup/restaurants/{id}/analytics`. [byHour] holds 24 cells (hour 0-23)
/// for `weekday` and `weekend`; hours without orders have `nOrders == 0`.
@freezed
abstract class RestaurantAnalytics with _$RestaurantAnalytics {
  const factory RestaurantAnalytics({
    required Restaurant restaurant,
    required DataAvailability dataAvailability,

    /// `null` for the rider's own restaurants.
    OverallStats? overall,
    @Default({}) Map<String, List<StatCell>> byHour,
    @Default(30) int minOrdersForStats,
    String? datasetVersion,
    String? acknowledgement,
  }) = _RestaurantAnalytics;

  factory RestaurantAnalytics.fromJson(Map<String, dynamic> json) =>
      _$RestaurantAnalyticsFromJson(json);
}

/// insufficient: n < 5 (no figures), low: 5 <= n < 20, ok: n >= 20.
@JsonEnum(fieldRename: FieldRename.snake)
enum WaitConfidence { insufficient, low, ok }

/// The rider's own logged waits (picked up - arrived) at one restaurant.
@freezed
abstract class WaitStats with _$WaitStats {
  const factory WaitStats({
    required String restaurantId,
    required int n,
    @NullableDecimalConverter() Decimal? medianMinutes,
    @NullableDecimalConverter() Decimal? p80Minutes,
    required WaitConfidence confidence,
  }) = _WaitStats;

  factory WaitStats.fromJson(Map<String, dynamic> json) =>
      _$WaitStatsFromJson(json);

  /// Logs needed before the server shows figures.
  static const minLogs = 5;
}

@freezed
abstract class PredictionInterval with _$PredictionInterval {
  const factory PredictionInterval({
    @DecimalConverter() required Decimal low,
    @DecimalConverter() required Decimal high,

    /// `null` in history rows of a version that is no longer loaded.
    double? nominalCoverage,
  }) = _PredictionInterval;

  factory PredictionInterval.fromJson(Map<String, dynamic> json) =>
      _$PredictionIntervalFromJson(json);
}

/// Warning codes of a prediction.
abstract final class PredictionWarning {
  static const foreignDataset = 'foreign_dataset';
  static const limitedRestaurantData = 'limited_restaurant_data';
  static const insufficientRestaurantData = 'insufficient_restaurant_data';
}

/// `POST /pickup/predictions` and the history rows. Show [interval], not
/// [predictedMinutes] alone.
@freezed
abstract class Prediction with _$Prediction {
  const factory Prediction({
    required String id,
    String? restaurantId,
    String? restaurantName,
    @DecimalConverter() required Decimal predictedMinutes,
    required PredictionInterval interval,
    required DataAvailability dataAvailability,
    @Default([]) List<String> warnings,
    required String modelVersion,
    @AwareDateTimeConverter() required DateTime requestedAt,
    required String disclaimer,
    required DateTime createdAt,
  }) = _Prediction;

  factory Prediction.fromJson(Map<String, dynamic> json) =>
      _$PredictionFromJson(json);
}

/// `GET /pickup/model`: the model card. Metric maps are kept as the server sends
/// them; the screen reads the few keys it shows.
@freezed
abstract class ModelInfo with _$ModelInfo {
  const ModelInfo._();

  const factory ModelInfo({
    required String name,
    required String version,
    required String dataset,
    required String domain,
    DateTime? trainedAt,
    @Default({}) Map<String, dynamic> testMetrics,
    Map<String, dynamic>? baselineTestMetrics,
    @Default({}) Map<String, dynamic> interval,
    @Default([]) List<String> limitations,
    required String acknowledgement,
  }) = _ModelInfo;

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);

  double? get testMae => _number(testMetrics['mae']);
  double? get baselineMae => _number(baselineTestMetrics?['mae']);
  int? get testOrders => _number(testMetrics['n'])?.toInt();
  String? get algorithm => testMetrics['model'] as String?;
  double? get nominalCoverage => _number(interval['nominal_coverage']);
  double? get testCoverage => _number(interval['test_coverage']);
  double? get meanWidthMinutes => _number(interval['test_mean_width_minutes']);

  static double? _number(Object? value) =>
      value is num ? value.toDouble() : null;
}

/// A real pickup the rider logged.
@freezed
abstract class PickupLog with _$PickupLog {
  const factory PickupLog({
    required String id,
    required String restaurantId,
    required String restaurantName,
    @AwareDateTimeConverter() required DateTime arrivedAt,
    @AwareDateTimeConverter() required DateTime pickedUpAt,
    @DecimalConverter() required Decimal waitMinutes,
    String? notes,
    required DateTime createdAt,
  }) = _PickupLog;

  factory PickupLog.fromJson(Map<String, dynamic> json) =>
      _$PickupLogFromJson(json);
}

/// `POST /pickup/logs`. Times carry the device's UTC offset.
@Freezed(fromJson: false, toJson: true)
abstract class PickupLogInput with _$PickupLogInput {
  const factory PickupLogInput({
    required String restaurantId,
    @AwareDateTimeConverter() required DateTime arrivedAt,
    @AwareDateTimeConverter() required DateTime pickedUpAt,
    String? notes,
  }) = _PickupLogInput;
}
