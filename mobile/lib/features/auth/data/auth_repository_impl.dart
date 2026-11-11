import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_guard.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/network/session_token_manager.dart';
import '../../../core/network/token_pair.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    dio: ref.watch(apiClientProvider),
    tokens: ref.watch(sessionTokenManagerProvider),
  ),
);

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this._dio, required this._tokens});

  final Dio _dio;
  final SessionTokenManager _tokens;

  @override
  Stream<void> get sessionExpired => _tokens.sessionExpired;

  @override
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  }) => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email.trim(),
        'password': password,
        'display_name': displayName.trim(),
      },
      options: AuthOptions.public,
    );
    return User.fromJson(response.data!);
  });

  @override
  Future<User> login({required String email, required String password}) =>
      guardApi(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'email': email.trim(), 'password': password},
          options: AuthOptions.public,
        );
        await _tokens.save(TokenPair.fromJson(response.data!));
        return _me();
      });

  @override
  Future<User?> restoreSession() => guardApi(() async {
    if (await _tokens.readRefreshToken() == null) return null;
    await _tokens.refresh();
    return _me();
  });

  @override
  Future<void> logout() async {
    final refreshToken = await _tokens.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _dio.post<void>(
          '/auth/logout',
          data: {'refresh_token': refreshToken},
          options: AuthOptions.public,
        );
      }
    } on DioException {
      // Offline or server error: the local session ends anyway. The server-side token
      // expires on its own (30 days) and cannot be used without the device.
    } finally {
      await _tokens.clear();
    }
  }

  @override
  Future<void> requestPasswordReset(String email) => guardApi(() async {
    await _dio.post<void>(
      '/auth/forgot-password',
      data: {'email': email.trim()},
      options: AuthOptions.public,
    );
  });

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) => guardApi(() async {
    await _dio.post<void>(
      '/auth/reset-password',
      data: {'token': token, 'new_password': newPassword},
      options: AuthOptions.public,
    );
  });

  @override
  Future<User> updateDisplayName(String displayName) => guardApi(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/me',
      data: {'display_name': displayName.trim()},
    );
    return User.fromJson(response.data!);
  });

  @override
  Future<void> deleteAccount(String password) => guardApi(() async {
    await _dio.delete<void>('/me', data: {'password': password});
    // The server deleted the refresh tokens with the account.
    await _tokens.clear();
  });

  Future<User> _me() async {
    final response = await _dio.get<Map<String, dynamic>>('/me');
    return User.fromJson(response.data!);
  }
}
