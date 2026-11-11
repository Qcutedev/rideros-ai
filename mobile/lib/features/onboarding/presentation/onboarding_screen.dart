import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/presentation/submit_notifier.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/form_layout.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/session_controller.dart';
import '../../profile/data/rider_profile_repository_impl.dart';
import '../../profile/domain/rider_profile.dart';
import '../../profile/presentation/rider_profile_fields.dart';

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
  final _costs = RiderProfileControllers();
  VehicleType? _vehicleType;

  @override
  void dispose() {
    _costs.dispose();
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
            fuelKmPerLiter: _costs.fuelKmPerLiterValue,
            fuelPricePerLiter: _costs.fuelPricePerLiterValue,
            depreciationPerKm: _costs.depreciationPerKmValue,
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
    final submit = ref.watch(onboardingControllerProvider);
    final busy = submit.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle)),
      body: FormLayout(
        subtitle: l10n.onboardingDescription,
        children: [
          Form(
            key: _formKey,
            child: RiderProfileFields(
              keyPrefix: 'onboarding',
              controllers: _costs,
              vehicleType: _vehicleType,
              enabled: !busy,
              onVehicleTypeChanged: (value) =>
                  setState(() => _vehicleType = value),
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
}
