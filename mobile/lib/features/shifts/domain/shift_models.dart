import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/date_json.dart';
import '../../../core/utils/decimal_json.dart';

part 'shift_models.freezed.dart';
part 'shift_models.g.dart';

/// Limits of `backend/app/modules/shifts` (schemas + estimator).
abstract final class ShiftLimits {
  static const nameMaxLength = 60;
  static const minDurationMinutes = 30;
  static const maxDurationMinutes = 960;

  /// `historical` looks back this many days and needs [minHistoryDays] of them
  /// with working hours.
  static const historyDays = 84;
  static const minHistoryDays = 5;

  /// `POST /shift-scenarios/compare` takes 2-5 ids.
  static const minCompare = 2;
  static const maxCompare = 5;

  // NUMERIC(maxDigits, places) of each assumption, plus the API's own bound.
  static final ordersPerHour = (
    maxDigits: 5,
    places: 2,
    max: Decimal.fromInt(30),
  );
  static final incomePerOrder = (
    maxDigits: 8,
    places: 2,
    max: Decimal.fromInt(10000),
  );
  static final kmPerOrder = (
    maxDigits: 6,
    places: 2,
    max: Decimal.fromInt(100),
  );
  static final fuelKmPerLiter = (
    maxDigits: 6,
    places: 2,
    max: Decimal.fromInt(1000),
  );
  static final fuelPricePerLiter = (
    maxDigits: 8,
    places: 2,
    max: Decimal.fromInt(1000),
  );
  static final depreciationPerKm = (
    maxDigits: 8,
    places: 4,
    max: Decimal.fromInt(1000),
  );
  static final otherCosts = (
    maxDigits: 10,
    places: 2,
    max: Decimal.fromInt(100000),
  );
}

/// `estimation_method`. [ml] is reserved by the API (400
/// `estimation_method_unavailable`); the app never offers it.
@JsonEnum(fieldRename: FieldRename.snake)
enum EstimationMethod { assumption, historical, ml }

/// A local wall-clock time without a zone (`17:00`, sent as `HH:MM`).
@immutable
class ClockTime {
  const ClockTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// Reads `HH:MM` or `HH:MM:SS`.
  factory ClockTime.parse(String value) {
    final parts = value.split(':');
    if (parts.length < 2) throw FormatException('Not a time: $value');
    return ClockTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  /// `17:05`
  String format() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => format();
}

class ClockTimeConverter implements JsonConverter<ClockTime, String> {
  const ClockTimeConverter();

  @override
  ClockTime fromJson(String json) => ClockTime.parse(json);

  @override
  String toJson(ClockTime value) => value.format();
}

/// Minutes from [start] to [end]; an end at or before the start is the next day,
/// like the API (equal times = 0, which is too short).
int shiftMinutes(ClockTime start, ClockTime end) =>
    (end.minutesOfDay - start.minutesOfDay) % 1440;

/// Whether the API accepts the length (30 minutes to 16 hours).
bool isValidShiftLength(int minutes) =>
    minutes >= ShiftLimits.minDurationMinutes &&
    minutes <= ShiftLimits.maxDurationMinutes;

/// Rider inputs. `assumption` needs [ordersPerHour] and [incomePerOrder]; empty
/// fuel and depreciation values fall back to the rider profile on the server.
@freezed
abstract class ShiftAssumptions with _$ShiftAssumptions {
  @JsonSerializable(includeIfNull: false)
  const factory ShiftAssumptions({
    @NullableDecimalConverter() Decimal? ordersPerHour,
    @NullableDecimalConverter() Decimal? incomePerOrder,
    @NullableDecimalConverter() Decimal? kmPerOrder,
    @NullableDecimalConverter() Decimal? fuelKmPerLiter,
    @NullableDecimalConverter() Decimal? fuelPricePerLiter,
    @NullableDecimalConverter() Decimal? depreciationPerKm,

    /// Fixed costs of the shift (parking, food, ...). Both methods use it.
    @NullableDecimalConverter() Decimal? otherCosts,
  }) = _ShiftAssumptions;

  factory ShiftAssumptions.fromJson(Map<String, dynamic> json) =>
      _$ShiftAssumptionsFromJson(json);
}

/// Warning codes in `estimate_details.warnings`.
abstract final class ShiftWarning {
  static const distanceCostsNotIncluded = 'distance_costs_not_included';
  static const fuelCostNotIncluded = 'fuel_cost_not_included';
  static const depreciationNotIncluded = 'depreciation_not_included';
  static const fewDaysForWeekday = 'few_days_for_weekday_used_all_days';
}

/// `estimate_details`: how the server reached the estimate. Every field is
/// optional because the two methods fill different ones.
class ShiftEstimateDetails {
  const ShiftEstimateDetails({
    this.method,
    this.hours,
    this.expectedOrders,
    this.expectedKm,
    this.fuelCost,
    this.depreciationCost,
    this.otherCosts,
    this.sources = const {},
    this.basis,
    this.nDays,
    this.windowStart,
    this.windowEnd,
    this.historicalHours,
    this.revenuePerHour,
    this.expensesPerHour,
    this.timezone,
    this.warnings = const [],
  });

