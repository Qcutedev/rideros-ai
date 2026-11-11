import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/submit_notifier.dart';
import '../data/auth_repository_impl.dart';
import 'session_controller.dart';

final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, AsyncValue<void>>(
      LoginController.new,
    );

final registerControllerProvider =
    NotifierProvider.autoDispose<RegisterController, AsyncValue<void>>(
      RegisterController.new,
    );

final forgotPasswordControllerProvider =
    NotifierProvider.autoDispose<ForgotPasswordController, AsyncValue<void>>(
      ForgotPasswordController.new,
    );

final resetPasswordControllerProvider =
    NotifierProvider.autoDispose<ResetPasswordController, AsyncValue<void>>(
      ResetPasswordController.new,
    );

/// On success the session becomes `SignedIn` and the router leaves the login screen.
class LoginController extends SubmitNotifier {
  Future<bool> submit({required String email, required String password}) => run(
    () => ref
        .read(sessionControllerProvider.notifier)
        .login(email: email, password: password),
  );
}

enum RegisterOutcome {
  /// Account created and signed in.
  signedIn,

  /// Account created, but the follow-up login failed (e.g. rate limited or offline).
  /// The rider continues on the login screen.
  registeredOnly,
}

class RegisterController extends SubmitNotifier {
  /// `null` when the registration itself failed (see `state` for the failure).
  Future<RegisterOutcome?> submit({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final session = ref.read(sessionControllerProvider.notifier);
    var outcome = RegisterOutcome.registeredOnly;
    final ok = await run(() async {
      await session.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      try {
        await session.login(email: email, password: password);
        outcome = RegisterOutcome.signedIn;
      } on Object {
        outcome = RegisterOutcome.registeredOnly;
      }
    });
    return ok ? outcome : null;
  }
}

class ForgotPasswordController extends SubmitNotifier {
  Future<bool> submit(String email) =>
      run(() => ref.read(authRepositoryProvider).requestPasswordReset(email));
}

class ResetPasswordController extends SubmitNotifier {
  Future<bool> submit({required String token, required String newPassword}) =>
      run(
        () => ref
            .read(authRepositoryProvider)
            .resetPassword(token: token, newPassword: newPassword),
      );
}
