import 'pickup_models.dart';

/// A time of day without a date (the form's pickers).
typedef PickupClock = ({int hour, int minute});

/// Arrival and pickup entered as an arrival date plus two times of day, in the
/// device's time zone. A pickup time before the arrival time means the next day
/// (past midnight); equal times are a wait of 0 minutes.
({DateTime arrivedAt, DateTime pickedUpAt}) pickupTimes(
  DateTime date,
  PickupClock arrived,
  PickupClock pickedUp,
) {
  final arrivedAt = DateTime(
    date.year,
    date.month,
    date.day,
    arrived.hour,
    arrived.minute,
  );
  final nextDay =
      pickedUp.hour * 60 + pickedUp.minute < arrived.hour * 60 + arrived.minute;
  final pickedUpAt = DateTime(
    date.year,
    date.month,
    date.day + (nextDay ? 1 : 0),
    pickedUp.hour,
    pickedUp.minute,
  );
  return (arrivedAt: arrivedAt, pickedUpAt: pickedUpAt);
}

/// The backend rejects waits above 3 hours (`pickup_wait_too_long`).
bool isWaitTooLong(DateTime arrivedAt, DateTime pickedUpAt) =>
    pickedUpAt.difference(arrivedAt) > PickupLimits.maxWait;
