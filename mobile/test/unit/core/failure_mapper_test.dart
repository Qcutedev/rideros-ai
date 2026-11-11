import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/errors/failure_mapper.dart';

DioException _bad(
  int status,
  Object? data, {
  Map<String, List<String>> headers = const {},
}) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: data,
      headers: Headers.fromMap(headers),
    ),
  );
}

Map<String, Object?> _envelope(
  String code, [
  List<Object> details = const [],
]) => {
  'error': {'code': code, 'message': 'msg', 'details': details},
};

void main() {
  group('mapToFailure', () {
    test('reads code and message from the API envelope', () {
      final failure = mapToFailure(_bad(409, _envelope('email_taken')));
      expect(
        failure,
        isA<ApiFailure>()
            .having((f) => f.statusCode, 'status', 409)
            .having((f) => f.code, 'code', 'email_taken')
            .having((f) => f.message, 'message', 'msg'),
      );
    });

    test('keys 422 details by the last loc element', () {
      final failure = mapToFailure(
        _bad(
          422,
          _envelope('validation_error', [
            {
              'loc': ['body', 'email'],
              'msg': 'not an email',
              'type': 'value_error',
            },
            {
              'loc': ['body', 'email'],
              'msg': 'second message ignored',
              'type': 'x',
            },
            {'loc': <Object>[], 'msg': 'no loc', 'type': 'x'},
          ]),
        ),
      );
      expect(failure, isA<ApiFailure>());
      expect((failure as ApiFailure).fieldErrors, {'email': 'not an email'});
    });

    test('429 becomes RateLimitedFailure with Retry-After', () {
      final failure = mapToFailure(
        _bad(
          429,
          _envelope('rate_limited'),
          headers: {
            'retry-after': ['42'],
          },
        ),
      );
      expect(
        failure,
        isA<RateLimitedFailure>().having(
          (f) => f.retryAfter,
          'retryAfter',
          const Duration(seconds: 42),
        ),
      );
    });

    test('429 without a usable Retry-After has no duration', () {
      final failure = mapToFailure(
        _bad(
          429,
          null,
          headers: {
            'retry-after': ['soon'],
          },
        ),
      );
      expect(
        failure,
        isA<RateLimitedFailure>().having((f) => f.retryAfter, 'r', isNull),
      );
    });

    test('responses without an envelope fall back to a code per status', () {
      expect(
        mapToFailure(_bad(502, '<html>bad gateway</html>')),
        isA<ApiFailure>().having((f) => f.code, 'code', 'internal_error'),
      );
      expect(
        mapToFailure(_bad(404, {'detail': 'x'})),
        isA<ApiFailure>().having((f) => f.code, 'code', 'not_found'),
      );
    });

    test('timeouts and connection errors are network failures', () {
      final options = RequestOptions(path: '/x');
      expect(
        mapToFailure(
          DioException.receiveTimeout(
            timeout: const Duration(seconds: 1),
            requestOptions: options,
          ),
        ),
        isA<NetworkFailure>().having((f) => f.isTimeout, 'timeout', isTrue),
      );
      expect(
        mapToFailure(
          DioException.connectionError(requestOptions: options, reason: 'x'),
        ),
        isA<NetworkFailure>().having((f) => f.isTimeout, 'timeout', isFalse),
      );
    });

    test('an AppFailure wrapped by an interceptor is passed through', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/x'),
        error: const SessionExpiredFailure(),
      );
      expect(mapToFailure(error), isA<SessionExpiredFailure>());
      expect(mapToFailure(const NetworkFailure()), isA<NetworkFailure>());
    });

    test('anything else is UnknownFailure', () {
      expect(mapToFailure(const FormatException('x')), isA<UnknownFailure>());
    });
  });
}
