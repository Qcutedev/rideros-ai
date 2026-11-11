import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_layout.dart';
import '../../../core/widgets/form_layout.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_form_controllers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final outcome = await ref
        .read(registerControllerProvider.notifier)
        .submit(
          displayName: _displayName.text,
          email: _email.text,
          password: _password.text,
        );
    // signedIn: the router guard moves on to onboarding by itself.
    if (outcome == RegisterOutcome.registeredOnly && mounted) {
      context.go('${Routes.login}?notice=${LoginNotice.registered}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final validators = Validators(l10n);
    final submit = ref.watch(registerControllerProvider);
    final busy = submit.isLoading;

    return AuthLayout(
      header: AuthHeader.page(title: l10n.registerTitle),
      footer: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.registerHaveAccount),
            TextButton(
              key: const Key('register.login'),
              onPressed: busy ? null : () => context.go(Routes.login),
              child: Text(l10n.registerGoLogin),
            ),
          ],
        ),
      ],
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  key: const Key('register.displayName'),
                  controller: _displayName,
                  label: l10n.fieldDisplayName,
                  prefixIcon: Icons.person_outline,
                  autofillHints: const [AutofillHints.name],
                  maxLength: AuthRules.displayNameMaxLength,
                  validator: validators.displayName,
                  enabled: !busy,
                ),
                formGap,
                AppTextField(
                  key: const Key('register.email'),
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
                  key: const Key('register.password'),
                  controller: _password,
                  label: l10n.fieldPassword,
                  helperText: l10n.registerPasswordHelper,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) =>
                      validators.newPassword(v, email: _email.text),
                  enabled: !busy,
                ),
                formGap,
                PasswordField(
                  key: const Key('register.confirm'),
                  controller: _confirm,
                  label: l10n.fieldConfirmPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      validators.confirmPassword(v, _password.text),
                  onFieldSubmitted: (_) => _submit(),
                  enabled: !busy,
                ),
              ],
            ),
          ),
        ),
        formGap,
        if (submit case AsyncError(:final AppFailure error)) ...[
          AppBanner.failure(context, error),
          formGap,
        ],
        AppPrimaryButton(
          key: const Key('register.submit'),
          label: l10n.registerSubmit,
          isLoading: busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}
