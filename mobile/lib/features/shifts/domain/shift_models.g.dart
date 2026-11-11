// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShiftAssumptions _$ShiftAssumptionsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_ShiftAssumptions',
      json,
      ($checkedConvert) {
        final val = _ShiftAssumptions(
          ordersPerHour: $checkedConvert(
            'orders_per_hour',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          incomePerOrder: $checkedConvert(
            'income_per_order',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          kmPerOrder: $checkedConvert(
            'km_per_order',
            (v) => const NullableDecimalConverter().fromJson(v),
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
          otherCosts: $checkedConvert(
            'other_costs',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'ordersPerHour': 'orders_per_hour',
        'incomePerOrder': 'income_per_order',
        'kmPerOrder': 'km_per_order',
        'fuelKmPerLiter': 'fuel_km_per_liter',
        'fuelPricePerLiter': 'fuel_price_per_liter',
        'depreciationPerKm': 'depreciation_per_km',
        'otherCosts': 'other_costs',
      },
    );

Map<String, dynamic> _$ShiftAssumptionsToJson(
  _ShiftAssumptions instance,
) => <String, dynamic>{
  'orders_per_hour': ?const NullableDecimalConverter().toJson(
    instance.ordersPerHour,
  ),
  'income_per_order': ?const NullableDecimalConverter().toJson(
    instance.incomePerOrder,
  ),
  'km_per_order': ?const NullableDecimalConverter().toJson(instance.kmPerOrder),
  'fuel_km_per_liter': ?const NullableDecimalConverter().toJson(
    instance.fuelKmPerLiter,
  ),
  'fuel_price_per_liter': ?const NullableDecimalConverter().toJson(
    instance.fuelPricePerLiter,
  ),
  'depreciation_per_km': ?const NullableDecimalConverter().toJson(
    instance.depreciationPerKm,
  ),
  'other_costs': ?const NullableDecimalConverter().toJson(instance.otherCosts),
};

_ShiftScenario _$ShiftScenarioFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_ShiftScenario',
      json,
      ($checkedConvert) {
        final val = _ShiftScenario(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          startTime: $checkedConvert(
            'start_time',
            (v) => const ClockTimeConverter().fromJson(v as String),
          ),
          endTime: $checkedConvert(
            'end_time',
            (v) => const ClockTimeConverter().fromJson(v as String),
          ),
          durationMinutes: $checkedConvert(
            'duration_minutes',
            (v) => (v as num).toInt(),
          ),
          plannedWeekday: $checkedConvert(
            'planned_weekday',
            (v) => (v as num?)?.toInt(),
          ),
          estimationMethod: $checkedConvert(
            'estimation_method',
            (v) => $enumDecode(_$EstimationMethodEnumMap, v),
          ),
          assumptions: $checkedConvert(
            'assumptions',
            (v) => v == null
                ? const ShiftAssumptions()
                : ShiftAssumptions.fromJson(v as Map<String, dynamic>),
          ),
          isEstimate: $checkedConvert('is_estimate', (v) => v as bool? ?? true),
          estimatedRevenue: $checkedConvert(
            'estimated_revenue',
            (v) => const DecimalConverter().fromJson(v as Object),
          ),
          estimatedExpenses: $checkedConvert(
            'estimated_expenses',
            (v) => const DecimalConverter().fromJson(v as Object),
          ),
          estimatedNetProfit: $checkedConvert(
            'estimated_net_profit',
            (v) => const DecimalConverter().fromJson(v as Object),
          ),
          estimatedNetProfitPerHour: $checkedConvert(
            'estimated_net_profit_per_hour',
            (v) => const DecimalConverter().fromJson(v as Object),
          ),
          estimateLow: $checkedConvert(
            'estimate_low',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          estimateHigh: $checkedConvert(
            'estimate_high',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          estimateDetails: $checkedConvert(
            'estimate_details',
            (v) =>
                const _DetailsConverter().fromJson(v as Map<String, dynamic>),
          ),
          actualWorkSessionId: $checkedConvert(
            'actual_work_session_id',
            (v) => v as String?,
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          updatedAt: $checkedConvert(
            'updated_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'startTime': 'start_time',
        'endTime': 'end_time',
        'durationMinutes': 'duration_minutes',
        'plannedWeekday': 'planned_weekday',
        'estimationMethod': 'estimation_method',
        'isEstimate': 'is_estimate',
        'estimatedRevenue': 'estimated_revenue',
        'estimatedExpenses': 'estimated_expenses',
        'estimatedNetProfit': 'estimated_net_profit',
        'estimatedNetProfitPerHour': 'estimated_net_profit_per_hour',
        'estimateLow': 'estimate_low',
        'estimateHigh': 'estimate_high',
        'estimateDetails': 'estimate_details',
        'actualWorkSessionId': 'actual_work_session_id',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
      },
    );

const _$EstimationMethodEnumMap = {
  EstimationMethod.assumption: 'assumption',
  EstimationMethod.historical: 'historical',
  EstimationMethod.ml: 'ml',
};

_ShiftScenarioInput _$ShiftScenarioInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_ShiftScenarioInput',
      json,
      ($checkedConvert) {
        final val = _ShiftScenarioInput(
          name: $checkedConvert('name', (v) => v as String),
          startTime: $checkedConvert(
            'start_time',
            (v) => const ClockTimeConverter().fromJson(v as String),
          ),
          endTime: $checkedConvert(
            'end_time',
            (v) => const ClockTimeConverter().fromJson(v as String),
          ),
          plannedWeekday: $checkedConvert(
            'planned_weekday',
            (v) => (v as num?)?.toInt(),
          ),
          estimationMethod: $checkedConvert(
            'estimation_method',
            (v) => $enumDecode(_$EstimationMethodEnumMap, v),
          ),
          assumptions: $checkedConvert(
            'assumptions',
            (v) => ShiftAssumptions.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'startTime': 'start_time',
        'endTime': 'end_time',
        'plannedWeekday': 'planned_weekday',
        'estimationMethod': 'estimation_method',
      },
    );

Map<String, dynamic> _$ShiftScenarioInputToJson(
  _ShiftScenarioInput instance,
) => <String, dynamic>{
  'name': instance.name,
  'start_time': const ClockTimeConverter().toJson(instance.startTime),
  'end_time': const ClockTimeConverter().toJson(instance.endTime),
  'planned_weekday': instance.plannedWeekday,
  'estimation_method': _$EstimationMethodEnumMap[instance.estimationMethod]!,
  'assumptions': instance.assumptions.toJson(),
};
