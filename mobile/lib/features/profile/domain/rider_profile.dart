import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/decimal_json.dart';

part 'rider_profile.freezed.dart';
part 'rider_profile.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum VehicleType { motorcycle, evMotorcycle, bicycle, car, other }

abstract final class RiderProfileDefaults {
  static const timezone = 'Asia/Bangkok';
  static const currency = 'THB';
}

/// Column limits of `rider_profiles` (NUMERIC(precision, scale)).
abstract final class RiderProfileLimits {
  static const fuelKmPerLiter = (maxDigits: 6, places: 2);
  static const fuelPricePerLiter = (maxDigits: 8, places: 2);
  static const depreciationPerKm = (maxDigits: 8, places: 4);
  static const dailyGoal = (maxDigits: 12, places: 2);
}

/// `GET /me/rider-profile`. Until the first save the backend returns defaults with
/// `is_configured: false`; the app uses that to show onboarding.
@freezed
abstract class RiderProfile with _$RiderProfile {
  const factory RiderProfile({
    VehicleType? vehicleType,
    @NullableDecimalConverter() Decimal? fuelKmPerLiter,
    @NullableDecimalConverter() Decimal? fuelPricePerLiter,
    @NullableDecimalConverter() Decimal? depreciationPerKm,

    /// Net-profit target for one day (Home progress ring); `null` = no goal.
    @NullableDecimalConverter() Decimal? dailyGoal,
    @Default(RiderProfileDefaults.timezone) String timezone,
    @Default(RiderProfileDefaults.currency) String currency,
    @Default(false) bool isConfigured,
    DateTime? updatedAt,
  }) = _RiderProfile;

  factory RiderProfile.fromJson(Map<String, dynamic> json) =>
      _$RiderProfileFromJson(json);
}

/// `PUT /me/rider-profile` body: replaces the whole profile (omitted = null/default).
@Freezed(fromJson: false, toJson: true)
abstract class RiderProfileInput with _$RiderProfileInput {
  @JsonSerializable(includeIfNull: true)
  const factory RiderProfileInput({
    VehicleType? vehicleType,
    @NullableDecimalConverter() Decimal? fuelKmPerLiter,
    @NullableDecimalConverter() Decimal? fuelPricePerLiter,
    @NullableDecimalConverter() Decimal? depreciationPerKm,
    @NullableDecimalConverter() Decimal? dailyGoal,
    @Default(RiderProfileDefaults.timezone) String timezone,
    @Default(RiderProfileDefaults.currency) String currency,
  }) = _RiderProfileInput;

  /// The saved profile as a `PUT` body, so one field can change and the rest stay.
  factory RiderProfileInput.from(RiderProfile profile) => RiderProfileInput(
    vehicleType: profile.vehicleType,
    fuelKmPerLiter: profile.fuelKmPerLiter,
    fuelPricePerLiter: profile.fuelPricePerLiter,
    depreciationPerKm: profile.depreciationPerKm,
    dailyGoal: profile.dailyGoal,
    timezone: profile.timezone,
    currency: profile.currency,
  );
}
