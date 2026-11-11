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
import '../domain/reset_token.dart';
import 'auth_form_controllers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({this.initialToken, super.key});

  /// Pre-filled from `?token=` when the route is opened with one.
  final String? initialToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _token = TextEditingController(text: widget.initialToken);
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(resetPasswordControllerProvider.notifier)
        .submit(
          token: extractResetToken(_token.text)!,
          newPassword: _password.text,
        );
    if (ok && mounted) {
      context.go('${Routes.login}?notice=${LoginNotice.passwordReset}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final validators = Validators(l10n);
    final submit = ref.watch(resetPasswordControllerProvider);
    final busy = submit.isLoading;

    return AuthLayout(
      header: AuthHeader.page(
        title: l10n.resetTitle,
        subtitle: l10n.resetDescription,
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                key: const Key('reset.token'),
                controller: _token,
                label: l10n.resetTokenField,
                prefixIcon: Icons.link,
                keyboardType: TextInputType.url,
                validator: (v) {
                  final empty = validators.required(v);
                  if (empty != null) return empty;
                  return extractResetToken(v!) == null
                      ? l10n.validationResetTokenInvalid
                      : null;
                },
                enabled: !busy,
              ),
              formGap,
              PasswordField(
                key: const Key('reset.password'),
                controller: _password,
                label: l10n.fieldNewPassword,
                helperText: l10n.registerPasswordHelper,
                autofillHints: const [AutofillHints.newPassword],
                validator: validators.newPassword,
                enabled: !busy,
              ),
              formGap,
              PasswordField(
                key: const Key('reset.confirm'),
                controller: _confirm,
                label: l10n.fieldConfirmPassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                validator: (v) => validators.confirmPassword(v, _password.text),
                onFieldSubmitted: (_) => _submit(),
                enabled: !busy,
              ),
            ],
          ),
        ),
        formGap,
        if (submit case AsyncError(:final AppFailure error)) ...[
          AppBanner.failure(context, error),
          formGap,
        ],
        AppPrimaryButton(
          key: const Key('reset.submit'),
          label: l10n.resetSubmit,
          isLoading: busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}
