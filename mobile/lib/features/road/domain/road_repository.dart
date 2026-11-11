import 'dart:typed_data';

import '../../../core/network/paged_result.dart';
import 'road_models.dart';

/// `/road/*`. Every method throws an `AppFailure` on error.
abstract interface class RoadRepository {
  /// 409 `already_reported` (detail `incident_id`) when this report would join
  /// an incident the rider already reported; 413 `image_too_large`,
  /// 415 `unsupported_image`, 503 `image_storage_unavailable`.
  Future<ReportCreated> createReport(NewReport report);

  /// The rider's own reports, newest first.
  Future<PagedResult<OwnReport>> myReports({String? cursor});

  /// JPEG of one of the rider's own reports.
  Future<Uint8List> reportImage(String reportId);

  /// Open incidents in [bounds], newest report first (at most 300).
  Future<IncidentList> incidentsIn(RoadBounds bounds);

  /// Open incidents within [radiusM] of [point], closest first (at most 100).
  Future<IncidentList> nearby(
    RoadPoint point, {
    int radiusM = RoadLimits.nearbyRadiusM,
  });

  Future<IncidentDetail> incident(String id);

  /// "Still there" (`true`) or "gone" (`false`); replaces the rider's previous
  /// answer. 409 `incident_closed` once the incident is no longer open.
  Future<IncidentDetail> confirm(String id, {required bool stillPresent});
}
