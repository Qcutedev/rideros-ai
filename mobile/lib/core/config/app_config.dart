import 'package:flutter/foundation.dart';

/// Build-time configuration, passed with `--dart-define`.
///
/// `API_BASE_URL` defaults to the Android emulator's alias for the host machine
/// (`docker compose up` binds the API to 127.0.0.1:8000 on the host).
/// A physical device can use `adb reverse tcp:8000 tcp:8000` with
/// `--dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1`.
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  factory AppConfig.fromEnvironment() {
    const url = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000/api/v1',
    );
    const config = AppConfig(apiBaseUrl: url);
    config.validate(releaseMode: kReleaseMode);
    return config;
  }

  final String apiBaseUrl;

  /// Release builds must talk to the API over HTTPS (tokens and financial data).
  void validate({required bool releaseMode}) {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_BASE_URL is not a valid absolute URL: $apiBaseUrl');
    }
    if (releaseMode && uri.scheme != 'https') {
      throw StateError('Release builds require an https API_BASE_URL');
    }
  }
}
