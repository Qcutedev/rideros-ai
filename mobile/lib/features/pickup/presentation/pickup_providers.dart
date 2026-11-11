import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paged_result.dart';
import '../../../core/presentation/paged_list.dart';
import '../../../core/presentation/submit_notifier.dart';
import '../data/pickup_repository_impl.dart';
import '../domain/pickup_models.dart';
import '../domain/pickup_repository.dart';

/// Bumped after every create/delete of a restaurant or pickup log. Lists and the
/// rider's wait statistics watch it, so they reload with the server's figures.
final pickupDataRevisionProvider = NotifierProvider<PickupDataRevision, int>(
  PickupDataRevision.new,
);

class PickupDataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

// ---- restaurant search ----

/// Search text (trimmed; empty = no filter) and source filter.
class RestaurantQuery {
  const RestaurantQuery({
    this.text = '',
    this.source = RestaurantSourceFilter.all,
  });

  final String text;
  final RestaurantSourceFilter source;

  @override
  bool operator ==(Object other) =>
      other is RestaurantQuery && other.text == text && other.source == source;

  @override
  int get hashCode => Object.hash(text, source);
}

class RestaurantListNotifier extends PagedListNotifier<Restaurant> {
  RestaurantListNotifier(this.query);

  final RestaurantQuery query;

  @override
  void watchDependencies() => ref.watch(pickupDataRevisionProvider);

  @override
  Future<PagedResult<Restaurant>> fetchPage(String? cursor) => ref
      .read(pickupRepositoryProvider)
      .restaurants(
        query: query.text.isEmpty ? null : query.text,
        source: query.source,
        cursor: cursor,
      );
}

final restaurantListProvider = AsyncNotifierProvider.autoDispose
    .family<RestaurantListNotifier, PagedState<Restaurant>, RestaurantQuery>(
      RestaurantListNotifier.new,
    );

// ---- restaurant details ----

final restaurantAnalyticsProvider = FutureProvider.autoDispose
    .family<RestaurantAnalytics, String>(
      (ref, id) => ref.watch(pickupRepositoryProvider).analytics(id),
    );

/// Reloads after a log is added or deleted.
final waitStatsProvider = FutureProvider.autoDispose.family<WaitStats, String>((
  ref,
  id,
) {
  ref.watch(pickupDataRevisionProvider);
  return ref.watch(pickupRepositoryProvider).waitStats(id);
});

/// One prediction per screen: `POST /pickup/predictions` for an order placed now.
/// Invalidating it (retry, "predict again") asks the model again.
final predictionProvider = FutureProvider.autoDispose
    .family<Prediction, String>(
      (ref, restaurantId) =>
          ref.watch(pickupRepositoryProvider).predict(restaurantId),
    );

final modelInfoProvider = FutureProvider.autoDispose<ModelInfo>(
  (ref) => ref.watch(pickupRepositoryProvider).modelInfo(),
);

// ---- history and logs ----

class PredictionHistoryNotifier extends PagedListNotifier<Prediction> {
  @override
  Future<PagedResult<Prediction>> fetchPage(String? cursor) =>
      ref.read(pickupRepositoryProvider).predictions(cursor: cursor);
}

final predictionHistoryProvider =
    AsyncNotifierProvider.autoDispose<
      PredictionHistoryNotifier,
      PagedState<Prediction>
    >(PredictionHistoryNotifier.new);

class PickupLogListNotifier extends PagedListNotifier<PickupLog> {
  @override
  void watchDependencies() => ref.watch(pickupDataRevisionProvider);

  @override
  Future<PagedResult<PickupLog>> fetchPage(String? cursor) =>
      ref.read(pickupRepositoryProvider).logs(cursor: cursor);
}

final pickupLogListProvider =
    AsyncNotifierProvider.autoDispose<
      PickupLogListNotifier,
      PagedState<PickupLog>
    >(PickupLogListNotifier.new);

// ---- forms ----

/// Create a pickup log or an own restaurant, delete a log. Success bumps
/// [pickupDataRevisionProvider].
class PickupFormController extends SubmitNotifier {
  Future<bool> createLog(PickupLogInput input) =>
      _save((repo) => repo.createLog(input));

  Future<bool> createRestaurant(RestaurantInput input) =>
      _save((repo) => repo.createRestaurant(input));

  Future<bool> deleteLog(String id) => _save((repo) => repo.deleteLog(id));

  /// Reads what it needs before awaiting: the screen may close while the
  /// request runs, disposing this notifier, and the revision bump that
  /// refreshes the lists must still happen.
  Future<bool> _save(Future<void> Function(PickupRepository repo) action) {
    final repo = ref.read(pickupRepositoryProvider);
    final revision = ref.read(pickupDataRevisionProvider.notifier);
    return run(() async {
      await action(repo);
      revision.bump();
    });
  }
}

final pickupLogFormProvider =
    NotifierProvider.autoDispose<PickupFormController, AsyncValue<void>>(
      PickupFormController.new,
    );

final ownRestaurantFormProvider =
    NotifierProvider.autoDispose<PickupFormController, AsyncValue<void>>(
      PickupFormController.new,
    );

/// Deleting from the log list (one at a time).
final pickupLogDeleteProvider =
    NotifierProvider.autoDispose<PickupFormController, AsyncValue<void>>(
      PickupFormController.new,
    );
