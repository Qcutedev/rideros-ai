import '../../../core/network/paged_result.dart';
import 'pickup_models.dart';

/// `/pickup/*`. Every method throws an `AppFailure` on error; another rider's
/// restaurant or log is a 404.
abstract interface class PickupRepository {
  /// Own restaurants first, then dataset ones, by name. [query] = name contains.
  Future<PagedResult<Restaurant>> restaurants({
    String? query,
    RestaurantSourceFilter source = RestaurantSourceFilter.all,
    String? cursor,
  });

  Future<Restaurant> createRestaurant(RestaurantInput input);

  Future<RestaurantAnalytics> analytics(String restaurantId);

  Future<WaitStats> waitStats(String restaurantId);

  /// Order placed now (the server reads the time in the rider's zone).
  /// 400 `restaurant_not_supported` for own restaurants, 503 `model_unavailable`.
  Future<Prediction> predict(String restaurantId);

  /// Newest first.
  Future<PagedResult<Prediction>> predictions({String? cursor});

  Future<ModelInfo> modelInfo();

  /// Newest arrival first.
  Future<PagedResult<PickupLog>> logs({String? cursor});

  Future<PickupLog> createLog(PickupLogInput input);

  Future<void> deleteLog(String id);
}
