import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FakeHandler = FutureOr<ResponseBody> Function(RequestOptions options);

/// Answers dio requests in-process; records every request it sees.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  FakeHandler handler;
  final List<RequestOptions> requests = [];

  List<String> get paths => [for (final r in requests) r.path];

  int count(String path) => requests.where((r) => r.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(
  int status, [
  Object? body,
  Map<String, List<String>> headers = const {},
]) => ResponseBody.fromString(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
    ...headers,
  },
);

ResponseBody apiError(
  int status,
  String code, {
  List<Object> details = const [],
  Map<String, List<String>> headers = const {},
}) => json(status, {
  'error': {'code': code, 'message': code, 'details': details},
}, headers);

Never offline(RequestOptions options) => throw DioException.connectionError(
  requestOptions: options,
  reason: 'offline (test)',
);

Map<String, Object?> tokenJson({
  String access = 'access-1',
  String refresh = 'refresh-token-0000000001',
}) => {
  'access_token': access,
  'refresh_token': refresh,
  'token_type': 'bearer',
  'expires_in': 900,
  'refresh_expires_at': '2026-12-10T00:00:00Z',
};

Map<String, Object?> userJson({
  String name = 'Somchai',
  String email = 'rider@example.com',
}) => {
  'id': '00000000-0000-0000-0000-000000000001',
  'email': email,
  'display_name': name,
  'role': 'rider',
  'created_at': '2026-11-10T03:00:00Z',
};

Map<String, Object?> profileJson({bool configured = false}) => {
  'vehicle_type': configured ? 'motorcycle' : null,
  'fuel_km_per_liter': configured ? '45.50' : null,
  'fuel_price_per_liter': configured ? '38.00' : null,
  'depreciation_per_km': null,
  'timezone': 'Asia/Bangkok',
  'currency': 'THB',
  'is_configured': configured,
  'updated_at': configured ? '2026-11-10T03:00:00Z' : null,
};
