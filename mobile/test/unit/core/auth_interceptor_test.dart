import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/errors/failure_mapper.dart';
import 'package:rideros_ai/core/network/auth_interceptor.dart';
import 'package:rideros_ai/core/network/session_token_manager.dart';
import 'package:rideros_ai/core/network/token_pair.dart';
import 'package:rideros_ai/core/storage/refresh_token_store.dart';

import '../../helpers/fake_http_adapter.dart';

/// Backend stand-in: `/data` accepts only the current access token.
class _Server {
  String validAccess = 'access-0';
  int refreshCalls = 0;
  Completer<void>? refreshGate;
  ResponseBody? refreshAnswer;

  Future<ResponseBody> handle(RequestOptions o) async {
    if (o.path == '/auth/refresh') {
      refreshCalls++;
      await refreshGate?.future;
      if (refreshAnswer != null) return refreshAnswer!;
      validAccess = 'access-$refreshCalls';
      return json(
        200,
        tokenJson(access: validAccess, refresh: 'refresh-$refreshCalls'),
      );
    }
    final auth = o.headers['Authorization'];
    if (o.path == '/public') return json(200, {'auth': auth});
    if (o.path == '/wrong-password') {
      return apiError(401, ApiErrorCode.invalidCredentials);
    }
    if (auth == null) return apiError(401, ApiErrorCode.notAuthenticated);
    if (auth != 'Bearer $validAccess') {
      return apiError(401, ApiErrorCode.tokenExpired);
    }
    return json(200, {'ok': o.path});
  }
}

void main() {
  late _Server server;
  late FakeHttpAdapter adapter;
  late InMemoryRefreshTokenStore store;
  late SessionTokenManager tokens;
  late Dio dio;

  setUp(() async {
    server = _Server();
    adapter = FakeHttpAdapter(server.handle);
    store = InMemoryRefreshTokenStore();
    final bare = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
      ..httpClientAdapter = adapter;
    tokens = SessionTokenManager(
      store: store,
      refreshCall: (refresh) async {
        final r = await bare.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'refresh_token': refresh},
        );
        return TokenPair.fromJson(r.data!);
      },
    );
    dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(tokens: tokens, retry: dio.fetch));
    await tokens.save(
      TokenPair.fromJson(tokenJson(access: 'access-0', refresh: 'refresh-0')),
    );
  });

  tearDown(() => tokens.dispose());

  test('adds the bearer token', () async {
    final r = await dio.get<Map<String, dynamic>>('/data');
    expect(r.data, {'ok': '/data'});
    expect(adapter.requests.single.headers['Authorization'], 'Bearer access-0');
  });

  test('public requests carry no token', () async {
    final r = await dio.get<Map<String, dynamic>>(
      '/public',
      options: AuthOptions.public,
    );
    expect(r.data, {'auth': null});
  });

  test('expired access token: refresh once, then retry', () async {
    server.validAccess = 'rotated-on-server';
    // The server only accepts what /auth/refresh issues next.
    final r = await dio.get<Map<String, dynamic>>('/data');
    expect(r.data, {'ok': '/data'});
    expect(adapter.paths, ['/data', '/auth/refresh', '/data']);
    expect(adapter.requests.last.headers['Authorization'], 'Bearer access-1');
    expect(store.value, 'refresh-1');
  });

  test('expired access token: a multipart body is sent again', () async {
    server.validAccess = 'rotated-on-server';
    final r = await dio.post<Map<String, dynamic>>(
      '/data',
      data: FormData.fromMap({
        'category': 'flooding',
        'image': MultipartFile.fromBytes([1, 2, 3], filename: 'a.jpg'),
      }),
    );
    expect(r.data, {'ok': '/data'});
    expect(adapter.paths, ['/data', '/auth/refresh', '/data']);
    final retried = adapter.requests.last.data as FormData;
    expect(retried.fields.single.value, 'flooding');
    expect(retried.files.single.value.filename, 'a.jpg');
  });

  test('concurrent 401s trigger a single refresh', () async {
    server.validAccess = 'rotated-on-server';
    server.refreshGate = Completer<void>();
    final all = Future.wait([
      for (var i = 0; i < 4; i++) dio.get<Map<String, dynamic>>('/data'),
    ]);
    await pumpEventQueue();
    server.refreshGate!.complete();
    final responses = await all;
    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(server.refreshCalls, 1);
    expect(adapter.count('/data'), 8);
  });

  test(
    'a 401 that arrives after another refresh retries without refreshing',
    () async {
      server.validAccess = 'rotated-on-server';
      final slowGate = Completer<void>();
      var staleCalls = 0;
      adapter.handler = (o) async {
        final stale =
            o.path == '/data' &&
            o.headers['Authorization'] == 'Bearer access-0';
        if (stale && ++staleCalls == 2) await slowGate.future;
        return server.handle(o);
      };
      final fast = dio.get<Map<String, dynamic>>('/data');
      final slow = dio.get<Map<String, dynamic>>('/data');
      await fast; // refreshed to access-1 and retried
      expect(server.refreshCalls, 1);
      slowGate.complete(); // the slow request now gets its 401 for access-0
      final response = await slow;
      expect(response.statusCode, 200);
      expect(server.refreshCalls, 1);
      expect(adapter.requests.last.headers['Authorization'], 'Bearer access-1');
    },
  );

  test('rejected refresh token ends the session', () async {
    server.validAccess = 'rotated-on-server';
    server.refreshAnswer = apiError(401, 'refresh_token_revoked');
    final expired = expectLater(tokens.sessionExpired, emits(null));
    final error = await dio
        .get<Map<String, dynamic>>('/data')
        .then<Object?>((_) => null, onError: (Object e) => e);
    expect(mapToFailure(error!), isA<SessionExpiredFailure>());
    await expired;
    expect(store.value, isNull);
    expect(tokens.accessToken, isNull);
  });

  test(
    'refresh while offline keeps the session and reports a network failure',
    () async {
      server.validAccess = 'rotated-on-server';
      adapter.handler = (o) =>
          o.path == '/auth/refresh' ? offline(o) : server.handle(o);
      final error = await dio
          .get<Map<String, dynamic>>('/data')
          .then<Object?>((_) => null, onError: (Object e) => e);
      expect(mapToFailure(error!), isA<NetworkFailure>());
      expect(store.value, 'refresh-0');
    },
  );

  test('401 that is not about the access token is passed through', () async {
    final error = await dio
        .get<Map<String, dynamic>>('/wrong-password')
        .then<Object?>((_) => null, onError: (Object e) => e);
    expect(
      mapToFailure(error!),
      isA<ApiFailure>().having((f) => f.code, 'code', 'invalid_credentials'),
    );
    expect(server.refreshCalls, 0);
  });

  test('a retried request is not refreshed again (no loop)', () async {
    server.validAccess = 'never-valid';
    adapter.handler = (o) async {
      if (o.path == '/auth/refresh') {
        server.refreshCalls++;
        return json(200, tokenJson(access: 'still-wrong'));
      }
      return apiError(401, ApiErrorCode.tokenExpired);
    };
    final error = await dio
        .get<Map<String, dynamic>>('/data')
        .then<Object?>((_) => null, onError: (Object e) => e);
    expect(error, isA<DioException>());
    expect(server.refreshCalls, 1);
    expect(adapter.count('/data'), 2);
  });
}
