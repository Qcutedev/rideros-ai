import 'dart:async';
import 'dart:typed_data';

import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/network/paged_result.dart';
import 'package:rideros_ai/features/road/data/device_services.dart';
import 'package:rideros_ai/features/road/domain/road_models.dart';
import 'package:rideros_ai/features/road/domain/road_repository.dart';

import 'profit_fakes.dart';

/// [testNow] minus [ago], as the API sends it (UTC ISO).
String isoAgo(Duration ago) =>
    testNow().subtract(ago).toUtc().toIso8601String();

// ---- JSON as the API sends it ----

Map<String, Object?> incidentJson({
  String id = 'i-1',
  String category = 'flooding',
  String status = 'unverified',
  double lat = 13.7563,
  double lng = 100.5018,
  Duration lastAgo = const Duration(minutes: 5),
  int reports = 1,
  int reporters = 1,
  int cleared = 0,
  double? distance,
}) => {
  'id': id,
  'category': category,
  'status': status,
  'location': {'lat': lat, 'lng': lng},
  'first_reported_at': isoAgo(const Duration(hours: 1)),
  'last_reported_at': isoAgo(lastAgo),
  'report_count': reports,
  'distinct_reporters': reporters,
  'cleared_count': cleared,
  'expires_at': isoAgo(const Duration(hours: -11)),
  'distance_m': distance,
};

Map<String, Object?> ownReportJson({
  String id = 'rep-1',
  String incidentId = 'i-1',
  String category = 'flooding',
  String? description = 'น้ำสูงครึ่งล้อ',
  bool image = false,
  String aiStatus = 'none',
  String? aiLabel,
  String? aiConfidence,
  String incidentStatus = 'unverified',
  Duration createdAgo = const Duration(hours: 1),
}) => {
  'id': id,
  'incident_id': incidentId,
  'category': category,
  'description': description,
  'location': {'lat': 13.7563, 'lng': 100.5018},
  'has_image': image,
  'ai_status': aiStatus,
  'ai_label': aiLabel,
  'ai_confidence': aiConfidence,
  'created_at': isoAgo(createdAgo),
  'incident_status': incidentStatus,
};

Map<String, Object?> detailJson({
  Map<String, Object?>? incident,
  Map<String, Object?>? myReport,
  Map<String, Object?>? myConfirmation,
}) => {
  ...incident ?? incidentJson(),
  'my_report': myReport,
  'my_confirmation': myConfirmation,
  'notice': 'Reported by riders (server text).',
};

Incident testIncident({
  String id = 'i-1',
  String category = 'flooding',
  String status = 'unverified',
  double? distance,
  int reporters = 1,
}) => Incident.fromJson(
  incidentJson(
    id: id,
    category: category,
    status: status,
    distance: distance,
    reporters: reporters,
  ),
);

OwnReport ownReport({
  String id = 'rep-1',
  String incidentId = 'i-1',
  bool image = false,
  String aiStatus = 'none',
  String? aiLabel,
  String? aiConfidence,
  String? description = 'น้ำสูงครึ่งล้อ',
  Duration createdAgo = const Duration(hours: 1),
}) => OwnReport.fromJson(
  ownReportJson(
    id: id,
    incidentId: incidentId,
    image: image,
    aiStatus: aiStatus,
    aiLabel: aiLabel,
    aiConfidence: aiConfidence,
    description: description,
    createdAgo: createdAgo,
  ),
);

const testPoint = RoadPoint(lat: 13.7563, lng: 100.5018);

// ---- scriptable fakes ----

/// In-memory [RoadRepository]. Every incident in [incidents] is "in view" and
/// "nearby"; details default to the incident without the rider's report.
class FakeRoadRepository implements RoadRepository {
  final incidents = <Incident>[testIncident()];
  final details = <String, IncidentDetail>{};
  final reports = <OwnReport>[];
  bool truncated = false;
  bool merged = false;
  int pageSize = 50;
  Uint8List image = Uint8List.fromList(const [0xFF, 0xD8, 0xFF]);

  Object? listError;
  Object? detailError;
  Object? createError;
  Object? confirmError;
  Object? imageError;
  Completer<void>? createGate;
  Completer<void>? confirmGate;
  Completer<void>? detailGate;
  final calls = <String>[];
  NewReport? lastReport;
  RoadBounds? lastBounds;
  ({String id, bool stillPresent})? lastConfirm;

