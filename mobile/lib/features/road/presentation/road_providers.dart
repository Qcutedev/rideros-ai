import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paged_result.dart';
import '../../../core/presentation/paged_list.dart';
import '../../../core/presentation/submit_notifier.dart';
import '../data/device_services.dart';
import '../data/road_repository_impl.dart';
import '../domain/road_models.dart';

/// Bumped after a report or a confirmation. The map, the nearby list, incident
/// details and "my reports" watch it, so they show the server's new figures.
final roadDataRevisionProvider = NotifierProvider<RoadDataRevision, int>(
  RoadDataRevision.new,
);

class RoadDataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// The rider's position, asked once per visit to the RoadContext screens.
/// Invalidate it to ask again (e.g. after the rider allowed location).
final currentLocationProvider = FutureProvider.autoDispose<LocationResult>(
  (ref) => ref.watch(locationServiceProvider).current(),
);

final incidentsInBoundsProvider = FutureProvider.autoDispose
    .family<IncidentList, RoadBounds>((ref, bounds) {
      ref.watch(roadDataRevisionProvider);
      return ref.watch(roadRepositoryProvider).incidentsIn(bounds);
    });

final nearbyIncidentsProvider = FutureProvider.autoDispose
    .family<IncidentList, RoadPoint>((ref, point) {
      ref.watch(roadDataRevisionProvider);
      return ref.watch(roadRepositoryProvider).nearby(point);
    });

final incidentDetailProvider = FutureProvider.autoDispose
    .family<IncidentDetail, String>((ref, id) {
      ref.watch(roadDataRevisionProvider);
      return ref.watch(roadRepositoryProvider).incident(id);
    });

/// Photos never change, so they are kept while the app runs.
final reportImageProvider = FutureProvider.family<Uint8List, String>(
  (ref, reportId) => ref.watch(roadRepositoryProvider).reportImage(reportId),
);

class MyReportsNotifier extends PagedListNotifier<OwnReport> {
  @override
  void watchDependencies() => ref.watch(roadDataRevisionProvider);

  @override
  Future<PagedResult<OwnReport>> fetchPage(String? cursor) =>
      ref.read(roadRepositoryProvider).myReports(cursor: cursor);
}

final myReportsProvider =
    AsyncNotifierProvider.autoDispose<MyReportsNotifier, PagedState<OwnReport>>(
      MyReportsNotifier.new,
    );

/// Sends a report. [created] holds the server's answer after a success.
class ReportFormController extends SubmitNotifier {
  ReportCreated? created;

  /// Reads what it needs before awaiting (see `PickupFormController._save`).
  Future<bool> submit(NewReport report) {
    final repo = ref.read(roadRepositoryProvider);
    final revision = ref.read(roadDataRevisionProvider.notifier);
    return run(() async {
      created = await repo.createReport(report);
      revision.bump();
    });
  }
}

final reportFormProvider =
    NotifierProvider.autoDispose<ReportFormController, AsyncValue<void>>(
      ReportFormController.new,
    );

/// "Still there" / "gone" on an incident's detail screen.
class ConfirmationController extends SubmitNotifier {
  ConfirmationController(this.incidentId);

  final String incidentId;

  Future<bool> answer({required bool stillPresent}) {
    final repo = ref.read(roadRepositoryProvider);
    final revision = ref.read(roadDataRevisionProvider.notifier);
    return run(() async {
      await repo.confirm(incidentId, stillPresent: stillPresent);
      revision.bump();
    });
  }
}

final confirmationProvider = NotifierProvider.autoDispose
    .family<ConfirmationController, AsyncValue<void>, String>(
      ConfirmationController.new,
    );
