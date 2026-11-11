import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/refresh_token_store.dart';
import 'auth_interceptor.dart';
import 'session_token_manager.dart';
import 'token_pair.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final refreshTokenStoreProvider = Provider<RefreshTokenStore>(
  (ref) => const SecureRefreshTokenStore(),
);

/// Plain client without the auth interceptor. Used for `POST /auth/refresh`.
/// Tests override it with a fake `HttpClientAdapter`.
final baseDioProvider = Provider<Dio>((ref) {
  final dio = createBaseDio(ref.watch(appConfigProvider));
  ref.onDispose(dio.close);
  return dio;
});

final sessionTokenManagerProvider = Provider<SessionTokenManager>((ref) {
  final bare = ref.watch(baseDioProvider);
  final manager = SessionTokenManager(
    store: ref.watch(refreshTokenStoreProvider),
    refreshCall: (refreshToken) async {
      final response = await bare.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      return TokenPair.fromJson(response.data!);
    },
  );
  ref.onDispose(manager.dispose);
  return manager;
});

/// The client every repository uses: bearer token + refresh-and-retry on 401.
final apiClientProvider = Provider<Dio>((ref) {
  final base = ref.watch(baseDioProvider);
  final dio = Dio(base.options)..httpClientAdapter = base.httpClientAdapter;
  dio.interceptors.add(
    AuthInterceptor(
      tokens: ref.watch(sessionTokenManagerProvider),
      retry: dio.fetch,
    ),
  );
  return dio;
});

Dio createBaseDio(AppConfig config) => Dio(
  BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
    headers: {'Accept': 'application/json'},
  ),
);
