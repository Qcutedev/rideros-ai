import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_layout.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import 'profile_providers.dart';

/// `/profile/delete-account` (S-ACCOUNT-DELETE): `DELETE /me` with the password.
/// Success signs out; the router guard then shows the login screen with a notice.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDelete(
      context,
      title: l10n.deleteAccountConfirmTitle,
      message: l10n.deleteAccountConfirmMessage,
      confirmLabel: l10n.deleteAccountSubmit,
    );
    if (!confirmed || !mounted) return;
    await ref.read(deleteAccountProvider.notifier).delete(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final submit = ref.watch(deleteAccountProvider);
    final busy = submit.isLoading;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccountTitle)),
      body: FormLayout(
        children: [
          AppBanner(
            key: const Key('deleteAccount.warning'),
            message: l10n.deleteAccountWarning,
            tone: BannerTone.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.deleteAccountIrreversible,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          Form(
            key: _formKey,
            child: PasswordField(
              key: const Key('deleteAccount.password'),
              controller: _password,
              label: l10n.fieldPassword,
              helperText: l10n.deleteAccountPasswordHelper,
              textInputAction: TextInputAction.done,
              autofillHints: const [],
              enabled: !busy,
              validator: Validators(l10n).loginPassword,
            ),
          ),
          formGap,
          if (submit case AsyncError(:final AppFailure error)) ...[
            AppBanner.failure(context, error),
            formGap,
          ],
          AppDestructiveButton(
            key: const Key('deleteAccount.submit'),
            label: l10n.deleteAccountSubmit,
            isLoading: busy,
            onPressed: _delete,
          ),
        ],
      ),
    );
  }
}
