import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the refresh token only. The access token (15 min) lives in memory.
abstract interface class RefreshTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

/// Android Keystore-backed storage (`flutter_secure_storage`).
/// Auto backup is disabled in the manifest so the encrypted value is never restored
/// onto another device without its key.
class SecureRefreshTokenStore implements RefreshTokenStore {
  const SecureRefreshTokenStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'rideros.refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

/// For tests and previews.
class InMemoryRefreshTokenStore implements RefreshTokenStore {
  InMemoryRefreshTokenStore([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> delete() async => value = null;
}
