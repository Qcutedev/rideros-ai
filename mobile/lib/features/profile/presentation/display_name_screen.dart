import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_layout.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/session_state.dart';
import '../../auth/presentation/session_controller.dart';
import 'profile_providers.dart';

/// `/profile/display-name`: `PATCH /me` (the display name is the only editable field).
class DisplayNameScreen extends ConsumerStatefulWidget {
  const DisplayNameScreen({super.key});

  @override
  ConsumerState<DisplayNameScreen> createState() => _DisplayNameScreenState();
}

class _DisplayNameScreenState extends ConsumerState<DisplayNameScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: switch (ref.read(sessionControllerProvider)) {
      SignedIn(:final user) => user.displayName,
      _ => '',
    },
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final ok = await ref
        .read(displayNameFormProvider.notifier)
        .save(_name.text.trim());
    if (ok && mounted) closeForm(context, l10n.recordSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final submit = ref.watch(displayNameFormProvider);
    final busy = submit.isLoading;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileEditName)),
      body: FormLayout(
        children: [
          Form(
            key: _formKey,
            child: AppTextField(
              key: const Key('displayName.field'),
              controller: _name,
              label: l10n.fieldDisplayName,
              prefixIcon: Icons.badge_outlined,
              textInputAction: TextInputAction.done,
              maxLength: AuthRules.displayNameMaxLength,
              enabled: !busy,
              validator: Validators(l10n).displayName,
              onFieldSubmitted: (_) => _save(),
            ),
          ),
          formGap,
          if (submit case AsyncError(:final AppFailure error)) ...[
            AppBanner.failure(context, error),
            formGap,
          ],
          AppPrimaryButton(
            key: const Key('displayName.submit'),
            label: l10n.recordSave,
            isLoading: busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
