import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_layout.dart';
import '../../../core/widgets/form_layout.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/session_state.dart';
import 'auth_form_controllers.dart';
import 'session_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({this.notice, super.key});

  /// [LoginNotice] value from the route (after registering or resetting the password).
  final String? notice;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(loginControllerProvider.notifier)
        .submit(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final validators = Validators(l10n);
    final submit = ref.watch(loginControllerProvider);
    final session = ref.watch(sessionControllerProvider);
    final busy = submit.isLoading;

    final notice = switch ((session, widget.notice)) {
      (SignedOut(reason: SignOutReason.sessionExpired), _) => AppBanner(
        message: l10n.loginSessionExpired,
        tone: BannerTone.warning,
      ),
      (_, LoginNotice.registered) => AppBanner(
        message: l10n.loginRegisteredPleaseLogin,
        tone: BannerTone.success,
      ),
      (_, LoginNotice.passwordReset) => AppBanner(
        message: l10n.loginPasswordResetDone,
        tone: BannerTone.success,
      ),
      _ => null,
    };

    return AuthLayout(
      header: AuthHeader.brand(title: l10n.appTitle, tagline: l10n.appTagline),
      footer: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.loginNoAccount),
            TextButton(
              key: const Key('login.register'),
              onPressed: busy ? null : () => context.push(Routes.register),
              child: Text(l10n.loginGoRegister),
            ),
          ],
        ),
      ],
      children: [
        if (notice != null) ...[notice, formGap],
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  key: const Key('login.email'),
                  controller: _email,
                  label: l10n.fieldEmail,
                  prefixIcon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: validators.email,
                  enabled: !busy,
                ),
                formGap,
                PasswordField(
                  key: const Key('login.password'),
                  controller: _password,
                  label: l10n.fieldPassword,
                  textInputAction: TextInputAction.done,
                  validator: validators.loginPassword,
                  onFieldSubmitted: (_) => _submit(),
                  enabled: !busy,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('login.forgot'),
            onPressed: busy ? null : () => context.push(Routes.forgotPassword),
            child: Text(l10n.loginForgotPassword),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Server errors sit right above the button (S-LOGIN).
        if (submit case AsyncError(:final AppFailure error)) ...[
          AppBanner.failure(context, error),
          formGap,
        ],
        AppPrimaryButton(
          key: const Key('login.submit'),
          label: l10n.loginSubmit,
          isLoading: busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}