  factory ShiftEstimateDetails.fromJson(Map<String, dynamic> json) {
    Decimal? dec(String key) => switch (json[key]) {
      null => null,
      final Object value => const DecimalConverter().fromJson(value),
    };
    DateTime? day(String key) => switch (json[key]) {
      final String value => parseIsoDate(value),
      _ => null,
    };
    return ShiftEstimateDetails(
      method: json['method'] as String?,
      hours: dec('hours'),
      expectedOrders: dec('expected_orders'),
      expectedKm: dec('expected_km'),
      fuelCost: dec('fuel_cost'),
      depreciationCost: dec('depreciation_cost'),
      otherCosts: dec('other_costs'),
      sources: {
        for (final MapEntry(:key, :value)
            in ((json['sources'] as Map<String, dynamic>?) ?? {}).entries)
          key: value as String?,
      },
      basis: json['basis'] as String?,
      nDays: json['n_days'] as int?,
      windowStart: day('window_start'),
      windowEnd: day('window_end'),
      historicalHours: dec('historical_hours'),
      revenuePerHour: dec('revenue_per_hour'),
      expensesPerHour: dec('expenses_per_hour'),
      timezone: json['timezone'] as String?,
      warnings: [
        for (final w in (json['warnings'] as List<dynamic>?) ?? const [])
          w as String,
      ],
    );
  }

  final String? method;
  final Decimal? hours;

  // assumption
  final Decimal? expectedOrders;
  final Decimal? expectedKm;
  final Decimal? fuelCost;
  final Decimal? depreciationCost;
  final Decimal? otherCosts;

  /// Where fuel/depreciation values came from: `scenario` or `rider_profile`
  /// (`null` = not available).
  final Map<String, String?> sources;

  // historical
  /// `same_weekday` or `all_days`.
  final String? basis;
  final int? nDays;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final Decimal? historicalHours;
  final Decimal? revenuePerHour;
  final Decimal? expensesPerHour;
  final String? timezone;

  final List<String> warnings;

  bool get usesSameWeekday => basis == 'same_weekday';
}

class _DetailsConverter
    implements JsonConverter<ShiftEstimateDetails, Map<String, dynamic>> {
  const _DetailsConverter();

  @override
  ShiftEstimateDetails fromJson(Map<String, dynamic> json) =>
      ShiftEstimateDetails.fromJson(json);

  @override
  Map<String, dynamic> toJson(ShiftEstimateDetails value) =>
      throw UnsupportedError('read only');
}

/// `GET /shift-scenarios/{id}`. Always an estimate ([isEstimate]); never part of
/// TrueProfit. All money is computed by the server.
@Freezed(toJson: false)
abstract class ShiftScenario with _$ShiftScenario {
  const ShiftScenario._();

  const factory ShiftScenario({
    required String id,
    required String name,
    @ClockTimeConverter() required ClockTime startTime,
    @ClockTimeConverter() required ClockTime endTime,
    required int durationMinutes,

    /// 0 = Monday ... 6 = Sunday; `null` = any day.
    int? plannedWeekday,
    required EstimationMethod estimationMethod,
    @Default(ShiftAssumptions()) ShiftAssumptions assumptions,
    @Default(true) bool isEstimate,
    @DecimalConverter() required Decimal estimatedRevenue,
    @DecimalConverter() required Decimal estimatedExpenses,
    @DecimalConverter() required Decimal estimatedNetProfit,
    @DecimalConverter() required Decimal estimatedNetProfitPerHour,

    /// P20-P80 range of the net profit (`historical` only).
    @NullableDecimalConverter() Decimal? estimateLow,
    @NullableDecimalConverter() Decimal? estimateHigh,
    @_DetailsConverter() required ShiftEstimateDetails estimateDetails,
    String? actualWorkSessionId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ShiftScenario;

  factory ShiftScenario.fromJson(Map<String, dynamic> json) =>
      _$ShiftScenarioFromJson(json);

  /// End before start.
  bool get crossesMidnight => endTime.minutesOfDay <= startTime.minutesOfDay;

  bool get hasRange => estimateLow != null && estimateHigh != null;
}

/// `POST /shift-scenarios` and `PATCH /shift-scenarios/{id}` body. A PATCH
/// replaces all assumptions; the work-session link is changed separately.
@Freezed(fromJson: false, toJson: true)
abstract class ShiftScenarioInput with _$ShiftScenarioInput {
  @JsonSerializable(includeIfNull: true)
  const factory ShiftScenarioInput({
    required String name,
    @ClockTimeConverter() required ClockTime startTime,
    @ClockTimeConverter() required ClockTime endTime,
    int? plannedWeekday,
    required EstimationMethod estimationMethod,
    required ShiftAssumptions assumptions,
  }) = _ShiftScenarioInput;
}

/// `POST /shift-scenarios/compare`: the scenarios in the requested order and the
/// best by net profit and by net profit per hour (may differ).
class ShiftComparison {
  const ShiftComparison({
    required this.scenarios,
    required this.bestNetProfitId,
    required this.bestNetProfitPerHourId,
  });

  factory ShiftComparison.fromJson(Map<String, dynamic> json) =>
      ShiftComparison(
        scenarios: [
          for (final s in json['scenarios'] as List<dynamic>)
            ShiftScenario.fromJson(s as Map<String, dynamic>),
        ],
        bestNetProfitId: json['best_net_profit_id'] as String,
        bestNetProfitPerHourId: json['best_net_profit_per_hour_id'] as String,
      );

  final List<ShiftScenario> scenarios;
  final String bestNetProfitId;
  final String bestNetProfitPerHourId;
}
