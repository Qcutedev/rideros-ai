// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profit_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfitMetrics _$ProfitMetricsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_ProfitMetrics',
  json,
  ($checkedConvert) {
    final val = _ProfitMetrics(
      totalRevenue: $checkedConvert(
        'total_revenue',
        (v) => const DecimalConverter().fromJson(v as Object),
      ),
      totalExpenses: $checkedConvert(
        'total_expenses',
        (v) => const DecimalConverter().fromJson(v as Object),
      ),
      netProfit: $checkedConvert(
        'net_profit',
        (v) => const DecimalConverter().fromJson(v as Object),
      ),
      workingHours: $checkedConvert(
        'working_hours',
        (v) => const DecimalConverter().fromJson(v as Object),
      ),
      revenuePerHour: $checkedConvert(
        'revenue_per_hour',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
      netProfitPerHour: $checkedConvert(
        'net_profit_per_hour',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
      reason: $checkedConvert('reason', (v) => v as String?),
      incomeCount: $checkedConvert('income_count', (v) => (v as num).toInt()),
      expenseCount: $checkedConvert('expense_count', (v) => (v as num).toInt()),
      workSessionCount: $checkedConvert(
        'work_session_count',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'totalRevenue': 'total_revenue',
    'totalExpenses': 'total_expenses',
    'netProfit': 'net_profit',
    'workingHours': 'working_hours',
    'revenuePerHour': 'revenue_per_hour',
    'netProfitPerHour': 'net_profit_per_hour',
    'incomeCount': 'income_count',
    'expenseCount': 'expense_count',
    'workSessionCount': 'work_session_count',
  },
);

Map<String, dynamic> _$ProfitMetricsToJson(_ProfitMetrics instance) =>
    <String, dynamic>{
      'total_revenue': const DecimalConverter().toJson(instance.totalRevenue),
      'total_expenses': const DecimalConverter().toJson(instance.totalExpenses),
      'net_profit': const DecimalConverter().toJson(instance.netProfit),
      'working_hours': const DecimalConverter().toJson(instance.workingHours),
      'revenue_per_hour': const NullableDecimalConverter().toJson(
        instance.revenuePerHour,
      ),
      'net_profit_per_hour': const NullableDecimalConverter().toJson(
        instance.netProfitPerHour,
      ),
      'reason': instance.reason,
      'income_count': instance.incomeCount,
      'expense_count': instance.expenseCount,
      'work_session_count': instance.workSessionCount,
    };
