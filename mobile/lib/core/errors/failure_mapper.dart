import 'package:dio/dio.dart';

import 'app_failure.dart';

/// Converts anything thrown by dio (or the data layer) into an [AppFailure].
AppFailure mapToFailure(Object error) {
  if (error is AppFailure) return error;
  if (error is DioException) return _fromDio(error);
  return UnknownFailure(error);
}

AppFailure _fromDio(DioException e) {
  final inner = e.error;
  if (inner is AppFailure) return inner;

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const NetworkFailure(isTimeout: true);
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      return _fromResponse(e.response!);
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      return UnknownFailure(inner ?? e.message);
  }
}

AppFailure _fromResponse(Response<dynamic> response) {
  final status = response.statusCode ?? 0;
  final envelope = _envelope(response.data);
  final code = envelope?.code ?? _fallbackCode(status);

  if (status == 429 || code == ApiErrorCode.rateLimited) {
    return RateLimitedFailure(retryAfter: _retryAfter(response.headers));
  }
  return ApiFailure(
    statusCode: status,
    code: code,
    message: envelope?.message ?? '',
    fieldErrors: envelope?.fieldErrors ?? const {},
    details: envelope?.details ?? const [],
  );
}

class _Envelope {
  const _Envelope(this.code, this.message, this.fieldErrors, this.details);

  final String code;
  final String message;
  final Map<String, String> fieldErrors;
  final List<Map<String, Object?>> details;
}

_Envelope? _envelope(Object? data) {
  if (data is! Map) return null;
  final error = data['error'];
  if (error is! Map) return null;
  final code = error['code'];
  if (code is! String || code.isEmpty) return null;
  final message = error['message'];
  final fields = <String, String>{};
  final objects = <Map<String, Object?>>[];
  final details = error['details'];
  if (details is List) {
    for (final item in details) {
      if (item is! Map) continue;
      objects.add({for (final e in item.entries) e.key.toString(): e.value});
      final loc = item['loc'];
      final msg = item['msg'];
      if (loc is List && loc.isNotEmpty && msg is String) {
        fields.putIfAbsent(loc.last.toString(), () => msg);
      }
    }
  }
  return _Envelope(code, message is String ? message : '', fields, objects);
}

Duration? _retryAfter(Headers headers) {
  final raw = headers.value('retry-after');
  final seconds = raw == null ? null : int.tryParse(raw.trim());
  if (seconds == null || seconds < 0) return null;
  return Duration(seconds: seconds);
}

String _fallbackCode(int status) => switch (status) {
  400 => 'bad_request',
  401 => 'unauthorized',
  403 => 'forbidden',
  404 => 'not_found',
  409 => 'conflict',
  422 => ApiErrorCode.validationError,
  429 => ApiErrorCode.rateLimited,
  >= 500 => ApiErrorCode.internalError,
  _ => 'http_error',
};
