// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'road_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoadPoint _$RoadPointFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RoadPoint', json, ($checkedConvert) {
      final val = _RoadPoint(
        lat: $checkedConvert('lat', (v) => (v as num).toDouble()),
        lng: $checkedConvert('lng', (v) => (v as num).toDouble()),
      );
      return val;
    });

Map<String, dynamic> _$RoadPointToJson(_RoadPoint instance) =>
    <String, dynamic>{'lat': instance.lat, 'lng': instance.lng};

_Incident _$IncidentFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_Incident',
  json,
  ($checkedConvert) {
    final val = _Incident(
      id: $checkedConvert('id', (v) => v as String),
      category: $checkedConvert(
        'category',
        (v) => $enumDecode(_$RoadCategoryEnumMap, v),
      ),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$IncidentStatusEnumMap, v),
      ),
      location: $checkedConvert(
        'location',
        (v) => RoadPoint.fromJson(v as Map<String, dynamic>),
      ),
      firstReportedAt: $checkedConvert(
        'first_reported_at',
        (v) => DateTime.parse(v as String),
      ),
      lastReportedAt: $checkedConvert(
        'last_reported_at',
        (v) => DateTime.parse(v as String),
      ),
      reportCount: $checkedConvert('report_count', (v) => (v as num).toInt()),
      distinctReporters: $checkedConvert(
        'distinct_reporters',
        (v) => (v as num).toInt(),
      ),
      clearedCount: $checkedConvert('cleared_count', (v) => (v as num).toInt()),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
      distanceM: $checkedConvert('distance_m', (v) => (v as num?)?.toDouble()),
    );
    return val;
  },
  fieldKeyMap: const {
    'firstReportedAt': 'first_reported_at',
    'lastReportedAt': 'last_reported_at',
    'reportCount': 'report_count',
    'distinctReporters': 'distinct_reporters',
    'clearedCount': 'cleared_count',
    'expiresAt': 'expires_at',
    'distanceM': 'distance_m',
  },
);

Map<String, dynamic> _$IncidentToJson(_Incident instance) => <String, dynamic>{
  'id': instance.id,
  'category': _$RoadCategoryEnumMap[instance.category]!,
  'status': _$IncidentStatusEnumMap[instance.status]!,
  'location': instance.location.toJson(),
  'first_reported_at': instance.firstReportedAt.toIso8601String(),
  'last_reported_at': instance.lastReportedAt.toIso8601String(),
  'report_count': instance.reportCount,
  'distinct_reporters': instance.distinctReporters,
  'cleared_count': instance.clearedCount,
  'expires_at': instance.expiresAt.toIso8601String(),
  'distance_m': instance.distanceM,
};

const _$RoadCategoryEnumMap = {
  RoadCategory.flooding: 'flooding',
  RoadCategory.roadDamage: 'road_damage',
  RoadCategory.roadClosure: 'road_closure',
  RoadCategory.roadObstacle: 'road_obstacle',
  RoadCategory.trafficIncident: 'traffic_incident',
};

const _$IncidentStatusEnumMap = {
  IncidentStatus.unverified: 'unverified',
  IncidentStatus.corroborated: 'corroborated',
  IncidentStatus.resolved: 'resolved',
  IncidentStatus.expired: 'expired',
  IncidentStatus.rejected: 'rejected',
};

_IncidentList _$IncidentListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_IncidentList', json, ($checkedConvert) {
      final val = _IncidentList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Incident.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        truncated: $checkedConvert('truncated', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$IncidentListToJson(_IncidentList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'truncated': instance.truncated,
    };

_OwnReport _$OwnReportFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_OwnReport',
  json,
  ($checkedConvert) {
    final val = _OwnReport(
      id: $checkedConvert('id', (v) => v as String),
      incidentId: $checkedConvert('incident_id', (v) => v as String),
      category: $checkedConvert(
        'category',
        (v) => $enumDecode(_$RoadCategoryEnumMap, v),
      ),
      description: $checkedConvert('description', (v) => v as String?),
      location: $checkedConvert(
        'location',
        (v) => RoadPoint.fromJson(v as Map<String, dynamic>),
      ),
      hasImage: $checkedConvert('has_image', (v) => v as bool),
      aiStatus: $checkedConvert(
        'ai_status',
        (v) => $enumDecode(_$AiStatusEnumMap, v),
      ),
      aiLabel: $checkedConvert('ai_label', (v) => v as String?),
      aiConfidence: $checkedConvert(
        'ai_confidence',
        (v) => const NullableDecimalConverter().fromJson(v),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      incidentStatus: $checkedConvert(
        'incident_status',
        (v) => $enumDecode(_$IncidentStatusEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'incidentId': 'incident_id',
    'hasImage': 'has_image',
    'aiStatus': 'ai_status',
    'aiLabel': 'ai_label',
    'aiConfidence': 'ai_confidence',
    'createdAt': 'created_at',
    'incidentStatus': 'incident_status',
  },
);

Map<String, dynamic> _$OwnReportToJson(_OwnReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'incident_id': instance.incidentId,
      'category': _$RoadCategoryEnumMap[instance.category]!,
      'description': instance.description,
      'location': instance.location.toJson(),
      'has_image': instance.hasImage,
      'ai_status': _$AiStatusEnumMap[instance.aiStatus]!,
      'ai_label': instance.aiLabel,
      'ai_confidence': const NullableDecimalConverter().toJson(
        instance.aiConfidence,
      ),
      'created_at': instance.createdAt.toIso8601String(),
      'incident_status': _$IncidentStatusEnumMap[instance.incidentStatus]!,
    };

const _$AiStatusEnumMap = {
  AiStatus.none: 'none',
  AiStatus.pending: 'pending',
  AiStatus.done: 'done',
  AiStatus.failed: 'failed',
};

_MyConfirmation _$MyConfirmationFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_MyConfirmation',
      json,
      ($checkedConvert) {
        final val = _MyConfirmation(
          stillPresent: $checkedConvert('still_present', (v) => v as bool),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'stillPresent': 'still_present',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$MyConfirmationToJson(_MyConfirmation instance) =>
    <String, dynamic>{
      'still_present': instance.stillPresent,
      'created_at': instance.createdAt.toIso8601String(),
    };

_ReportCreated _$ReportCreatedFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_ReportCreated',
      json,
      ($checkedConvert) {
        final val = _ReportCreated(
          reportId: $checkedConvert('report_id', (v) => v as String),
          incidentId: $checkedConvert('incident_id', (v) => v as String),
          merged: $checkedConvert('merged', (v) => v as bool),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$IncidentStatusEnumMap, v),
          ),
          incident: $checkedConvert(
            'incident',
            (v) => Incident.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {'reportId': 'report_id', 'incidentId': 'incident_id'},
    );

Map<String, dynamic> _$ReportCreatedToJson(_ReportCreated instance) =>
    <String, dynamic>{
      'report_id': instance.reportId,
      'incident_id': instance.incidentId,
      'merged': instance.merged,
      'status': _$IncidentStatusEnumMap[instance.status]!,
      'incident': instance.incident.toJson(),
    };
