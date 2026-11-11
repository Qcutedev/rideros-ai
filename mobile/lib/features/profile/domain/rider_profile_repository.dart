import 'rider_profile.dart';

/// Every method throws an `AppFailure` on error.
abstract interface class RiderProfileRepository {
  Future<RiderProfile> fetch();

  Future<RiderProfile> save(RiderProfileInput input);
}
