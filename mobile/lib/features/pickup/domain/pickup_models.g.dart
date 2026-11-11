// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pickup_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Coordinates _$CoordinatesFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Coordinates', json, ($checkedConvert) {
      final val = _Coordinates(
        lat: $checkedConvert('lat', (v) => (v as num).toDouble()),
        lng: $checkedConvert('lng', (v) => (v as num).toDouble()),
      );
      return val;
    });

Map<String, dynamic> _$CoordinatesToJson(_Coordinates instance) =>
    <String, dynamic>{'lat': instance.lat, 'lng': instance.lng};

_Restaurant _$RestaurantFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_Restaurant',
  json,
  ($checkedConvert) {
    final val = _Restaurant(
      id: $checkedConvert('id', (v) => v as String),
      source: $checkedConvert('source', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      isOwn: $checkedConvert('is_own', (v) => v as bool),
      supportsPrediction: $checkedConvert(
        'supports_prediction',
        (v) => v as bool,
      ),
      dataAvailability: $checkedConvert(
        'data_availability',
        (v) => $enumDecodeNullable(_$DataAvailabilityEnumMap, v),
      ),
      nOrders: $checkedConvert('n_orders', (v) => (v as num?)?.toInt()),
      location: $checkedConvert(
        'location',
        (v) =>
            v == null ? null : Coordinates.fromJson(v as Map<String, dynamic>),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'isOwn': 'is_own',
    'supportsPrediction': 'supports_prediction',
    'dataAvailability': 'data_availability',
    'nOrders': 'n_orders',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$RestaurantToJson(_Restaurant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': instance.source,
      'name': instance.name,
      'is_own': instance.isOwn,
      'supports_prediction': instance.supportsPrediction,
      'data_availability': _$DataAvailabilityEnumMap[instance.dataAvailability],
      'n_orders': instance.nOrders,
      'location': instance.location?.toJson(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$DataAvailabilityEnumMap = {
  DataAvailability.sufficient: 'sufficient',
  DataAvailability.limited: 'limited',
  DataAvailability.insufficient: 'insufficient',
};

Map<String, dynamic> _$RestaurantInputToJson(_RestaurantInput instance) =>
    <String, dynamic>{
      'name': instance.name,
      'location': instance.location?.toJson(),
    };

_StatCell _$StatCellFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_StatCell',
  json,
  ($checkedConvert) {
    final val = _StatCell(
      hour: $checkedConvert('hour', (v) => (v as num).toInt()),
      nOrders: $checkedConvert('n_orders', (v) => (v as num).toInt()),
      medianMin: $checkedConvert(
        'median_min',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
      p25Min: $checkedConvert(
        'p25_min',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
      p75Min: $checkedConvert(
        'p75_min',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
      p90Min: $checkedConvert(
        'p90_min',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'nOrders': 'n_orders',
    'medianMin': 'median_min',
    'p25Min': 'p25_min',
    'p75Min': 'p75_min',
    'p90Min': 'p90_min',
  },
);

Map<String, dynamic> _$StatCellToJson(_StatCell instance) => <String, dynamic>{
  'hour': instance.hour,
  'n_orders': instance.nOrders,
  'median_min': const NullableDecimalConverter().toJson(instance.medianMin),
  'p25_min': const NullableDecimalConverter().toJson(instance.p25Min),
  'p75_min': const NullableDecimalConverter().toJson(instance.p75Min),
  'p90_min': const NullableDecimalConverter().toJson(instance.p90Min),
};

_OverallStats _$OverallStatsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_OverallStats',
      json,
      ($checkedConvert) {
        final val = _OverallStats(
          nOrders: $checkedConvert('n_orders', (v) => (v as num).toInt()),
          medianMin: $checkedConvert(
            'median_min',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          p25Min: $checkedConvert(
            'p25_min',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          p75Min: $checkedConvert(
            'p75_min',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          p90Min: $checkedConvert(
            'p90_min',
            (v) => const NullableDecimalConverter().fromJson(v),
          ),
          peakHour: $checkedConvert('peak_hour', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'nOrders': 'n_orders',
        'medianMin': 'median_min',
        'p25Min': 'p25_min',
        'p75Min': 'p75_min',
        'p90Min': 'p90_min',
        'peakHour': 'peak_hour',
      },
    );

Map<String, dynamic> _$OverallStatsToJson(_OverallStats instance) =>
    <String, dynamic>{
      'n_orders': instance.nOrders,
      'median_min': const NullableDecimalConverter().toJson(instance.medianMin),
      'p25_min': const NullableDecimalConverter().toJson(instance.p25Min),
      'p75_min': const NullableDecimalConverter().toJson(instance.p75Min),
      'p90_min': const NullableDecimalConverter().toJson(instance.p90Min),
      'peak_hour': instance.peakHour,
    };

_RestaurantAnalytics _$RestaurantAnalyticsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_RestaurantAnalytics',
  json,
  ($checkedConvert) {
    final val = _RestaurantAnalytics(
      restaurant: $checkedConvert(
        'restaurant',
        (v) => Restaurant.fromJson(v as Map<String, dynamic>),
      ),
      dataAvailability: $checkedConvert(
        'data_availability',
        (v) => $enumDecode(_$DataAvailabilityEnumMap, v),
      ),
      overall: $checkedConvert(
        'overall',
        (v) =>
            v == null ? null : OverallStats.fromJson(v as Map<String, dynamic>),
      ),
      byHour: $checkedConvert(
        'by_hour',
        (v) =>
            (v as Map<String, dynamic>?)?.map(
              (k, e) => MapEntry(
                k,
                (e as List<dynamic>)
                    .map((e) => StatCell.fromJson(e as Map<String, dynamic>))
                    .toList(),
              ),
            ) ??
            const {},
      ),
      minOrdersForStats: $checkedConvert(
        'min_orders_for_stats',
        (v) => (v as num?)?.toInt() ?? 30,
      ),
      datasetVersion: $checkedConvert('dataset_version', (v) => v as String?),
      acknowledgement: $checkedConvert('acknowledgement', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'dataAvailability': 'data_availability',
    'byHour': 'by_hour',
    'minOrdersForStats': 'min_orders_for_stats',
    'datasetVersion': 'dataset_version',
  },
);

Map<String, dynamic> _$RestaurantAnalyticsToJson(
  _RestaurantAnalytics instance,
) => <String, dynamic>{
  'restaurant': instance.restaurant.toJson(),
  'data_availability': _$DataAvailabilityEnumMap[instance.dataAvailability]!,
  'overall': instance.overall?.toJson(),
  'by_hour': instance.byHour.map(
    (k, e) => MapEntry(k, e.map((e) => e.toJson()).toList()),
  ),
  'min_orders_for_stats': instance.minOrdersForStats,
  'dataset_version': instance.datasetVersion,
  'acknowledgement': instance.acknowledgement,
};

_WaitStats _$WaitStatsFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_WaitStats',
  json,
  ($checkedConvert) {
    final val = _WaitStats(
      restaurantId: $checkedConvert('restaurant_id', (v) => v as String),
      n: $checkedConvert('n', (v) => (v as num).toInt()),
      medianMinutes: $checkedConvert(
        'median_minutes',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
      p80Minutes: $checkedConvert(
        'p80_minutes',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
      confidence: $checkedConvert(
        'confidence',
        (v) => $enumDecode(_$WaitConfidenceEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'restaurantId': 'restaurant_id',
    'medianMinutes': 'median_minutes',
    'p80Minutes': 'p80_minutes',
  },
);

Map<String, dynamic> _$WaitStatsToJson(
  _WaitStats instance,
) => <String, dynamic>{
  'restaurant_id': instance.restaurantId,
  'n': instance.n,
  'median_minutes': const NullableDecimalConverter().toJson(
    instance.medianMinutes,
  ),
  'p80_minutes': const NullableDecimalConverter().toJson(instance.p80Minutes),
  'confidence': _$WaitConfidenceEnumMap[instance.confidence]!,
};

const _$WaitConfidenceEnumMap = {
  WaitConfidence.insufficient: 'insufficient',
  WaitConfidence.low: 'low',
  WaitConfidence.ok: 'ok',
};

_PredictionInterval _$PredictionIntervalFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PredictionInterval', json, ($checkedConvert) {
      final val = _PredictionInterval(
        low: $checkedConvert(
          'low',
          (v) => const DecimalConverter().fromJson(v as Object),
        ),
        high: $checkedConvert(
          'high',
          (v) => const DecimalConverter().fromJson(v as Object),
        ),
        nominalCoverage: $checkedConvert(
          'nominal_coverage',
          (v) => (v as num?)?.toDouble(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'nominalCoverage': 'nominal_coverage'});

Map<String, dynamic> _$PredictionIntervalToJson(_PredictionInterval instance) =>
    <String, dynamic>{
      'low': const DecimalConverter().toJson(instance.low),
      'high': const DecimalConverter().toJson(instance.high),
      'nominal_coverage': instance.nominalCoverage,
    };

_Prediction _$PredictionFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_Prediction',
  json,
  ($checkedConvert) {
    final val = _Prediction(
      id: $checkedConvert('id', (v) => v as String),
      restaurantId: $checkedConvert('restaurant_id', (v) => v as String?),
      restaurantName: $checkedConvert('restaurant_name', (v) => v as String?),
      predictedMinutes: $checkedConvert(
        'predicted_minutes',
        (v) => const DecimalConverter().fromJson(v as Object),
      ),
      interval: $checkedConvert(
        'interval',
        (v) => PredictionInterval.fromJson(v as Map<String, dynamic>),
      ),
      dataAvailability: $checkedConvert(
        'data_availability',
        (v) => $enumDecode(_$DataAvailabilityEnumMap, v),
      ),
      warnings: $checkedConvert(
        'warnings',
        (v) =>
            (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      ),
      modelVersion: $checkedConvert('model_version', (v) => v as String),
      requestedAt: $checkedConvert(
        'requested_at',
        (v) => const AwareDateTimeConverter().fromJson(v as String),
      ),
      disclaimer: $checkedConvert('disclaimer', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'restaurantId': 'restaurant_id',
    'restaurantName': 'restaurant_name',
    'predictedMinutes': 'predicted_minutes',
    'dataAvailability': 'data_availability',
    'modelVersion': 'model_version',
    'requestedAt': 'requested_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$PredictionToJson(
  _Prediction instance,
) => <String, dynamic>{
  'id': instance.id,
  'restaurant_id': instance.restaurantId,
  'restaurant_name': instance.restaurantName,
  'predicted_minutes': const DecimalConverter().toJson(
    instance.predictedMinutes,
  ),
  'interval': instance.interval.toJson(),
  'data_availability': _$DataAvailabilityEnumMap[instance.dataAvailability]!,
  'warnings': instance.warnings,
  'model_version': instance.modelVersion,
  'requested_at': const AwareDateTimeConverter().toJson(instance.requestedAt),
  'disclaimer': instance.disclaimer,
  'created_at': instance.createdAt.toIso8601String(),
};

_ModelInfo _$ModelInfoFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_ModelInfo',
  json,
  ($checkedConvert) {
    final val = _ModelInfo(
      name: $checkedConvert('name', (v) => v as String),
      version: $checkedConvert('version', (v) => v as String),
      dataset: $checkedConvert('dataset', (v) => v as String),
      domain: $checkedConvert('domain', (v) => v as String),
      trainedAt: $checkedConvert(
        'trained_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      testMetrics: $checkedConvert(
        'test_metrics',
        (v) => v as Map<String, dynamic>? ?? const {},
      ),
      baselineTestMetrics: $checkedConvert(
        'baseline_test_metrics',
        (v) => v as Map<String, dynamic>?,
      ),
      interval: $checkedConvert(
        'interval',
        (v) => v as Map<String, dynamic>? ?? const {},
      ),
      limitations: $checkedConvert(
        'limitations',
        (v) =>
            (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      ),
      acknowledgement: $checkedConvert('acknowledgement', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'trainedAt': 'trained_at',
    'testMetrics': 'test_metrics',
    'baselineTestMetrics': 'baseline_test_metrics',
  },
);

Map<String, dynamic> _$ModelInfoToJson(_ModelInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'dataset': instance.dataset,
      'domain': instance.domain,
      'trained_at': instance.trainedAt?.toIso8601String(),
      'test_metrics': instance.testMetrics,
      'baseline_test_metrics': instance.baselineTestMetrics,
      'interval': instance.interval,
      'limitations': instance.limitations,
      'acknowledgement': instance.acknowledgement,
    };

_PickupLog _$PickupLogFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_PickupLog',
  json,
  ($checkedConvert) {
    final val = _PickupLog(
      id: $checkedConvert('id', (v) => v as String),
      restaurantId: $checkedConvert('restaurant_id', (v) => v as String),
      restaurantName: $checkedConvert('restaurant_name', (v) => v as String),
      arrivedAt: $checkedConvert(
        'arrived_at',
        (v) => const AwareDateTimeConverter().fromJson(v as String),
      ),
      pickedUpAt: $checkedConvert(
        'picked_up_at',
        (v) => const AwareDateTimeConverter().fromJson(v as String),
      ),
      waitMinutes: $checkedConvert(
        'wait_minutes',
        (v) => const DecimalConverter().fromJson(v as Object),
      ),
      notes: $checkedConvert('notes', (v) => v as String?),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'restaurantId': 'restaurant_id',
    'restaurantName': 'restaurant_name',
    'arrivedAt': 'arrived_at',
    'pickedUpAt': 'picked_up_at',
    'waitMinutes': 'wait_minutes',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$PickupLogToJson(
  _PickupLog instance,
) => <String, dynamic>{
  'id': instance.id,
  'restaurant_id': instance.restaurantId,
  'restaurant_name': instance.restaurantName,
  'arrived_at': const AwareDateTimeConverter().toJson(instance.arrivedAt),
  'picked_up_at': const AwareDateTimeConverter().toJson(instance.pickedUpAt),
  'wait_minutes': const DecimalConverter().toJson(instance.waitMinutes),
  'notes': instance.notes,
  'created_at': instance.createdAt.toIso8601String(),
};

Map<String, dynamic> _$PickupLogInputToJson(
  _PickupLogInput instance,
) => <String, dynamic>{
  'restaurant_id': instance.restaurantId,
  'arrived_at': const AwareDateTimeConverter().toJson(instance.arrivedAt),
  'picked_up_at': const AwareDateTimeConverter().toJson(instance.pickedUpAt),
  'notes': instance.notes,
};
