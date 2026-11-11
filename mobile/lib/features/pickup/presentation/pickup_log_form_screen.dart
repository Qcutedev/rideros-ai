import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_json.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../profit/presentation/profit_labels.dart';
import '../domain/pickup_models.dart';
import '../domain/pickup_times.dart';
import 'pickup_providers.dart';

/// The restaurant chosen in the log form.
typedef ChosenRestaurant = ({String id, String name});

/// `/pickup/logs/new` (S-PICKUP-LOG-FORM): restaurant, arrival date and time,
/// pickup time, notes. `?restaurant_id=&restaurant_name=` preselects the
/// restaurant (from its detail screen or a prediction).
class PickupLogFormScreen extends ConsumerStatefulWidget {
  const PickupLogFormScreen({this.restaurant, super.key});

  final ChosenRestaurant? restaurant;

  @override
  ConsumerState<PickupLogFormScreen> createState() =>
      _PickupLogFormScreenState();
}

class _PickupLogFormScreenState extends ConsumerState<PickupLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  late ChosenRestaurant? _restaurant = widget.restaurant;
  late DateTime _date;
  late TimeOfDay _arrived;
  late TimeOfDay _pickedUp;

  /// Errors appear after the first save attempt.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Default: arrived 10 minutes ago, picked up now (whole minutes).
    final now = ref.read(clockProvider)();
    final pickedUp = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    final arrived = pickedUp.subtract(const Duration(minutes: 10));
    _date = dateOnly(arrived);
    _arrived = TimeOfDay.fromDateTime(arrived);
    _pickedUp = TimeOfDay.fromDateTime(pickedUp);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  ({DateTime arrivedAt, DateTime pickedUpAt}) get _times => pickupTimes(
    _date,
    (hour: _arrived.hour, minute: _arrived.minute),
    (hour: _pickedUp.hour, minute: _pickedUp.minute),
  );

  Future<void> _chooseRestaurant() async {
    final picked = await context.push<Restaurant>(Routes.restaurantPicker);
    if (picked != null && mounted) {
      setState(() => _restaurant = (id: picked.id, name: picked.name));
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    final times = _times;
    final fieldsValid = _formKey.currentState!.validate();
    final restaurant = _restaurant;
    if (!fieldsValid ||
        restaurant == null ||
        isWaitTooLong(times.arrivedAt, times.pickedUpAt)) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final ok = await ref
        .read(pickupLogFormProvider.notifier)
        .createLog(
          PickupLogInput(
            restaurantId: restaurant.id,
            arrivedAt: times.arrivedAt,
            pickedUpAt: times.pickedUpAt,
            notes: optionalTextOf(_notes),
          ),
        );
    if (ok && mounted) closeForm(context, l10n.recordSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = Validators(l10n);
    final submit = ref.watch(pickupLogFormProvider);
    final busy = submit.isLoading;
    final today = dateOnly(ref.watch(clockProvider)());
    final times = _times;
    final tooLong = isWaitTooLong(times.arrivedAt, times.pickedUpAt);
    final nextDay = times.pickedUpAt.day != times.arrivedAt.day;

    return RecordFormScaffold(
      keyPrefix: 'logForm',
      title: l10n.logFormTitle,
      formKey: _formKey,
      submit: submit,
      onSave: _save,
      fields: [
        _RestaurantField(
          name: _restaurant?.name,
          enabled: !busy,
          errorText: _submitted && _restaurant == null
              ? l10n.logFormRestaurantRequired
              : null,
          onTap: _chooseRestaurant,
        ),
        DateField(
          key: const Key('logForm.date'),
          label: l10n.logFormDate,
          value: _date,
          lastDate: today,
          enabled: !busy,
          onChanged: (date) => setState(() => _date = date),
        ),
        TimeField(
          key: const Key('logForm.arrived'),
          label: l10n.logFormArrived,
          value: _arrived,
          enabled: !busy,
          onChanged: (time) => setState(() => _arrived = time),
        ),
        TimeField(
          key: const Key('logForm.pickedUp'),
          label: l10n.logFormPickedUp,
          value: _pickedUp,
          enabled: !busy,
          errorText: tooLong && _submitted ? l10n.logFormWaitTooLong : null,
          helperText: tooLong
              ? l10n.logFormWaitTooLong
              : [
                  l10n.logFormWait(
                    durationLabel(
                      l10n,
                      times.pickedUpAt.difference(times.arrivedAt),
                    ),
                  ),
                  if (nextDay) l10n.logFormNextDay,
                ].join(' · '),
          onChanged: (time) => setState(() => _pickedUp = time),
        ),
        AppTextField(
          key: const Key('logForm.notes'),
          controller: _notes,
          label: l10n.fieldNotes,
          helperText: l10n.commonOptional,
          maxLength: PickupLimits.notesMaxLength,
          maxLines: 3,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          enabled: !busy,
          validator: (value) =>
              v.optionalText(value, max: PickupLimits.notesMaxLength),
        ),
      ],
    );
  }
}

class _RestaurantField extends StatelessWidget {
  const _RestaurantField({
    required this.name,
    required this.enabled,
    required this.errorText,
    required this.onTap,
  });

  final String? name;
  final bool enabled;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = this.name;
    return LabeledField(
      label: l10n.logFormRestaurant,
      child: InkWell(
        key: const Key('logForm.restaurant'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: enabled ? onTap : null,
        child: InputDecorator(
          decoration: InputDecoration(
            enabled: enabled,
            errorText: errorText,
            prefixIcon: const Icon(Icons.storefront_outlined),
            suffixIcon: const Icon(Icons.chevron_right_rounded),
          ),
          child: Text(
            name ?? l10n.logFormChooseRestaurant,
            style: name == null
                ? theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : theme.textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
