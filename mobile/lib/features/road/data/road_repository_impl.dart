import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_guard.dart';
import '../../../core/network/paged_result.dart';
import '../domain/road_models.dart';
import '../domain/road_repository.dart';

final roadRepositoryProvider = Provider<RoadRepository>(
  (ref) => RoadRepositoryImpl(ref.watch(apiClientProvider)),
);

class RoadRepositoryImpl implements RoadRepository {
  RoadRepositoryImpl(this._dio);

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

  @override
  Future<ReportCreated> createReport(NewReport report) => guardApi(() async {
    final photo = report.photo;
    final form = FormData.fromMap({
      'category': report.category.apiValue,
      'lat': report.location.lat.toString(),
      'lng': report.location.lng.toString(),
      'description': ?report.description,
      if (photo != null)
        'image': MultipartFile.fromBytes(photo.bytes, filename: photo.name),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/road/reports',
      data: form,
    );
    return ReportCreated.fromJson(response.data!);
  });

  @override
  Future<PagedResult<OwnReport>> myReports({String? cursor}) =>
      guardApi(() async {
        final json = await _get('/road/reports', {'cursor': ?cursor});
        return PagedResult.fromJson(json, OwnReport.fromJson);
      });

  @override
  Future<Uint8List> reportImage(String reportId) => guardApi(() async {
    final response = await _dio.get<List<int>>(
      '/road/reports/$reportId/image',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': 'image/jpeg'},
      ),
    );
    return Uint8List.fromList(response.data!);
  });

  @override
  Future<IncidentList> incidentsIn(RoadBounds bounds) => guardApi(
    () async => IncidentList.fromJson(
      await _get('/road/incidents', {'bbox': bounds.query}),
    ),
  );

  @override
  Future<IncidentList> nearby(
    RoadPoint point, {
    int radiusM = RoadLimits.nearbyRadiusM,
  }) => guardApi(
    () async => IncidentList.fromJson(
      await _get('/road/incidents/nearby', {
        'lat': point.lat,
        'lng': point.lng,
        'radius_m': radiusM,
      }),
    ),
  );

  @override
  Future<IncidentDetail> incident(String id) => guardApi(
    () async => IncidentDetail.fromJson(await _get('/road/incidents/$id')),
  );

  @override
  Future<IncidentDetail> confirm(String id, {required bool stillPresent}) =>
      guardApi(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/road/incidents/$id/confirmations',
          data: {'still_present': stillPresent},
        );
        return IncidentDetail.fromJson(response.data!);
      });
}
