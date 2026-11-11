import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_guard.dart';
import '../domain/rider_profile.dart';
import '../domain/rider_profile_repository.dart';

final riderProfileRepositoryProvider = Provider<RiderProfileRepository>(
  (ref) => RiderProfileRepositoryImpl(ref.watch(apiClientProvider)),
);

class RiderProfileRepositoryImpl implements RiderProfileRepository {
  RiderProfileRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<RiderProfile> fetch() => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>('/me/rider-profile');
    return RiderProfile.fromJson(response.data!);
  });

  @override
  Future<RiderProfile> save(RiderProfileInput input) => guardApi(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/me/rider-profile',
      data: input.toJson(),
    );
    return RiderProfile.fromJson(response.data!);
  });
}
