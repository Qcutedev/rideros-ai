import 'dart:async';

import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/features/auth/domain/auth_repository.dart';
import 'package:rideros_ai/features/auth/domain/user.dart';
import 'package:rideros_ai/features/profile/domain/rider_profile.dart';
import 'package:rideros_ai/features/profile/domain/rider_profile_repository.dart';

final testUser = User(
  id: '00000000-0000-0000-0000-000000000001',
  email: 'rider@example.com',
  displayName: 'Somchai',
  role: 'rider',
  createdAt: DateTime.utc(2026, 11, 10),
);

/// Scriptable [AuthRepository]. Set a `*Error` to make that call throw; set a `*Gate`
/// to hold the call until the test completes it (to observe loading states).
class FakeAuthRepository implements AuthRepository {
  User? restoreUser;
  Object? restoreError;
  Object? loginError;
  Object? registerError;
  Object? forgotError;
  Object? resetError;
  Object? updateNameError;
  Object? deleteError;
  Completer<void>? loginGate;
  Completer<void>? deleteGate;
  Completer<void>? restoreGate;

  final calls = <String>[];
  final Map<String, Object?> lastArgs = {};
  final _expired = StreamController<void>.broadcast();

  void expireSession() => _expired.add(null);

  @override
  Stream<void> get sessionExpired => _expired.stream;

  @override
  Future<User?> restoreSession() async {
    calls.add('restore');
    await restoreGate?.future;
    if (restoreError != null) throw restoreError!;
    return restoreUser;
  }

  @override
  Future<User> login({required String email, required String password}) async {
    calls.add('login');
    lastArgs.addAll({'email': email, 'password': password});
    await loginGate?.future;
    if (loginError != null) throw loginError!;
    return testUser.copyWith(email: email);
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    calls.add('register');
    lastArgs.addAll({
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    if (registerError != null) throw registerError!;
    return testUser.copyWith(email: email, displayName: displayName);
  }

  @override
  Future<void> logout() async => calls.add('logout');

  @override
  Future<User> updateDisplayName(String displayName) async {
    calls.add('updateName');
    lastArgs['displayName'] = displayName;
    if (updateNameError != null) throw updateNameError!;
    return testUser.copyWith(displayName: displayName.trim());
  }

  @override
  Future<void> deleteAccount(String password) async {
    calls.add('deleteAccount');
    lastArgs['password'] = password;
    await deleteGate?.future;
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    calls.add('forgot');
    lastArgs['email'] = email;
    if (forgotError != null) throw forgotError!;
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    calls.add('reset');
    lastArgs.addAll({'token': token, 'newPassword': newPassword});
    if (resetError != null) throw resetError!;
  }
}

class FakeRiderProfileRepository implements RiderProfileRepository {
  FakeRiderProfileRepository({this.configured = false, this._profile});

  bool configured;
  RiderProfile? _profile;
  Object? fetchError;
  Object? saveError;
  Completer<void>? fetchGate;
  RiderProfileInput? lastSaved;
  int saves = 0;
  int fetches = 0;

  /// What `fetch` returns: the last saved profile, or defaults.
  RiderProfile get profile =>
      (_profile ?? const RiderProfile()).copyWith(isConfigured: configured);

  @override
  Future<RiderProfile> fetch() async {
    fetches++;
    await fetchGate?.future;
    if (fetchError != null) throw fetchError!;
    return profile;
  }

  @override
  Future<RiderProfile> save(RiderProfileInput input) async {
    saves++;
    lastSaved = input;
    if (saveError != null) throw saveError!;
    configured = true;
    _profile = RiderProfile(
      vehicleType: input.vehicleType,
      fuelKmPerLiter: input.fuelKmPerLiter,
      fuelPricePerLiter: input.fuelPricePerLiter,
      depreciationPerKm: input.depreciationPerKm,
      timezone: input.timezone,
      currency: input.currency,
      isConfigured: true,
    );
    return profile;
  }
}

const invalidCredentials = ApiFailure(
  statusCode: 401,
  code: ApiErrorCode.invalidCredentials,
);
