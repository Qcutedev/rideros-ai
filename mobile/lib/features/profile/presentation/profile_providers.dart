import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/submit_notifier.dart';
import '../../auth/presentation/session_controller.dart';
import '../../profit/presentation/profit_providers.dart';
import '../data/rider_profile_repository_impl.dart';
import '../domain/rider_profile.dart';

/// `GET /me/rider-profile` for the profile tab and the rider profile form.
final riderProfileProvider = FutureProvider.autoDispose<RiderProfile>(
  (ref) => ref.watch(riderProfileRepositoryProvider).fetch(),
);

/// Saves the whole rider profile (`PUT`). The time zone decides the days and weeks
/// of the TrueProfit summaries, so those reload too.
class RiderProfileFormController extends SubmitNotifier {
  Future<bool> save(RiderProfileInput input) => run(() async {
    await ref.read(riderProfileRepositoryProvider).save(input);
    ref.invalidate(riderProfileProvider);
    ref.read(profitDataRevisionProvider.notifier).bump();
  });
}

final riderProfileFormProvider =
    NotifierProvider.autoDispose<RiderProfileFormController, AsyncValue<void>>(
      RiderProfileFormController.new,
    );

/// Sets or clears the daily goal from Home. `PUT` replaces the whole profile, so
/// the other fields are sent back unchanged. The day boundaries do not move, so
/// the TrueProfit summaries are not reloaded.
class DailyGoalController extends SubmitNotifier {
  Future<bool> save(RiderProfile current, Decimal? goal) => run(() async {
    await ref
        .read(riderProfileRepositoryProvider)
        .save(RiderProfileInput.from(current).copyWith(dailyGoal: goal));
    ref.invalidate(riderProfileProvider);
  });
}

final dailyGoalFormProvider =
    NotifierProvider.autoDispose<DailyGoalController, AsyncValue<void>>(
      DailyGoalController.new,
    );

class DisplayNameController extends SubmitNotifier {
  Future<bool> save(String displayName) => run(
    () => ref
        .read(sessionControllerProvider.notifier)
        .updateDisplayName(displayName),
  );
}

final displayNameFormProvider =
    NotifierProvider.autoDispose<DisplayNameController, AsyncValue<void>>(
      DisplayNameController.new,
    );

/// Deleting the account signs out; the router guard then shows the login screen.
class DeleteAccountController extends SubmitNotifier {
  Future<bool> delete(String password) => run(
    () => ref.read(sessionControllerProvider.notifier).deleteAccount(password),
  );
}

final deleteAccountProvider =
    NotifierProvider.autoDispose<DeleteAccountController, AsyncValue<void>>(
      DeleteAccountController.new,
    );
