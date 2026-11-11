import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rideros_ai/features/profile/domain/rider_profile.dart';

import '../helpers/fakes.dart';
import '../helpers/pump.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeRiderProfileRepository profiles;

  setUp(() {
    auth = FakeAuthRepository()..restoreUser = testUser;
    profiles = FakeRiderProfileRepository();
  });

  Future<void> pump(WidgetTester tester) => pumpScreen(
    tester,
    path: Routes.onboarding,
    screen: const OnboardingScreen(),
    overrides: fakeRepositories(auth, profiles),
  );

  testWidgets('invalid numbers are rejected before saving', (tester) async {
    await pump(tester);
    await enter(tester, 'onboarding.fuelKmPerLiter', '0');
    await enter(tester, 'onboarding.fuelPrice', 'abc');
    await enter(tester, 'onboarding.depreciation', '1.23456');
    await tapKey(tester, 'onboarding.submit');
    expect(find.text(t.validationNumberMustBePositive), findsOneWidget);
    expect(find.text(t.validationNumberInvalid), findsOneWidget);
    expect(find.text(t.validationNumberTooManyDecimals(4)), findsOneWidget);
    expect(profiles.saves, 0);
  });

  testWidgets('saves the entered values as decimals', (tester) async {
    await pump(tester);
    await tester.tap(find.text(t.vehicleNotSpecified));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.vehicleEvMotorcycle).last);
    await tester.pumpAndSettle();
    await enter(tester, 'onboarding.fuelKmPerLiter', '45.5');
    await enter(tester, 'onboarding.fuelPrice', ' 38 ');
    await tapKey(tester, 'onboarding.submit');

    final saved = profiles.lastSaved!;
    expect(saved.vehicleType, VehicleType.evMotorcycle);
    expect(saved.fuelKmPerLiter, Decimal.parse('45.5'));
    expect(saved.fuelPricePerLiter, Decimal.parse('38'));
    expect(saved.depreciationPerKm, isNull);
    expect(saved.timezone, 'Asia/Bangkok');
  });

  testWidgets('skip saves the defaults', (tester) async {
    await pump(tester);
    await enter(tester, 'onboarding.fuelPrice', '38');
    await tapKey(tester, 'onboarding.skip');
    expect(profiles.saves, 1);
    expect(profiles.lastSaved, const RiderProfileInput());
  });

  testWidgets('a save error is shown and the form stays', (tester) async {
    profiles.saveError = const NetworkFailure();
    await pump(tester);
    await tapKey(tester, 'onboarding.submit');
    expect(find.text(t.failureNetwork), findsOneWidget);
    expect(find.byKey(const Key('onboarding.submit')), findsOneWidget);
  });
}
