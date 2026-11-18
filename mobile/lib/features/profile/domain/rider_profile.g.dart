// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rider_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RiderProfile _$RiderProfileFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_RiderProfile',
      json,
      ($checkedConvert) {
        final val = _RiderProfile(
          vehicleType: $checkedConvert(
            'vehicle_type',
            (v) => $enumDecodeNullable(_$VehicleTypeEnumMap, v),
          ),
          fuelKmPerLiter: $checkedConvert(
            'fuel_km_per_liter',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          fuelPricePerLiter: $checkedConvert(
            'fuel_price_per_liter',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          depreciationPerKm: $checkedConvert(
            'depreciation_per_km',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          dailyGoal: $checkedConvert(
            'daily_goal',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          timezone: $checkedConvert(
            'timezone',
            (v) => v as String? ?? RiderProfileDefaults.timezone,
          ),
          currency: $checkedConvert(
            'currency',
            (v) => v as String? ?? RiderProfileDefaults.currency,
          ),
          isConfigured: $checkedConvert(
            'is_configured',
            (v) => v as bool? ?? false,
          ),
          updatedAt: $checkedConvert(
            'updated_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'vehicleType': 'vehicle_type',
        'fuelKmPerLiter': 'fuel_km_per_liter',
        'fuelPricePerLiter': 'fuel_price_per_liter',
        'depreciationPerKm': 'depreciation_per_km',
        'dailyGoal': 'daily_goal',
        'isConfigured': 'is_configured',
        'updatedAt': 'updated_at',
      },
    );

Map<String, dynamic> _$RiderProfileToJson(_RiderProfile instance) =>
    <String, dynamic>{
      'vehicle_type': _$VehicleTypeEnumMap[instance.vehicleType],
      'fuel_km_per_liter': const NullableDecimalConverter().toJson(
        instance.fuelKmPerLiter,
      ),
      'fuel_price_per_liter': const NullableDecimalConverter().toJson(
        instance.fuelPricePerLiter,
      ),
      'depreciation_per_km': const NullableDecimalConverter().toJson(
        instance.depreciationPerKm,
      ),
      'daily_goal': const NullableDecimalConverter().toJson(instance.dailyGoal),
      'timezone': instance.timezone,
      'currency': instance.currency,
      'is_configured': instance.isConfigured,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$VehicleTypeEnumMap = {
  VehicleType.motorcycle: 'motorcycle',
  VehicleType.evMotorcycle: 'ev_motorcycle',
  VehicleType.bicycle: 'bicycle',
  VehicleType.car: 'car',
  VehicleType.other: 'other',
};

_RiderProfileInput _$RiderProfileInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_RiderProfileInput',
      json,
      ($checkedConvert) {
        final val = _RiderProfileInput(
          vehicleType: $checkedConvert(
            'vehicle_type',
            (v) => $enumDecodeNullable(_$VehicleTypeEnumMap, v),
          ),
          fuelKmPerLiter: $checkedConvert(
            'fuel_km_per_liter',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          fuelPricePerLiter: $checkedConvert(
            'fuel_price_per_liter',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          depreciationPerKm: $checkedConvert(
            'depreciation_per_km',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          dailyGoal: $checkedConvert(
            'daily_goal',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          timezone: $checkedConvert(
            'timezone',
            (v) => v as String? ?? RiderProfileDefaults.timezone,
          ),
          currency: $checkedConvert(
            'currency',
            (v) => v as String? ?? RiderProfileDefaults.currency,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'vehicleType': 'vehicle_type',
        'fuelKmPerLiter': 'fuel_km_per_liter',
        'fuelPricePerLiter': 'fuel_price_per_liter',
        'depreciationPerKm': 'depreciation_per_km',
        'dailyGoal': 'daily_goal',
      },
    );

Map<String, dynamic> _$RiderProfileInputToJson(_RiderProfileInput instance) =>
    <String, dynamic>{
      'vehicle_type': _$VehicleTypeEnumMap[instance.vehicleType],
      'fuel_km_per_liter': const NullableDecimalConverter().toJson(
        instance.fuelKmPerLiter,
      ),
      'fuel_price_per_liter': const NullableDecimalConverter().toJson(
        instance.fuelPricePerLiter,
      ),
      'depreciation_per_km': const NullableDecimalConverter().toJson(
        instance.depreciationPerKm,
      ),
      'daily_goal': const NullableDecimalConverter().toJson(instance.dailyGoal),
      'timezone': instance.timezone,
      'currency': instance.currency,
    };
