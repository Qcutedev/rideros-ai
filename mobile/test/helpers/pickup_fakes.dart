import 'dart:async';

import 'package:decimal/decimal.dart';

import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/network/paged_result.dart';
import 'package:rideros_ai/features/pickup/domain/pickup_models.dart';
import 'package:rideros_ai/features/pickup/domain/pickup_repository.dart';

// ---- JSON as the API sends it ----

Map<String, Object?> restaurantJson({
  String id = 'r-1',
  String name = 'POI-1',
  bool own = false,
  String? availability = 'sufficient',
  int? orders = 1267,
  Map<String, Object?>? location,
}) => {
  'id': id,
  'source': own ? 'user' : 'dataset_meituan',
  'name': name,
  'is_own': own,
  'supports_prediction': !own,
  'data_availability': own ? null : availability,
  'n_orders': own ? null : orders,
  'location': location,
  'created_at': '2026-11-09T13:30:33.539206Z',
};

Map<String, Object?> cellJson(int hour, {int orders = 0, String? median}) => {
  'hour': hour,
  'n_orders': orders,
  'median_min': median,
  'p25_min': null,
  'p75_min': null,
  'p90_min': null,
};

/// Weekday hours 10-21 have data (median 8 + (hour - 10)); weekend only 12.
Map<String, Object?> analyticsJson({
  Map<String, Object?>? restaurant,
  bool withOverall = true,
}) {
  final r = restaurant ?? restaurantJson();
  final own = r['is_own'] == true;
  return {
    'restaurant': r,
    'metric': 'order_to_pickup_minutes',
    'data_availability': own ? 'insufficient' : 'sufficient',
    'overall': own || !withOverall
        ? null
        : {
            'n_orders': 1267,
            'median_min': '10.433',
            'p25_min': '7.892',
            'p75_min': '13.992',
            'p90_min': '18.040',
            'peak_hour': 12,
          },
    'by_hour': {
      'weekday': [
        for (var h = 0; h < 24; h++)
          h >= 10 && h <= 21
              ? cellJson(h, orders: 40, median: '${8 + h - 10}.000')
              : cellJson(h),
      ],
      'weekend': [
        for (var h = 0; h < 24; h++)
          h == 12 ? cellJson(h, orders: 9, median: '9.500') : cellJson(h),
      ],
    },
    'min_orders_for_stats': 30,
    'dataset_version': own ? null : 'restaurant_stats/1.0.0',
    'acknowledgement': own
        ? null
        : 'This research was supported by data provided by Meituan.',
  };
}

Map<String, Object?> waitStatsJson({
  String id = 'r-1',
  int n = 0,
  String? median,
  String? p80,
  String confidence = 'insufficient',
}) => {
  'restaurant_id': id,
  'n': n,
  'median_minutes': median,
  'p80_minutes': p80,
  'confidence': confidence,
};

Map<String, Object?> predictionJson({
  String id = 'p-1',
  String restaurantId = 'r-1',
  String? name = 'POI-1',
  List<String> warnings = const ['foreign_dataset'],
  String availability = 'sufficient',
  double? coverage = 0.8,
  String requestedAt = '2026-11-10T07:07:00Z',
}) => {
  'id': id,
  'restaurant_id': restaurantId,
  'restaurant_name': name,
  'metric': 'order_to_pickup_minutes',
  'predicted_minutes': '11.43',
  'interval': {'low': '5.04', 'high': '19.99', 'nominal_coverage': coverage},
  'data_availability': availability,
  'warnings': warnings,
  'model_version': '1.0.0',
  'requested_at': requestedAt,
  'input_features': {'poi_id': 1},
  'disclaimer': 'Estimate of order-to-pickup time (server text).',
  'created_at': requestedAt,
};

Map<String, Object?> modelInfoJson() => {
  'name': 'pickup_o2p',
  'version': '1.0.0',
  'task': 'regression:order_to_pickup_min',
  'target': {'name': 'order_to_pickup_min'},
  'dataset': 'Meituan INFORMS TSL dataset @ 1f9b4288cee5 (546226 orders)',
  'domain': 'Meituan on-demand delivery, one Chinese city.',
  'trained_at': '2026-11-09T11:24:56Z',
  'test_metrics': {'model': 'xgboost', 'n': 64701, 'mae': 4.508763},
  'baseline_test_metrics': {'n': 64701, 'mae': 4.635922},
  'interval': {
    'method': 'split conformal',
    'nominal_coverage': 0.8,
    'test_coverage': 0.8162779,
    'test_mean_width_minutes': 14.948,
  },
  'limitations': ['Not food preparation time.'],
  'acknowledgement': 'This research was supported by data provided by Meituan.',
};

Map<String, Object?> logJson({
  String id = 'l-1',
  String restaurantId = 'r-1',
  String name = 'POI-1',
  String arrived = '2026-11-10T06:50:00Z',
  String picked = '2026-11-10T07:02:00Z',
  String wait = '12.00',
  String? notes,
}) => {
  'id': id,
  'restaurant_id': restaurantId,
  'restaurant_name': name,
  'arrived_at': arrived,
  'picked_up_at': picked,
  'wait_minutes': wait,
  'notes': notes,
  'created_at': picked,
};

Restaurant restaurant({
  String id = 'r-1',
  String name = 'POI-1',
  bool own = false,
  String? availability = 'sufficient',
}) => Restaurant.fromJson(
  restaurantJson(id: id, name: name, own: own, availability: availability),
);