  @override
  Future<ReportCreated> createReport(NewReport report) async {
    calls.add('create');
    lastReport = report;
    await createGate?.future;
    if (createError != null) throw createError!;
    final created = testIncident(
      id: 'i-new',
      category: report.category.apiValue,
    );
    return ReportCreated(
      reportId: 'rep-new',
      incidentId: created.id,
      merged: merged,
      status: created.status,
      incident: created,
    );
  }

  @override
  Future<PagedResult<OwnReport>> myReports({String? cursor}) async {
    calls.add('myReports:${cursor ?? '-'}');
    if (listError != null) throw listError!;
    final offset = cursor == null ? 0 : int.parse(cursor);
    final page = reports.skip(offset).take(pageSize).toList();
    final end = offset + page.length;
    return PagedResult(
      items: page,
      nextCursor: end < reports.length ? '$end' : null,
    );
  }

  @override
  Future<Uint8List> reportImage(String reportId) async {
    calls.add('image:$reportId');
    if (imageError != null) throw imageError!;
    return image;
  }

  @override
  Future<IncidentList> incidentsIn(RoadBounds bounds) async {
    calls.add('bbox');
    lastBounds = bounds;
    if (listError != null) throw listError!;
    return IncidentList(items: [...incidents], truncated: truncated);
  }

  @override
  Future<IncidentList> nearby(
    RoadPoint point, {
    int radiusM = RoadLimits.nearbyRadiusM,
  }) async {
    calls.add('nearby:${point.lat},${point.lng}:$radiusM');
    if (listError != null) throw listError!;
    return IncidentList(items: [...incidents], truncated: truncated);
  }

  IncidentDetail _detail(String id) {
    final known = details[id];
    if (known != null) return known;
    final i = incidents.where((i) => i.id == id).firstOrNull;
    if (i == null) {
      throw const ApiFailure(statusCode: 404, code: 'incident_not_found');
    }
    return IncidentDetail(incident: i);
  }

  @override
  Future<IncidentDetail> incident(String id) async {
    calls.add('detail:$id');
    await detailGate?.future;
    if (detailError != null) throw detailError!;
    return _detail(id);
  }

  @override
  Future<IncidentDetail> confirm(
    String id, {
    required bool stillPresent,
  }) async {
    calls.add('confirm:$id:$stillPresent');
    lastConfirm = (id: id, stillPresent: stillPresent);
    await confirmGate?.future;
    if (confirmError != null) throw confirmError!;
    final before = _detail(id);
    final i = before.incident;
    final updated = IncidentDetail(
      incident: stillPresent
          ? i.copyWith(distinctReporters: i.distinctReporters + 1)
          : i.copyWith(clearedCount: i.clearedCount + 1),
      myReport: before.myReport,
      myConfirmation: MyConfirmation(
        stillPresent: stillPresent,
        createdAt: testNow(),
      ),
    );
    details[id] = updated;
    return updated;
  }
}

class FakeLocationService implements LocationService {
  FakeLocationService([this.result = const LocationFound(testPoint)]);

  LocationResult result;
  Completer<void>? gate;
  int calls = 0;
  int appSettings = 0;
  int locationSettings = 0;

  @override
  Future<LocationResult> current() async {
    calls++;
    await gate?.future;
    return result;
  }

  @override
  Future<void> openAppSettings() async => appSettings++;

  @override
  Future<void> openLocationSettings() async => locationSettings++;
}

class FakePhotoPicker implements PhotoPicker {
  ReportPhoto? next = ReportPhoto(
    bytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xE0]),
    name: 'flood.jpg',
  );
  Object? error;
  final sources = <PhotoSource>[];

  @override
  Future<ReportPhoto?> pick(PhotoSource source) async {
    sources.add(source);
    if (error != null) throw error!;
    return next;
  }
}

/// The RoadContext fakes together (like [ProfitFakes]).
class RoadFakes {
  RoadFakes({LocationResult location = const LocationFound(testPoint)})
    : location = FakeLocationService(location);

  final repo = FakeRoadRepository();
  final FakeLocationService location;
  final photos = FakePhotoPicker();
}
