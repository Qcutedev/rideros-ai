import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/rider_profile.dart';
import 'vehicle_type_label.dart';

/// Text of the three cost fields shared by onboarding and the rider profile form.
class RiderProfileControllers {
  RiderProfileControllers([RiderProfile? initial])
    : fuelKmPerLiter = TextEditingController(
        text: _text(initial?.fuelKmPerLiter),
      ),
      fuelPricePerLiter = TextEditingController(
        text: _text(initial?.fuelPricePerLiter),
      ),
      depreciationPerKm = TextEditingController(
        text: _text(initial?.depreciationPerKm),
      );

  final TextEditingController fuelKmPerLiter;
  final TextEditingController fuelPricePerLiter;
  final TextEditingController depreciationPerKm;

  Decimal? get fuelKmPerLiterValue => _decimal(fuelKmPerLiter);
  Decimal? get fuelPricePerLiterValue => _decimal(fuelPricePerLiter);
  Decimal? get depreciationPerKmValue => _decimal(depreciationPerKm);

  void dispose() {
    fuelKmPerLiter.dispose();
    fuelPricePerLiter.dispose();
    depreciationPerKm.dispose();
  }

  static String _text(Decimal? value) =>
      value == null ? '' : Formats.decimalInput(value);

  static Decimal? _decimal(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : parseDecimalInput(text);
  }
}

/// Vehicle type + fuel economy + fuel price + depreciation. Every field is optional,
/// like the API. Keys: `<keyPrefix>.vehicleType`, `.fuelKmPerLiter`, `.fuelPrice`,
/// `.depreciation`.
class RiderProfileFields extends StatelessWidget {
  const RiderProfileFields({
    required this.keyPrefix,
    required this.controllers,
    required this.vehicleType,
    required this.onVehicleTypeChanged,
    this.enabled = true,
    this.lastAction = TextInputAction.done,
    super.key,
  });

  final String keyPrefix;
  final RiderProfileControllers controllers;
  final VehicleType? vehicleType;
  final ValueChanged<VehicleType?> onVehicleTypeChanged;
  final bool enabled;

  /// Keyboard action of the depreciation field (the last one here).
  final TextInputAction lastAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final validators = Validators(l10n);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: l10n.onboardingVehicleType,
          child: DropdownButtonFormField<VehicleType?>(
            key: Key('$keyPrefix.vehicleType'),
            // Same text size as the other inputs (default is titleMedium).
            style: Theme.of(context).textTheme.bodyLarge,
            initialValue: vehicleType,
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
            onChanged: enabled ? onVehicleTypeChanged : null,
          ),
        ),
        formGap,
        AppTextField(
          key: Key('$keyPrefix.fuelKmPerLiter'),
          controller: controllers.fuelKmPerLiter,
          label: l10n.onboardingFuelKmPerLiter,
          helperText: l10n.commonOptional,
          keyboardType: numberKeyboard,
          prefixIcon: Icons.local_gas_station_outlined,
          validator: (v) =>
              decimalRule(v, RiderProfileLimits.fuelKmPerLiter, positive: true),
          enabled: enabled,
        ),
        formGap,
        AppTextField(
          key: Key('$keyPrefix.fuelPrice'),
          controller: controllers.fuelPricePerLiter,
          label: l10n.onboardingFuelPricePerLiter,
          helperText: l10n.commonOptional,
          keyboardType: numberKeyboard,
          prefixIcon: Icons.payments_outlined,
          validator: (v) =>
              decimalRule(v, RiderProfileLimits.fuelPricePerLiter),
          enabled: enabled,
        ),
        formGap,
        AppTextField(
          key: Key('$keyPrefix.depreciation'),
          controller: controllers.depreciationPerKm,
          label: l10n.onboardingDepreciationPerKm,
          helperText: l10n.commonOptional,
          keyboardType: numberKeyboard,
          textInputAction: lastAction,
          prefixIcon: Icons.build_outlined,
          validator: (v) =>
              decimalRule(v, RiderProfileLimits.depreciationPerKm),
          enabled: enabled,
        ),
      ],
    );
  }
}