// ---- scriptable repository ----

/// In-memory [PickupRepository]. Restaurants are filtered like the API (name
/// contains, source); lists page by [pageSize] with numeric cursors.
class FakePickupRepository implements PickupRepository {
  final restaurantItems = <Restaurant>[
    restaurant(),
    restaurant(id: 'r-2', name: 'POI-2', availability: 'limited'),
  ];
  final analyticsById = <String, RestaurantAnalytics>{};
  final waitById = <String, WaitStats>{};
  final predictionItems = <Prediction>[];
  final logItems = <PickupLog>[];
  int pageSize = 50;
  List<String> predictWarnings = const ['foreign_dataset'];

  Object? listError;
  Object? analyticsError;
  Object? waitError;
  Object? predictError;
  Object? modelError;
  Object? saveError;
  Completer<void>? saveGate;
  Completer<void>? predictGate;
  final calls = <String>[];
  PickupLogInput? lastLog;
  RestaurantInput? lastRestaurant;
  int _next = 1;

  PagedResult<T> _page<T>(List<T> all, String? cursor) {
    final offset = cursor == null ? 0 : int.parse(cursor);
    final page = all.skip(offset).take(pageSize).toList();
    final end = offset + page.length;
    return PagedResult(
      items: page,
      nextCursor: end < all.length ? '$end' : null,
    );
  }

  @override
  Future<PagedResult<Restaurant>> restaurants({
    String? query,
    RestaurantSourceFilter source = RestaurantSourceFilter.all,
    String? cursor,
  }) async {
    calls.add('restaurants:${query ?? '-'}:${source.name}:${cursor ?? '-'}');
    if (listError != null) throw listError!;
    final matching =
        [
          ...restaurantItems.where((r) => r.isOwn),
          ...restaurantItems.where((r) => !r.isOwn),
        ].where((r) {
          final q = query?.toLowerCase();
          final nameOk = q == null || r.name.toLowerCase().contains(q);
          final sourceOk = switch (source) {
            RestaurantSourceFilter.all => true,
            RestaurantSourceFilter.dataset => !r.isOwn,
            RestaurantSourceFilter.own => r.isOwn,
          };
          return nameOk && sourceOk;
        }).toList();
    return _page(matching, cursor);
  }

  @override
  Future<Restaurant> createRestaurant(RestaurantInput input) async {
    calls.add('createRestaurant');
    lastRestaurant = input;
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    final created = Restaurant(
      id: 'own-${_next++}',
      source: 'user',
      name: input.name,
      isOwn: true,
      supportsPrediction: false,
      location: input.location,
      createdAt: DateTime.utc(2026, 11, 10),
    );
    restaurantItems.insert(0, created);
    return created;
  }

  @override
  Future<RestaurantAnalytics> analytics(String restaurantId) async {
    calls.add('analytics:$restaurantId');
    if (analyticsError != null) throw analyticsError!;
    final known = analyticsById[restaurantId];
    if (known != null) return known;
    final r = restaurantItems.where((r) => r.id == restaurantId).firstOrNull;
    if (r == null) {
      throw const ApiFailure(statusCode: 404, code: 'restaurant_not_found');
    }
    return RestaurantAnalytics.fromJson(
      analyticsJson(
        restaurant: restaurantJson(id: r.id, name: r.name, own: r.isOwn),
      ),
    );
  }

  @override
  Future<WaitStats> waitStats(String restaurantId) async {
    calls.add('wait:$restaurantId');
    if (waitError != null) throw waitError!;
    return waitById[restaurantId] ??
        WaitStats.fromJson(waitStatsJson(id: restaurantId));
  }

  @override
  Future<Prediction> predict(String restaurantId) async {
    calls.add('predict:$restaurantId');
    await predictGate?.future;
    if (predictError != null) throw predictError!;
    final p = Prediction.fromJson(
      predictionJson(
        id: 'p-${_next++}',
        restaurantId: restaurantId,
        warnings: predictWarnings,
      ),
    );
    predictionItems.insert(0, p);
    return p;
  }

  @override
  Future<PagedResult<Prediction>> predictions({String? cursor}) async {
    calls.add('predictions:${cursor ?? '-'}');
    if (listError != null) throw listError!;
    return _page(predictionItems, cursor);
  }

  @override
  Future<ModelInfo> modelInfo() async {
    calls.add('model');
    if (modelError != null) throw modelError!;
    return ModelInfo.fromJson(modelInfoJson());
  }

  @override
  Future<PagedResult<PickupLog>> logs({String? cursor}) async {
    calls.add('logs:${cursor ?? '-'}');
    if (listError != null) throw listError!;
    return _page(logItems, cursor);
  }

  @override
  Future<PickupLog> createLog(PickupLogInput input) async {
    calls.add('createLog');
    lastLog = input;
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    final log = PickupLog(
      id: 'l-${_next++}',
      restaurantId: input.restaurantId,
      restaurantName: input.restaurantId,
      arrivedAt: input.arrivedAt,
      pickedUpAt: input.pickedUpAt,
      waitMinutes: Decimal.fromInt(
        input.pickedUpAt.difference(input.arrivedAt).inMinutes,
      ),
      notes: input.notes,
      createdAt: input.pickedUpAt,
    );
    logItems.insert(0, log);
    return log;
  }

  @override
  Future<void> deleteLog(String id) async {
    calls.add('deleteLog:$id');
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    logItems.removeWhere((l) => l.id == id);
  }
}
