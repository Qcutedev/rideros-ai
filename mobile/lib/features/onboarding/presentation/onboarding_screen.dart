import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/presentation/submit_notifier.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_layout.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/session_controller.dart';
import '../../profile/data/rider_profile_repository_impl.dart';
import '../../profile/domain/rider_profile.dart';
import '../../profile/presentation/vehicle_type_label.dart';

final onboardingControllerProvider =
    NotifierProvider.autoDispose<OnboardingController, AsyncValue<void>>(
      OnboardingController.new,
    );

/// Saves the first rider profile; afterwards the router guard moves on to home.
class OnboardingController extends SubmitNotifier {
  Future<bool> submit(RiderProfileInput input) => run(() async {
    await ref.read(riderProfileRepositoryProvider).save(input);
    ref.read(sessionControllerProvider.notifier).markProfileConfigured();
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fuelKmPerLiter = TextEditingController();
  final _fuelPrice = TextEditingController();
  final _depreciation = TextEditingController();
  VehicleType? _vehicleType;

  @override
  void dispose() {
    _fuelKmPerLiter.dispose();
    _fuelPrice.dispose();
    _depreciation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(onboardingControllerProvider.notifier)
        .submit(
          RiderProfileInput(
            vehicleType: _vehicleType,
            fuelKmPerLiter: _decimal(_fuelKmPerLiter),
            fuelPricePerLiter: _decimal(_fuelPrice),
            depreciationPerKm: _decimal(_depreciation),
          ),
        );
  }

  /// Saves the defaults (all optional values empty) so onboarding is not shown again.
  Future<void> _skip() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(onboardingControllerProvider.notifier)
        .submit(const RiderProfileInput());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final validators = Validators(l10n);
    final submit = ref.watch(onboardingControllerProvider);
    final busy = submit.isLoading;
    const numberKeyboard = TextInputType.numberWithOptions(decimal: true);

    String? decimalRule(
      String? value,
      ({int maxDigits, int places}) limit, {
      bool positive = false,
    }) => validators.optionalDecimal(
      value,
      maxDigits: limit.maxDigits,
      places: limit.places,
      positive: positive,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle)),
      body: FormLayout(
        subtitle: l10n.onboardingDescription,
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: l10n.onboardingVehicleType,
                  child: DropdownButtonFormField<VehicleType?>(
                    key: const Key('onboarding.vehicleType'),
                    // Same text size as the other inputs (default is titleMedium).
                    style: Theme.of(context).textTheme.bodyLarge,
                    initialValue: _vehicleType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.two_wheeler_outlined),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(l10n.vehicleNotSpecified),
                      ),
                      for (final type in VehicleType.values)
                        DropdownMenuItem(
                          value: type,
                          child: Text(vehicleTypeLabel(l10n, type)),
                        ),
                    ],
                    onChanged: busy
                        ? null
                        : (value) => setState(() => _vehicleType = value),
                  ),
                ),
                formGap,
                AppTextField(
                  key: const Key('onboarding.fuelKmPerLiter'),
                  controller: _fuelKmPerLiter,
                  label: l10n.onboardingFuelKmPerLiter,
                  helperText: l10n.commonOptional,
                  keyboardType: numberKeyboard,
                  prefixIcon: Icons.local_gas_station_outlined,
                  validator: (v) => decimalRule(
                    v,
                    RiderProfileLimits.fuelKmPerLiter,
                    positive: true,
                  ),
                  enabled: !busy,
                ),
                formGap,
                AppTextField(
                  key: const Key('onboarding.fuelPrice'),
                  controller: _fuelPrice,
                  label: l10n.onboardingFuelPricePerLiter,
                  helperText: l10n.commonOptional,
                  keyboardType: numberKeyboard,
                  prefixIcon: Icons.payments_outlined,
                  validator: (v) =>
                      decimalRule(v, RiderProfileLimits.fuelPricePerLiter),
                  enabled: !busy,
                ),
                formGap,
                AppTextField(
                  key: const Key('onboarding.depreciation'),
                  controller: _depreciation,
                  label: l10n.onboardingDepreciationPerKm,
                  helperText: l10n.commonOptional,
                  keyboardType: numberKeyboard,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.build_outlined,
                  validator: (v) =>
                      decimalRule(v, RiderProfileLimits.depreciationPerKm),
                  enabled: !busy,
                ),
              ],
            ),
          ),
          formGap,
          AppBanner(
            message: l10n.onboardingRegion(RiderProfileDefaults.timezone),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (submit case AsyncError(:final AppFailure error)) ...[
            AppBanner.failure(context, error),
            formGap,
          ],
          AppPrimaryButton(
            key: const Key('onboarding.submit'),
            label: l10n.onboardingSubmit,
            isLoading: busy,
            onPressed: _save,
          ),
          formGap,
          AppSecondaryButton(
            key: const Key('onboarding.skip'),
            label: l10n.onboardingSkip,
            onPressed: busy ? null : _skip,
          ),
        ],
      ),
    );
  }

  static Decimal? _decimal(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : parseDecimalInput(text);
  }
}
