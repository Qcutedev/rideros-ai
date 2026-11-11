import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/features/profile/data/rider_profile_repository_impl.dart';
import 'package:rideros_ai/features/profile/domain/rider_profile.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  test('decimals are parsed from JSON strings without float rounding', () {
    final profile = RiderProfile.fromJson({
      ...profileJson(configured: true),
      'depreciation_per_km': '0.1234',
    });
    expect(profile.vehicleType, VehicleType.motorcycle);
    expect(profile.fuelKmPerLiter, Decimal.parse('45.5'));
    expect(profile.fuelPricePerLiter, Decimal.parse('38'));
    expect(profile.depreciationPerKm, Decimal.parse('0.1234'));
    expect(profile.isConfigured, isTrue);
  });

  test('defaults from an unconfigured profile', () {
    final profile = RiderProfile.fromJson(profileJson());
    expect(profile.isConfigured, isFalse);
    expect(profile.vehicleType, isNull);
    expect(profile.timezone, 'Asia/Bangkok');
  });

  test('PUT body sends decimals as strings and nulls explicitly', () {
    final body = RiderProfileInput(
      vehicleType: VehicleType.evMotorcycle,
      fuelKmPerLiter: Decimal.parse('45.50'),
    ).toJson();
    expect(body, {
      'vehicle_type': 'ev_motorcycle',
      'fuel_km_per_liter': '45.5',
      'fuel_price_per_liter': null,
      'depreciation_per_km': null,
      'timezone': 'Asia/Bangkok',
      'currency': 'THB',
    });
  });

  test('repository GETs and PUTs /me/rider-profile', () async {
    final adapter = FakeHttpAdapter(
      (o) => json(200, profileJson(configured: o.method == 'PUT')),
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
      ..httpClientAdapter = adapter;
    final repo = RiderProfileRepositoryImpl(dio);

    expect((await repo.fetch()).isConfigured, isFalse);
    final saved = await repo.save(const RiderProfileInput());
    expect(saved.isConfigured, isTrue);
    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'GET /me/rider-profile',
      'PUT /me/rider-profile',
    ]);
  });
}
