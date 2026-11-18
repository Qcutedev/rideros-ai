import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paged_result.dart';
import '../../../core/presentation/paged_list.dart';
import '../../../core/presentation/submit_notifier.dart';
import '../../../core/utils/clock.dart';
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

/// How often an open detail asks again while the rider's photo is still being
/// classified (`ai_status` `pending`).
const aiPollInterval = Duration(seconds: 3);

/// Polling stops this long after the report was sent; pull to refresh after
/// that. (The server reads a classification still pending after 10 minutes as
/// failed.)
const aiPollWindow = Duration(minutes: 2);

/// The incident detail. While the rider's own photo is `pending`, it asks the
/// server again every [aiPollInterval] until the suggestion is `done` or
/// `failed`, so the screen updates without a pull to refresh. A failed poll
/// keeps the last answer on screen and tries again.
final incidentDetailProvider = StreamProvider.autoDispose
    .family<IncidentDetail, String>((ref, id) async* {
      ref.watch(roadDataRevisionProvider);
      final repo = ref.watch(roadRepositoryProvider);
      final now = ref.watch(clockProvider);
      var detail = await repo.incident(id);
      yield detail;
      while (ref.mounted && _classifying(detail, now())) {
        await _delay(ref, aiPollInterval);
        try {
          detail = await repo.incident(id);
        } on Object {
          continue;
        }
        yield detail;
      }
    });

bool _classifying(IncidentDetail detail, DateTime now) {
  final report = detail.myReport;
  return report != null &&
      report.aiStatus == AiStatus.pending &&
      now.difference(report.createdAt) < aiPollWindow;
}

/// A wait that is cancelled with the provider (no timer left behind).
Future<void> _delay(Ref ref, Duration duration) {
  final done = Completer<void>();
  final timer = Timer(duration, done.complete);
  ref.onDispose(timer.cancel);
  return done.future;
}

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

  /// Reads what it needs before awaiting: the provider may be disposed by then.
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
