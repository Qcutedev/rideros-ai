import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_guard.dart';
import '../../../core/network/paged_result.dart';
import '../domain/pickup_models.dart';
import '../domain/pickup_repository.dart';

final pickupRepositoryProvider = Provider<PickupRepository>(
  (ref) => PickupRepositoryImpl(ref.watch(apiClientProvider)),
);

class PickupRepositoryImpl implements PickupRepository {
  PickupRepositoryImpl(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> _post(String path, Object body) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: body);
    return response.data!;
  }

  @override
  Future<PagedResult<Restaurant>> restaurants({
    String? query,
    RestaurantSourceFilter source = RestaurantSourceFilter.all,
    String? cursor,
  }) => guardApi(() async {
    final json = await _get('/pickup/restaurants', {
      'q': ?query,
      'source': ?source.query,
      'cursor': ?cursor,
    });
    return PagedResult.fromJson(json, Restaurant.fromJson);
  });

  @override
  Future<Restaurant> createRestaurant(RestaurantInput input) => guardApi(
    () async =>
        Restaurant.fromJson(await _post('/pickup/restaurants', input.toJson())),
  );

  @override
  Future<RestaurantAnalytics> analytics(String restaurantId) => guardApi(
    () async => RestaurantAnalytics.fromJson(
      await _get('/pickup/restaurants/$restaurantId/analytics'),
    ),
  );

  @override
  Future<WaitStats> waitStats(String restaurantId) => guardApi(
    () async => WaitStats.fromJson(
      await _get('/pickup/restaurants/$restaurantId/wait-stats'),
    ),
  );

  @override
  Future<Prediction> predict(String restaurantId) => guardApi(
    () async => Prediction.fromJson(
      await _post('/pickup/predictions', {'restaurant_id': restaurantId}),
    ),
  );

  @override
  Future<PagedResult<Prediction>> predictions({String? cursor}) =>
      guardApi(() async {
        final json = await _get('/pickup/predictions', {'cursor': ?cursor});
        return PagedResult.fromJson(json, Prediction.fromJson);
      });

  @override
  Future<ModelInfo> modelInfo() =>
      guardApi(() async => ModelInfo.fromJson(await _get('/pickup/model')));

  @override
  Future<PagedResult<PickupLog>> logs({String? cursor}) => guardApi(() async {
    final json = await _get('/pickup/logs', {'cursor': ?cursor});
    return PagedResult.fromJson(json, PickupLog.fromJson);
  });

  @override
  Future<PickupLog> createLog(PickupLogInput input) => guardApi(
    () async => PickupLog.fromJson(await _post('/pickup/logs', input.toJson())),
  );

  @override
  Future<void> deleteLog(String id) => guardApi(() async {
    await _dio.delete<void>('/pickup/logs/$id');
  });
}
