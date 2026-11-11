import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/pickup_models.dart';
import 'pickup_providers.dart';

/// `/pickup/own-restaurant` (S-OWN-RESTAURANT-FORM): a private restaurant for the
/// Pickup Log. Name required; the location is optional (both or neither) and only
/// the rider sees it.
class OwnRestaurantFormScreen extends ConsumerStatefulWidget {
  const OwnRestaurantFormScreen({super.key});

  @override
  ConsumerState<OwnRestaurantFormScreen> createState() =>
      _OwnRestaurantFormScreenState();
}

class _OwnRestaurantFormScreenState
    extends ConsumerState<OwnRestaurantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    final ok = await ref
        .read(ownRestaurantFormProvider.notifier)
        .createRestaurant(
          RestaurantInput(
            name: _name.text.trim(),
            location: lat == null || lng == null
                ? null
                : Coordinates(lat: lat, lng: lng),
          ),
        );
    if (ok && mounted) closeForm(context, l10n.ownFormSaved);
  }

  /// Optional coordinate in [-limit, limit]; required when the other one is set.
  String? _coordinate(
    AppLocalizations l10n,
    String? value,
    TextEditingController other,
    double limit,
  ) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return other.text.trim().isEmpty ? null : l10n.ownFormLocationPair;
    }
    final parsed = parseDecimalInput(text);
    if (parsed == null) return l10n.validationNumberInvalid;
    final number = parsed.toDouble();
    if (number < -limit || number > limit) {
      return l10n.validationRange('-${limit.toInt()}', '${limit.toInt()}');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final v = Validators(l10n);
    final submit = ref.watch(ownRestaurantFormProvider);
    final busy = submit.isLoading;
    const coordinateKeyboard = TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    );
    return RecordFormScaffold(
      keyPrefix: 'ownForm',
      title: l10n.ownFormTitle,
      formKey: _formKey,
      submit: submit,
      onSave: _save,
      fields: [
        AppTextField(
          key: const Key('ownForm.name'),
          controller: _name,
          label: l10n.ownFormName,
          maxLength: PickupLimits.restaurantNameMaxLength,
          prefixIcon: Icons.storefront_outlined,
          enabled: !busy,
          validator: (value) =>
              v.required(value) ??
              v.optionalText(value, max: PickupLimits.restaurantNameMaxLength),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.ownFormLocationTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.ownFormLocationHelper,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AppTextField(
          key: const Key('ownForm.lat'),
          controller: _lat,
          label: l10n.ownFormLat,
          keyboardType: coordinateKeyboard,
          prefixIcon: Icons.place_outlined,
          enabled: !busy,
          validator: (value) => _coordinate(l10n, value, _lng, 90),
        ),
        AppTextField(
          key: const Key('ownForm.lng'),
          controller: _lng,
          label: l10n.ownFormLng,
          keyboardType: coordinateKeyboard,
          prefixIcon: Icons.place_outlined,
          enabled: !busy,
          validator: (value) => _coordinate(l10n, value, _lat, 180),
        ),
      ],
    );
  }
}
