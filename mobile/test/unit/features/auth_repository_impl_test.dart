import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/network/api_client.dart';
import 'package:rideros_ai/core/storage/refresh_token_store.dart';
import 'package:rideros_ai/features/auth/data/auth_repository_impl.dart';
import 'package:rideros_ai/features/auth/domain/auth_repository.dart';

import '../../helpers/fake_http_adapter.dart';

/// Runs the real providers (dio, interceptor, token manager, repository) against a fake
/// HTTP adapter.
void main() {
  late FakeHttpAdapter adapter;
  late InMemoryRefreshTokenStore store;
  late ProviderContainer container;
  late AuthRepository repo;

  setUp(() {
    adapter = FakeHttpAdapter((o) => json(404));
    store = InMemoryRefreshTokenStore();
    container = ProviderContainer.test(
      retry: (retryCount, error) => null,
      overrides: [
        refreshTokenStoreProvider.overrideWithValue(store),
        baseDioProvider.overrideWith((ref) {
          final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
            ..httpClientAdapter = adapter;
          return dio;
        }),
      ],
    );
    repo = container.read(authRepositoryProvider);
  });

  test('register posts trimmed fields and sends no token', () async {
    adapter.handler = (o) => json(201, userJson(name: 'Somchai'));
    final user = await repo.register(
      email: ' rider@example.com ',
      password: 'pass word 1',
      displayName: ' Somchai ',
    );
    final request = adapter.requests.single;
    expect(request.path, '/auth/register');
    expect(request.data, {
      'email': 'rider@example.com',
      'password': 'pass word 1',
      'display_name': 'Somchai',
    });
    expect(request.headers.containsKey('Authorization'), isFalse);
    expect(user.displayName, 'Somchai');
    expect(store.value, isNull, reason: 'register returns no tokens');
  });

  test(
    'login stores the refresh token and loads /me with the access token',
    () async {
      adapter.handler = (o) => switch (o.path) {
        '/auth/login' => json(
          200,
          tokenJson(access: 'a1', refresh: 'r1-0000000000000000'),
        ),
        '/me' => json(200, userJson()),
        _ => json(404),
      };
      final user = await repo.login(email: 'rider@example.com', password: 'pw');
      expect(user.email, 'rider@example.com');
      expect(store.value, 'r1-0000000000000000');
      expect(adapter.requests.last.headers['Authorization'], 'Bearer a1');
    },
  );

  test('login errors become typed failures', () async {
    adapter.handler = (o) => apiError(401, 'invalid_credentials');
    await expectLater(
      repo.login(email: 'rider@example.com', password: 'bad'),
      throwsA(
        isA<ApiFailure>().having((f) => f.code, 'code', 'invalid_credentials'),
      ),
    );
    expect(store.value, isNull);
  });

  test('rate limiting is surfaced with Retry-After', () async {
    adapter.handler = (o) => apiError(
      429,
      'rate_limited',
      headers: {
        'retry-after': ['30'],
      },
    );
    await expectLater(
      repo.login(email: 'rider@example.com', password: 'pw'),
      throwsA(
        isA<RateLimitedFailure>().having(
          (f) => f.retryAfter,
          'retryAfter',
          const Duration(seconds: 30),
        ),
      ),
    );
  });

  test(
    'restoreSession without a stored token returns null and calls nothing',
    () async {
      expect(await repo.restoreSession(), isNull);
      expect(adapter.requests, isEmpty);
    },
  );

  test('restoreSession refreshes (rotation) then loads /me', () async {
    store.value = 'stored-refresh-000000';
    adapter.handler = (o) => switch (o.path) {
      '/auth/refresh' => json(
        200,
        tokenJson(access: 'a2', refresh: 'r2-0000000000000000'),
      ),
      '/me' => json(200, userJson()),
      _ => json(404),
    };
    final user = await repo.restoreSession();
    expect(user, isNotNull);
    expect(adapter.requests.first.data, {
      'refresh_token': 'stored-refresh-000000',
    });
    expect(store.value, 'r2-0000000000000000');
  });

  test(
    'restoreSession with a revoked token throws SessionExpiredFailure',
    () async {
      store.value = 'stored-refresh-000000';
      adapter.handler = (o) => apiError(401, 'refresh_token_revoked');
      await expectLater(
        repo.restoreSession(),
        throwsA(isA<SessionExpiredFailure>()),
      );
      expect(store.value, isNull);
    },
  );

  test('restoreSession offline keeps the stored token', () async {
    store.value = 'stored-refresh-000000';
    adapter.handler = offline;
    await expectLater(repo.restoreSession(), throwsA(isA<NetworkFailure>()));
    expect(store.value, 'stored-refresh-000000');
  });

  test('logout revokes on the server and clears local tokens', () async {
    store.value = 'stored-refresh-000000';
    adapter.handler = (o) => json(204);
    await repo.logout();
    expect(adapter.requests.single.path, '/auth/logout');
    expect(adapter.requests.single.data, {
      'refresh_token': 'stored-refresh-000000',
    });
    expect(store.value, isNull);
  });

  test('logout offline still clears local tokens', () async {
    store.value = 'stored-refresh-000000';
    adapter.handler = offline;
    await repo.logout();
    expect(store.value, isNull);
  });

  test(
    'forgot and reset password are public calls with the documented bodies',
    () async {
      adapter.handler = (o) => o.path == '/auth/forgot-password'
          ? json(202, {'detail': 'accepted'})
          : json(204);
      await repo.requestPasswordReset(' rider@example.com');
      await repo.resetPassword(
        token: 'tok-0000000000000000',
        newPassword: 'new pass 1',
      );
      expect(adapter.requests[0].data, {'email': 'rider@example.com'});
      expect(adapter.requests[1].data, {
        'token': 'tok-0000000000000000',
        'new_password': 'new pass 1',
      });
      expect(
        adapter.requests.every((r) => !r.headers.containsKey('Authorization')),
        isTrue,
      );
    },
  );

  test('invalid reset token is a typed failure', () async {
    adapter.handler = (o) => apiError(400, 'invalid_reset_token');
    await expectLater(
      repo.resetPassword(token: 'tok-0000000000000000', newPassword: 'x'),
      throwsA(
        isA<ApiFailure>().having((f) => f.code, 'code', 'invalid_reset_token'),
      ),
    );
  });
}
