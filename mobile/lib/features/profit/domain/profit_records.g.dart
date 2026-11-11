// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profit_records.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Income _$IncomeFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_Income',
  json,
  ($checkedConvert) {
    final val = _Income(
      id: $checkedConvert('id', (v) => v as String),
      occurredOn: $checkedConvert(
        'occurred_on',
        (v) => const DateOnlyConverter().fromJson(v as String),
      ),
      amount: $checkedConvert(
        'amount',
        (v) => const DecimalConverter().fromJson(v as Object),
      ),
      workSessionId: $checkedConvert('work_session_id', (v) => v as String?),
      orderCount: $checkedConvert('order_count', (v) => (v as num?)?.toInt()),
      distanceKm: $checkedConvert(
        'distance_km',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
      workingHours: $checkedConvert(
        'working_hours',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
      sourceLabel: $checkedConvert('source_label', (v) => v as String?),
      notes: $checkedConvert('notes', (v) => v as String?),
      isDemo: $checkedConvert('is_demo', (v) => v as bool? ?? false),
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
    'occurredOn': 'occurred_on',
    'workSessionId': 'work_session_id',
    'orderCount': 'order_count',
    'distanceKm': 'distance_km',
    'workingHours': 'working_hours',
    'sourceLabel': 'source_label',
    'isDemo': 'is_demo',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
  },
);

Map<String, dynamic> _$IncomeToJson(_Income instance) => <String, dynamic>{
  'id': instance.id,
  'occurred_on': const DateOnlyConverter().toJson(instance.occurredOn),
  'amount': const DecimalConverter().toJson(instance.amount),
  'work_session_id': instance.workSessionId,
  'order_count': instance.orderCount,
  'distance_km': const NullableDecimalConverter().toJson(instance.distanceKm),
  'working_hours': const NullableDecimalConverter().toJson(
    instance.workingHours,
  ),
  'source_label': instance.sourceLabel,
  'notes': instance.notes,
  'is_demo': instance.isDemo,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

_IncomeInput _$IncomeInputFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_IncomeInput',
  json,
  ($checkedConvert) {
    final val = _IncomeInput(
      occurredOn: $checkedConvert(
        'occurred_on',
        (v) => const DateOnlyConverter().fromJson(v as String),
      ),
      amount: $checkedConvert(
        'amount',
        (v) => const DecimalConverter().fromJson(v as Object),
      ),
      workSessionId: $checkedConvert('work_session_id', (v) => v as String?),
      orderCount: $checkedConvert('order_count', (v) => (v as num?)?.toInt()),
      distanceKm: $checkedConvert(
        'distance_km',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
      workingHours: $checkedConvert(
        'working_hours',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
      sourceLabel: $checkedConvert('source_label', (v) => v as String?),
      notes: $checkedConvert('notes', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'occurredOn': 'occurred_on',
    'workSessionId': 'work_session_id',
    'orderCount': 'order_count',
    'distanceKm': 'distance_km',
    'workingHours': 'working_hours',
    'sourceLabel': 'source_label',
  },
);

Map<String, dynamic> _$IncomeInputToJson(
  _IncomeInput instance,
) => <String, dynamic>{
  'occurred_on': const DateOnlyConverter().toJson(instance.occurredOn),
  'amount': const DecimalConverter().toJson(instance.amount),
  'work_session_id': instance.workSessionId,
  'order_count': instance.orderCount,
  'distance_km': const NullableDecimalConverter().toJson(instance.distanceKm),
  'working_hours': const NullableDecimalConverter().toJson(
    instance.workingHours,
  ),
  'source_label': instance.sourceLabel,
  'notes': instance.notes,
};

_Expense _$ExpenseFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_Expense',
  json,
  ($checkedConvert) {
    final val = _Expense(
      id: $checkedConvert('id', (v) => v as String),
      occurredOn: $checkedConvert(
        'occurred_on',
        (v) => const DateOnlyConverter().fromJson(v as String),
      ),
      category: $checkedConvert(
        'category',
        (v) => $enumDecode(_$ExpenseCategoryEnumMap, v),
      ),
      amount: $checkedConvert(
        'amount',
        (v) => const DecimalConverter().fromJson(v as Object),
      ),
      workSessionId: $checkedConvert('work_session_id', (v) => v as String?),
      description: $checkedConvert('description', (v) => v as String?),
      isDemo: $checkedConvert('is_demo', (v) => v as bool? ?? false),
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
    'occurredOn': 'occurred_on',
    'workSessionId': 'work_session_id',
    'isDemo': 'is_demo',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
  },
);

Map<String, dynamic> _$ExpenseToJson(_Expense instance) => <String, dynamic>{
  'id': instance.id,
  'occurred_on': const DateOnlyConverter().toJson(instance.occurredOn),
  'category': _$ExpenseCategoryEnumMap[instance.category]!,
  'amount': const DecimalConverter().toJson(instance.amount),
  'work_session_id': instance.workSessionId,
  'description': instance.description,
  'is_demo': instance.isDemo,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$ExpenseCategoryEnumMap = {
  ExpenseCategory.fuel: 'fuel',
  ExpenseCategory.maintenance: 'maintenance',
  ExpenseCategory.depreciation: 'depreciation',
  ExpenseCategory.other: 'other',
};

_ExpenseInput _$ExpenseInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ExpenseInput', json, ($checkedConvert) {
      final val = _ExpenseInput(
        occurredOn: $checkedConvert(
          'occurred_on',
          (v) => const DateOnlyConverter().fromJson(v as String),
        ),
        category: $checkedConvert(
          'category',
          (v) => $enumDecode(_$ExpenseCategoryEnumMap, v),
        ),
        amount: $checkedConvert(
          'amount',
          (v) => const DecimalConverter().fromJson(v as Object),
        ),
        description: $checkedConvert('description', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'occurredOn': 'occurred_on'});

Map<String, dynamic> _$ExpenseInputToJson(_ExpenseInput instance) =>
    <String, dynamic>{
      'occurred_on': const DateOnlyConverter().toJson(instance.occurredOn),
      'category': _$ExpenseCategoryEnumMap[instance.category]!,
      'amount': const DecimalConverter().toJson(instance.amount),
      'description': instance.description,
    };

_WorkSession _$WorkSessionFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_WorkSession',
  json,
  ($checkedConvert) {
    final val = _WorkSession(
      id: $checkedConvert('id', (v) => v as String),
      startedAt: $checkedConvert(
        'started_at',
        (v) => const AwareDateTimeConverter().fromJson(v as String),
      ),
      endedAt: $checkedConvert(
        'ended_at',
        (v) => const AwareDateTimeConverter().fromJson(v as String),
      ),
      distanceKm: $checkedConvert(
        'distance_km',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
      orderCount: $checkedConvert('order_count', (v) => (v as num?)?.toInt()),
      notes: $checkedConvert('notes', (v) => v as String?),
      isDemo: $checkedConvert('is_demo', (v) => v as bool? ?? false),
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
    'startedAt': 'started_at',
    'endedAt': 'ended_at',
    'distanceKm': 'distance_km',
    'orderCount': 'order_count',
    'isDemo': 'is_demo',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
  },
);

Map<String, dynamic> _$WorkSessionToJson(
  _WorkSession instance,
) => <String, dynamic>{
  'id': instance.id,
  'started_at': const AwareDateTimeConverter().toJson(instance.startedAt),
  'ended_at': const AwareDateTimeConverter().toJson(instance.endedAt),
  'distance_km': const NullableDecimalConverter().toJson(instance.distanceKm),
  'order_count': instance.orderCount,
  'notes': instance.notes,
  'is_demo': instance.isDemo,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

_WorkSessionInput _$WorkSessionInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_WorkSessionInput',
      json,
      ($checkedConvert) {
        final val = _WorkSessionInput(
          startedAt: $checkedConvert(
            'started_at',
            (v) => const AwareDateTimeConverter().fromJson(v as String),
          ),
          endedAt: $checkedConvert(
            'ended_at',
            (v) => const AwareDateTimeConverter().fromJson(v as String),
          ),
          distanceKm: $checkedConvert(
            'distance_km',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          orderCount: $checkedConvert(
            'order_count',
            (v) => (v as num?)?.toInt(),
          ),
          notes: $checkedConvert('notes', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'startedAt': 'started_at',
        'endedAt': 'ended_at',
        'distanceKm': 'distance_km',
        'orderCount': 'order_count',
      },
    );

Map<String, dynamic> _$WorkSessionInputToJson(
  _WorkSessionInput instance,
) => <String, dynamic>{
  'started_at': const AwareDateTimeConverter().toJson(instance.startedAt),
  'ended_at': const AwareDateTimeConverter().toJson(instance.endedAt),
  'distance_km': const NullableDecimalConverter().toJson(instance.distanceKm),
  'order_count': instance.orderCount,
  'notes': instance.notes,
};
