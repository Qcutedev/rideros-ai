import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_guard.dart';
import '../../../core/network/paged_result.dart';
import '../domain/shift_models.dart';
import '../domain/shift_repository.dart';

final shiftRepositoryProvider = Provider<ShiftRepository>(
  (ref) => ShiftRepositoryImpl(ref.watch(apiClientProvider)),
);

class ShiftRepositoryImpl implements ShiftRepository {
  ShiftRepositoryImpl(this._dio);

  final Dio _dio;

  static const _base = '/shift-scenarios';

  Future<ShiftScenario> _send(
    String method,
    String path, [
    Object? body,
  ]) async {
    final response = await _dio.request<Map<String, dynamic>>(
      path,
      data: body,
      options: Options(method: method),
    );
    return ShiftScenario.fromJson(response.data!);
  }

  @override
  Future<PagedResult<ShiftScenario>> list({String? cursor}) =>
      guardApi(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          _base,
          queryParameters: {'cursor': ?cursor},
        );
        return PagedResult.fromJson(response.data!, ShiftScenario.fromJson);
      });

  @override
  Future<ShiftScenario> get(String id) =>
      guardApi(() => _send('GET', '$_base/$id'));

  @override
  Future<ShiftScenario> create(ShiftScenarioInput input) =>
      guardApi(() => _send('POST', _base, input.toJson()));

  @override
  Future<ShiftScenario> update(String id, ShiftScenarioInput input) =>
      guardApi(() => _send('PATCH', '$_base/$id', input.toJson()));

  @override
  Future<ShiftScenario> linkWorkSession(String id, String? workSessionId) =>
      guardApi(
        () => _send('PATCH', '$_base/$id', {
          'actual_work_session_id': workSessionId,
        }),
      );

  @override
  Future<ShiftScenario> reEstimate(String id) =>
      guardApi(() => _send('POST', '$_base/$id/estimate'));

  @override
  Future<void> delete(String id) => guardApi(() async {
    await _dio.delete<void>('$_base/$id');
  });

  @override
  Future<ShiftComparison> compare(List<String> ids) => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/compare',
      data: {'ids': ids},
    );
    return ShiftComparison.fromJson(response.data!);
  });
}
