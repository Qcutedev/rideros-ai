import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/network/session_token_manager.dart';
import 'package:rideros_ai/core/network/token_pair.dart';
import 'package:rideros_ai/core/storage/refresh_token_store.dart';

TokenPair _pair(int n) => TokenPair(
  accessToken: 'access-$n',
  refreshToken: 'refresh-$n',
  expiresIn: 900,
  refreshExpiresAt: DateTime.utc(2026, 12, 10),
);

DioException _status(int status, String code) {
  final options = RequestOptions(path: '/auth/refresh');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: {
        'error': {'code': code, 'message': code, 'details': <Object>[]},
      },
    ),
  );
}

void main() {
  late InMemoryRefreshTokenStore store;
  late List<String> presented;
  late Future<TokenPair> Function(String token) answer;
  late SessionTokenManager manager;

  setUp(() {
    store = InMemoryRefreshTokenStore('refresh-0');
    presented = [];
    answer = (token) async => _pair(presented.length);
    manager = SessionTokenManager(
      store: store,
      refreshCall: (token) {
        presented.add(token);
        return answer(token);
      },
    );
  });

  tearDown(() => manager.dispose());

  test('save keeps access in memory and refresh in the store', () async {
    await manager.save(_pair(7));
    expect(manager.accessToken, 'access-7');
    expect(store.value, 'refresh-7');
  });

  test('refresh rotates both tokens', () async {
    final access = await manager.refresh();
    expect(access, 'access-1');
    expect(presented, ['refresh-0']);
    expect(store.value, 'refresh-1');
    expect(manager.accessToken, 'access-1');
  });

  test('concurrent callers share one refresh call (single flight)', () async {
    final gate = Completer<void>();
    answer = (token) async {
      await gate.future;
      return _pair(1);
    };
    final results = Future.wait([
      manager.refresh(),
      manager.refresh(),
      manager.refresh(),
    ]);
    gate.complete();
    expect(await results, ['access-1', 'access-1', 'access-1']);
    expect(presented, hasLength(1));

    // A later refresh is a new call with the rotated token.
    answer = (token) async => _pair(2);
    await manager.refresh();
    expect(presented, ['refresh-0', 'refresh-1']);
  });

  for (final code in [
    'refresh_token_revoked',
    'refresh_token_expired',
    'invalid_refresh_token',
  ]) {
    test('401 $code clears tokens and fires sessionExpired', () async {
      await manager.save(_pair(0));
      answer = (token) async => throw _status(401, code);
      final expired = expectLater(manager.sessionExpired, emits(null));
      await expectLater(
        manager.refresh(),
        throwsA(isA<SessionExpiredFailure>()),
      );
      await expired;
      expect(manager.accessToken, isNull);
      expect(store.value, isNull);
    });
  }

  test('a network error keeps the session (retry later)', () async {
    answer = (token) async => throw DioException.connectionError(
      requestOptions: RequestOptions(path: '/auth/refresh'),
      reason: 'offline',
    );
    await expectLater(manager.refresh(), throwsA(isA<NetworkFailure>()));
    expect(store.value, 'refresh-0');
  });

  test('a 5xx keeps the session', () async {
    answer = (token) async => throw _status(500, 'internal_error');
    await expectLater(manager.refresh(), throwsA(isA<ApiFailure>()));
    expect(store.value, 'refresh-0');
  });

  test('no stored token expires the session without a call', () async {
    store.value = null;
    await expectLater(manager.refresh(), throwsA(isA<SessionExpiredFailure>()));
    expect(presented, isEmpty);
  });
}
