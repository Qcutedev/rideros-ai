import 'package:flutter/foundation.dart';
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
import 'auth_form_controllers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(_email.text);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final submit = ref.watch(forgotPasswordControllerProvider);
    final busy = submit.isLoading;

    if (_sent) {
      return _SentView(
        onHaveToken: () => context.push(Routes.resetPassword),
        onBackToLogin: () => context.go(Routes.login),
      );
    }
    return AuthLayout(
      header: AuthHeader.page(
        title: l10n.forgotTitle,
        subtitle: l10n.forgotDescription,
      ),
      children: [
        Form(
          key: _formKey,
          child: AppTextField(
            key: const Key('forgot.email'),
            controller: _email,
            label: l10n.fieldEmail,
            prefixIcon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            validator: Validators(l10n).email,
            onFieldSubmitted: (_) => _submit(),
            enabled: !busy,
          ),
        ),
        formGap,
        if (submit case AsyncError(:final AppFailure error)) ...[
          AppBanner.failure(context, error),
          formGap,
        ],
        AppPrimaryButton(
          key: const Key('forgot.submit'),
          label: l10n.forgotSubmit,
          isLoading: busy,
          onPressed: _submit,
        ),
        formGap,
        TextButton(
          key: const Key('forgot.haveToken'),
          onPressed: busy ? null : () => context.push(Routes.resetPassword),
          child: Text(l10n.forgotHaveToken),
        ),
      ],
    );
  }
}

class _SentView extends StatelessWidget {
  const _SentView({required this.onHaveToken, required this.onBackToLogin});

  final VoidCallback onHaveToken;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AuthLayout(
      header: AuthHeader.page(title: l10n.forgotTitle),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.semanticColors.mint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: AppSizes.iconLg,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        formGap,
        Text(
          l10n.forgotSentTitle,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.forgotSentMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        // D5: the backend has no e-mail provider in development; the link is only logged.
        if (!kReleaseMode) ...[
          formGap,
          AppBanner(message: l10n.forgotDevNote, tone: BannerTone.warning),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppPrimaryButton(
          key: const Key('forgot.sent.haveToken'),
          label: l10n.forgotHaveToken,
          onPressed: onHaveToken,
        ),
        formGap,
        AppSecondaryButton(
          key: const Key('forgot.sent.login'),
          label: l10n.forgotBackToLogin,
          onPressed: onBackToLogin,
        ),
      ],
    );
  }
}
