import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/decimal_json.dart';

part 'road_models.freezed.dart';
part 'road_models.g.dart';

/// Limits of `backend/app/modules/road` (rules + router).
abstract final class RoadLimits {
  static const descriptionMaxLength = 500;

  /// `GET /road/incidents?bbox=` rejects a wider view (`invalid_bbox`).
  static const maxBboxSpanDeg = 2.0;

  /// `GET /road/incidents/nearby` default radius.
  static const nearbyRadiusM = 2000;

  /// The server refuses larger photos (`image_too_large`).
  static const maxImageBytes = 5 * 1024 * 1024;

  /// The app shrinks photos to this edge before upload (the server keeps ≤ 1600 px).
  static const photoMaxEdge = 1600.0;
  static const photoQuality = 85;
}

@JsonEnum(fieldRename: FieldRename.snake)
enum RoadCategory {
  flooding,
  roadDamage,
  roadClosure,
  roadObstacle,
  trafficIncident;

  /// Form / query value (`road_damage`).
  String get apiValue => _$RoadCategoryEnumMap[this]!;
}

/// `unverified` and `corroborated` are open (on the map, open to reports and
/// confirmations). `corroborated` means several riders reported it, never that
/// anyone verified it.
@JsonEnum(fieldRename: FieldRename.snake)
enum IncidentStatus {
  unverified,
  corroborated,
  resolved,
  expired,
  rejected;

  bool get isOpen => this == unverified || this == corroborated;
}

/// Photo classification state of a report (CV, Phase 5c).
@JsonEnum(fieldRename: FieldRename.snake)
enum AiStatus { none, pending, done, failed }

@freezed
abstract class RoadPoint with _$RoadPoint {
  const factory RoadPoint({required double lat, required double lng}) =
      _RoadPoint;

  factory RoadPoint.fromJson(Map<String, dynamic> json) =>
      _$RoadPointFromJson(json);
}

/// Aggregate view of an incident. Never names who reported it.
@freezed
abstract class Incident with _$Incident {
  const factory Incident({
    required String id,
    required RoadCategory category,

    /// Effective status: an open incident past [expiresAt] reads `expired`.
    required IncidentStatus status,
    required RoadPoint location,
    required DateTime firstReportedAt,
    required DateTime lastReportedAt,
    required int reportCount,

    /// Riders who reported it or said it is still there.
    required int distinctReporters,

    /// Riders who said it is gone since the last report.
    required int clearedCount,
    required DateTime expiresAt,

    /// Only in `/nearby` results.
    double? distanceM,
  }) = _Incident;

  factory Incident.fromJson(Map<String, dynamic> json) =>
      _$IncidentFromJson(json);
}

/// `GET /road/incidents` and `/road/incidents/nearby`.
@freezed
abstract class IncidentList with _$IncidentList {
  const factory IncidentList({
    required List<Incident> items,

    /// More incidents matched than the server returns: zoom in or move closer.
    @Default(false) bool truncated,
  }) = _IncidentList;

  factory IncidentList.fromJson(Map<String, dynamic> json) =>
      _$IncidentListFromJson(json);
}

/// A report the current rider submitted (only ever returned to its author).
@freezed
abstract class OwnReport with _$OwnReport {
  const factory OwnReport({
    required String id,
    required String incidentId,
    required RoadCategory category,
    String? description,
    required RoadPoint location,
    required bool hasImage,
    required AiStatus aiStatus,

    /// Category suggested from the photo; a suggestion only.
    String? aiLabel,
    @NullableDecimalConverter() Decimal? aiConfidence,
    required DateTime createdAt,
    required IncidentStatus incidentStatus,
  }) = _OwnReport;

  factory OwnReport.fromJson(Map<String, dynamic> json) =>
      _$OwnReportFromJson(json);
}

/// The rider's latest "still there" / "gone" answer.
@freezed
abstract class MyConfirmation with _$MyConfirmation {
  const factory MyConfirmation({
    required bool stillPresent,
    required DateTime createdAt,
  }) = _MyConfirmation;

  factory MyConfirmation.fromJson(Map<String, dynamic> json) =>
      _$MyConfirmationFromJson(json);
}

/// `GET /road/incidents/{id}`: the incident plus the rider's own report and
/// answer, in any status.
class IncidentDetail {
  const IncidentDetail({
    required this.incident,
    this.myReport,
    this.myConfirmation,
  });

  factory IncidentDetail.fromJson(Map<String, dynamic> json) => IncidentDetail(
    incident: Incident.fromJson(json),
    myReport: switch (json['my_report']) {
      final Map<String, dynamic> report => OwnReport.fromJson(report),
      _ => null,
    },
    myConfirmation: switch (json['my_confirmation']) {
      final Map<String, dynamic> answer => MyConfirmation.fromJson(answer),
      _ => null,
    },
  );

  final Incident incident;
  final OwnReport? myReport;
  final MyConfirmation? myConfirmation;
}

/// `POST /road/reports` 201.
@freezed
abstract class ReportCreated with _$ReportCreated {
  const factory ReportCreated({
    required String reportId,
    required String incidentId,

    /// The report joined an existing nearby incident.
    required bool merged,
    required IncidentStatus status,
    required Incident incident,
  }) = _ReportCreated;

  factory ReportCreated.fromJson(Map<String, dynamic> json) =>
      _$ReportCreatedFromJson(json);
}

/// A photo picked for a report (already shrunk by the picker).
class ReportPhoto {
  const ReportPhoto({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

/// `POST /road/reports` (multipart).
class NewReport {
  const NewReport({
    required this.category,
    required this.location,
    this.description,
    this.photo,
  });

  final RoadCategory category;
  final RoadPoint location;
  final String? description;
  final ReportPhoto? photo;
}

/// A map view for `GET /road/incidents?bbox=`. Edges are rounded outwards to
/// 3 decimals (about 100 m) so small pans reuse the last answer.
class RoadBounds {
  factory RoadBounds({
    required double west,
    required double south,
    required double east,
    required double north,
  }) => RoadBounds._(
    _down(west.clamp(-180, 180)),
    _down(south.clamp(-90, 90)),
    _up(east.clamp(-180, 180)),
    _up(north.clamp(-90, 90)),
  );

  const RoadBounds._(this.west, this.south, this.east, this.north);

  final double west;
  final double south;
  final double east;
  final double north;

  static double _down(double v) => (v * 1000).floorToDouble() / 1000;
  static double _up(double v) => (v * 1000).ceilToDouble() / 1000;

  /// Wider or taller than the server allows: zoom in first.
  bool get tooLarge =>
      east - west > RoadLimits.maxBboxSpanDeg ||
      north - south > RoadLimits.maxBboxSpanDeg;

  /// `min_lng,min_lat,max_lng,max_lat`.
  String get query => '$west,$south,$east,$north';

  @override
  bool operator ==(Object other) =>
      other is RoadBounds &&
      other.west == west &&
      other.south == south &&
      other.east == east &&
      other.north == north;

  @override
  int get hashCode => Object.hash(west, south, east, north);

  @override
  String toString() => 'RoadBounds($query)';
}
