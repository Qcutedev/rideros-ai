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
import '../domain/rider_profile.dart';
import 'profile_providers.dart';
import 'rider_profile_fields.dart';

/// `/profile/rider` (S-RIDER-PROFILE-FORM): the onboarding fields plus the time zone.
/// `PUT` replaces the whole profile, so every field is sent.
class RiderProfileFormScreen extends ConsumerWidget {
  const RiderProfileFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RecordLoader<RiderProfile>(
      provider: riderProfileProvider,
      title: AppLocalizations.of(context).riderProfileTitle,
      onRetry: () => ref.invalidate(riderProfileProvider),
      builder: (profile) => _RiderProfileForm(initial: profile),
    );
  }
}

class _RiderProfileForm extends ConsumerStatefulWidget {
  const _RiderProfileForm({required this.initial});

  final RiderProfile initial;

  @override
  ConsumerState<_RiderProfileForm> createState() => _RiderProfileFormState();
}

/// The time zone column is VARCHAR(64); the server checks it is a real IANA zone.
const _timezoneMaxLength = 64;

class _RiderProfileFormState extends ConsumerState<_RiderProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _costs = RiderProfileControllers(widget.initial);
  late final _timezone = TextEditingController(text: widget.initial.timezone);
  late VehicleType? _vehicleType = widget.initial.vehicleType;

  @override
  void dispose() {
    _costs.dispose();
    _timezone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final ok = await ref
        .read(riderProfileFormProvider.notifier)
        .save(
          RiderProfileInput(
            vehicleType: _vehicleType,
            fuelKmPerLiter: _costs.fuelKmPerLiterValue,
            fuelPricePerLiter: _costs.fuelPricePerLiterValue,
            depreciationPerKm: _costs.depreciationPerKmValue,
            timezone: _timezone.text.trim(),
            currency: widget.initial.currency,
          ),
        );
    if (ok && mounted) closeForm(context, l10n.recordSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = Validators(l10n);
    final submit = ref.watch(riderProfileFormProvider);
    final busy = submit.isLoading;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.riderProfileTitle)),
      body: FormLayout(
        subtitle: l10n.onboardingDescription,
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RiderProfileFields(
                  keyPrefix: 'riderProfile',
                  controllers: _costs,
                  vehicleType: _vehicleType,
                  enabled: !busy,
                  lastAction: TextInputAction.next,
                  onVehicleTypeChanged: (value) =>
                      setState(() => _vehicleType = value),
                ),
                formGap,
                AppTextField(
                  key: const Key('riderProfile.timezone'),
                  controller: _timezone,
                  label: l10n.profileTimezone,
                  helperText: l10n.riderProfileTimezoneHelper,
                  prefixIcon: Icons.schedule_outlined,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  maxLength: _timezoneMaxLength,
                  enabled: !busy,
                  validator: (value) =>
                      v.required(value) ??
                      v.optionalText(value, max: _timezoneMaxLength),
                ),
              ],
            ),
          ),
          formGap,
          AppBanner(
            message: l10n.riderProfileCurrency(widget.initial.currency),
          ),
          formGap,
          if (submit case AsyncError(:final AppFailure error)) ...[
            AppBanner.failure(context, error),
            formGap,
          ],
          AppPrimaryButton(
            key: const Key('riderProfile.submit'),
            label: l10n.recordSave,
            isLoading: busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
