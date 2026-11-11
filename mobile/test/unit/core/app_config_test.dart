import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/config/app_config.dart';

void main() {
  test('development may use the emulator http alias', () {
    const config = AppConfig(apiBaseUrl: 'http://10.0.2.2:8000/api/v1');
    expect(() => config.validate(releaseMode: false), returnsNormally);
  });

  test('release builds require https', () {
    const http = AppConfig(apiBaseUrl: 'http://api.example.com/api/v1');
    const https = AppConfig(apiBaseUrl: 'https://api.example.com/api/v1');
    expect(() => http.validate(releaseMode: true), throwsStateError);
    expect(() => https.validate(releaseMode: true), returnsNormally);
  });

  test('rejects a relative or empty URL', () {
    expect(
      () => const AppConfig(apiBaseUrl: '/api/v1').validate(releaseMode: false),
      throwsStateError,
    );
    expect(
      () => const AppConfig(apiBaseUrl: '').validate(releaseMode: false),
      throwsStateError,
    );
  });

  test('the default points at the emulator host alias', () {
    expect(
      AppConfig.fromEnvironment().apiBaseUrl,
      'http://10.0.2.2:8000/api/v1',
    );
  });
}
