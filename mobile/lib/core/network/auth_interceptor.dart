import 'package:dio/dio.dart';

import '../errors/app_failure.dart';
import '../errors/failure_mapper.dart';
import 'session_token_manager.dart';

/// Request option keys understood by [AuthInterceptor].
abstract final class AuthOptions {
  /// Set `extra[skipAuth] = true` for endpoints that must not carry or refresh a token
  /// (login, register, refresh, logout, password reset).
  static const skipAuth = 'rideros.skipAuth';
  static const _retried = 'rideros.retried';
  static const _tokenUsed = 'rideros.tokenUsed';

  static Options get public => Options(extra: {skipAuth: true});
}

/// Adds `Authorization: Bearer <access>` and, on a 401 caused by the access token,
/// refreshes once (shared with every concurrent request) and retries the request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._tokens, required this.retry});

  final SessionTokenManager _tokens;

  /// Re-sends a request through the full client (normally `dio.fetch`).
  final Future<Response<dynamic>> Function(RequestOptions options) retry;

  static const _accessTokenCodes = {
    ApiErrorCode.tokenExpired,
    ApiErrorCode.invalidToken,
    ApiErrorCode.notAuthenticated,
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra[AuthOptions.skipAuth] != true) {
      final token = _tokens.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      options.extra[AuthOptions._tokenUsed] = token;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (!_shouldRefresh(err)) {
      handler.next(err);
      return;
    }
    try {
      // Another request may have refreshed while this one was in flight.
      final current = _tokens.accessToken;
      if (current == null || current == request.extra[AuthOptions._tokenUsed]) {
        await _tokens.refresh();
      }
      request.extra[AuthOptions._retried] = true;
      handler.resolve(await retry(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (error) {
      handler.next(
        DioException(
          requestOptions: request,
          response: err.response,
          error: mapToFailure(error),
        ),
      );
    }
  }

  bool _shouldRefresh(DioException err) {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401) return false;
    if (request.extra[AuthOptions.skipAuth] == true) return false;
    if (request.extra[AuthOptions._retried] == true) return false;
    final failure = mapToFailure(err);
    return failure is ApiFailure && _accessTokenCodes.contains(failure.code);
  }
}
