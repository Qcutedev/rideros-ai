import 'dart:async';

import '../errors/app_failure.dart';
import '../errors/failure_mapper.dart';
import '../storage/refresh_token_store.dart';
import 'token_pair.dart';

/// Calls `POST /auth/refresh` without the auth interceptor.
typedef RefreshCall = Future<TokenPair> Function(String refreshToken);

/// Owns the tokens of the current login session.
///
/// * The access token stays in memory; the refresh token goes to [RefreshTokenStore].
/// * [refresh] is single-flight: concurrent callers share one `POST /auth/refresh`, so a
///   rotated refresh token is never presented twice (the backend would treat that as
///   reuse and revoke the whole session).
/// * When the backend rejects the refresh token, the tokens are cleared and
///   [sessionExpired] fires so the app can return to the login screen.
class SessionTokenManager {
  SessionTokenManager({required this._store, required this._refreshCall});

  final RefreshTokenStore _store;
  final RefreshCall _refreshCall;
  final _expired = StreamController<void>.broadcast();

  String? _accessToken;
  Future<String>? _inFlight;

  String? get accessToken => _accessToken;

  Stream<void> get sessionExpired => _expired.stream;

  Future<String?> readRefreshToken() => _store.read();

  Future<void> save(TokenPair pair) async {
    _accessToken = pair.accessToken;
    await _store.write(pair.refreshToken);
  }

  Future<void> clear() async {
    _accessToken = null;
    await _store.delete();
  }

  /// Returns a fresh access token or throws [SessionExpiredFailure] / [NetworkFailure].
  Future<String> refresh() => _inFlight ??= _refresh().whenComplete(() {
    _inFlight = null;
  });

  Future<String> _refresh() async {
    final refreshToken = await _store.read();
    if (refreshToken == null) {
      await _expire();
      throw const SessionExpiredFailure();
    }
    final TokenPair pair;
    try {
      pair = await _refreshCall(refreshToken);
    } catch (error) {
      final failure = mapToFailure(error);
      if (_rejectsToken(failure)) {
        await _expire();
        throw const SessionExpiredFailure();
      }
      throw failure;
    }
    await save(pair);
    return pair.accessToken;
  }

  /// 401 (`invalid_refresh_token`, `refresh_token_expired`, `refresh_token_revoked`) or a
  /// malformed stored token (422) means this session cannot continue.
  bool _rejectsToken(AppFailure failure) =>
      failure is ApiFailure &&
      (failure.statusCode == 401 || failure.statusCode == 422);

  Future<void> _expire() async {
    await clear();
    _expired.add(null);
  }

  Future<void> dispose() => _expired.close();
}
