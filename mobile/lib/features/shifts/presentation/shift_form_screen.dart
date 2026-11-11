import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../profit/presentation/profit_labels.dart';
import '../domain/shift_models.dart';
import 'shift_labels.dart';
import 'shift_providers.dart';

/// `/shifts/new` and `/shifts/edit/:id` (S-SHIFT-FORM). Saving estimates at once;
/// a new scenario then opens its details.
class ShiftFormScreen extends ConsumerWidget {
  const ShiftFormScreen({this.id, super.key});

  /// `null` = new scenario.
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = this.id;
    if (id == null) return const _ShiftForm();
    return RecordLoader<ShiftScenario>(
      provider: shiftScenarioProvider(id),
      title: l10n.shiftEditTitle,
      onRetry: () => ref.invalidate(shiftScenarioProvider(id)),
      builder: (scenario) => _ShiftForm(initial: scenario),
    );
  }
}

typedef _Limit = ({int maxDigits, int places, Decimal max});

class _ShiftForm extends ConsumerStatefulWidget {
  const _ShiftForm({this.initial});

  final ShiftScenario? initial;

  @override
  ConsumerState<_ShiftForm> createState() => _ShiftFormState();
}

class _ShiftFormState extends ConsumerState<_ShiftForm> {
  final _formKey = GlobalKey<FormState>();
  late final ShiftScenario? _initial = widget.initial;
  late final ShiftAssumptions _a =
      _initial?.assumptions ?? const ShiftAssumptions();

  late final _name = TextEditingController(text: _initial?.name);
  late final _ordersPerHour = TextEditingController(
    text: fieldText(_a.ordersPerHour),
  );
  late final _incomePerOrder = TextEditingController(
    text: fieldText(_a.incomePerOrder),
  );
  late final _kmPerOrder = TextEditingController(
    text: fieldText(_a.kmPerOrder),
  );
  late final _fuelKmPerLiter = TextEditingController(
    text: fieldText(_a.fuelKmPerLiter),
  );
  late final _fuelPrice = TextEditingController(
    text: fieldText(_a.fuelPricePerLiter),
  );
  late final _depreciation = TextEditingController(
    text: fieldText(_a.depreciationPerKm),
  );
  late final _otherCosts = TextEditingController(
    text: fieldText(_a.otherCosts),
  );

  late ClockTime _start = _initial?.startTime ?? const ClockTime(17, 0);
  late ClockTime _end = _initial?.endTime ?? const ClockTime(22, 0);
  late int? _weekday = _initial?.plannedWeekday;
  late EstimationMethod _method = switch (_initial?.estimationMethod) {
    EstimationMethod.historical => EstimationMethod.historical,
    _ => EstimationMethod.assumption,
  };

  /// Shown under the end time after a save attempt with a bad length.
  bool _showLengthError = false;

  List<TextEditingController> get _controllers => [
    _name,
    _ordersPerHour,
    _incomePerOrder,
    _kmPerOrder,
    _fuelKmPerLiter,
    _fuelPrice,
    _depreciation,
    _otherCosts,
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  int get _minutes => shiftMinutes(_start, _end);

  ShiftAssumptions get _assumptions => _method == EstimationMethod.historical
      // The historical method only reads the fixed costs.
      ? ShiftAssumptions(otherCosts: optionalDecimalOf(_otherCosts))
      : ShiftAssumptions(
          ordersPerHour: optionalDecimalOf(_ordersPerHour),
          incomePerOrder: optionalDecimalOf(_incomePerOrder),
          kmPerOrder: optionalDecimalOf(_kmPerOrder),
          fuelKmPerLiter: optionalDecimalOf(_fuelKmPerLiter),
          fuelPricePerLiter: optionalDecimalOf(_fuelPrice),
          depreciationPerKm: optionalDecimalOf(_depreciation),
          otherCosts: optionalDecimalOf(_otherCosts),
        );

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final lengthOk = isValidShiftLength(_minutes);
    final fieldsValid = _formKey.currentState!.validate();
    if (!lengthOk) setState(() => _showLengthError = true);
    if (!fieldsValid || !lengthOk) return;
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(shiftFormProvider.notifier);
    final ok = await controller.save(
      _initial?.id,
      ShiftScenarioInput(
        name: _name.text.trim(),
        startTime: _start,
        endTime: _end,
        plannedWeekday: _weekday,
        estimationMethod: _method,
        assumptions: _assumptions,
      ),
    );
    if (!ok || !mounted) return;
    final saved = controller.saved;
    if (_initial == null && saved != null) {
      // Leave the form for the new scenario's details (list underneath). The
      // details are the confirmation: no snackbar, which the shell's Scaffold
      // would float over the list's compare bar after going back.
      context.go(Routes.shiftDetail(saved.id));
    } else {
      closeForm(context, l10n.recordSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = Validators(l10n);
    final submit = ref.watch(shiftFormProvider);
    final busy = submit.isLoading;
    final historyDays = ref.watch(workedHistoryDaysProvider);
    // Unknown (request failed) = offer it; the server checks the history again.
    final historyAvailable =
        _method == EstimationMethod.historical ||
        historyDays.hasError ||
        (historyDays.value ?? 0) >= ShiftLimits.minHistoryDays;
    final minutes = _minutes;
    final lengthOk = isValidShiftLength(minutes);

    String? decimal(String? value, _Limit limit, {bool required = false}) {
      final missing = required ? v.required(value) : null;
      return missing ??
          v.optionalDecimal(
            value,
            maxDigits: limit.maxDigits,
            places: limit.places,
            max: limit.max,
          );
    }

    String? positiveDecimal(String? value, _Limit limit) => v.optionalDecimal(
      value,
      maxDigits: limit.maxDigits,
      places: limit.places,
      max: limit.max,
      positive: true,
    );

    Widget number(
      String key,
      TextEditingController controller,
      String label, {
      required String? Function(String?) validator,
      String? helper,
      IconData? icon,
    }) => AppTextField(
      key: Key('shiftForm.$key'),
      controller: controller,
      label: label,
      helperText: helper,
      keyboardType: decimalKeyboard,
      prefixIcon: icon,
      enabled: !busy,
      validator: validator,
    );

    return RecordFormScaffold(
      keyPrefix: 'shiftForm',
      title: _initial == null ? l10n.shiftNewTitle : l10n.shiftEditTitle,
      formKey: _formKey,
      submit: submit,
      onSave: _save,
      fields: [
        AppTextField(
          key: const Key('shiftForm.name'),
          controller: _name,
          label: l10n.shiftFieldName,
          helperText: l10n.shiftFieldNameHint,
          maxLength: ShiftLimits.nameMaxLength,
          prefixIcon: Icons.edit_note_rounded,
          enabled: !busy,
          validator: (value) =>
              v.required(value) ??
              v.optionalText(value, max: ShiftLimits.nameMaxLength),
        ),
        TimeField(
          key: const Key('shiftForm.start'),
          label: l10n.shiftFieldStart,
          value: TimeOfDay(hour: _start.hour, minute: _start.minute),
          enabled: !busy,
          onChanged: (t) =>
              setState(() => _start = ClockTime(t.hour, t.minute)),
        ),
        TimeField(
          key: const Key('shiftForm.end'),
          label: l10n.shiftFieldEnd,
          value: TimeOfDay(hour: _end.hour, minute: _end.minute),
          enabled: !busy,
          errorText: !lengthOk && _showLengthError
              ? l10n.shiftLengthInvalid
              : null,
          helperText: lengthOk
              ? [
                  l10n.sessionDuration(
                    durationLabel(l10n, Duration(minutes: minutes)),
                  ),
                  if (_end.minutesOfDay <= _start.minutesOfDay)
                    l10n.sessionCrossesMidnight,
                ].join(' · ')
              : l10n.shiftLengthInvalid,
          onChanged: (t) => setState(() => _end = ClockTime(t.hour, t.minute)),
        ),
        LabeledField(
          label: l10n.shiftFieldWeekday,
          child: DropdownButtonFormField<int?>(
            key: const Key('shiftForm.weekday'),
            style: Theme.of(context).textTheme.bodyLarge,
            initialValue: _weekday,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.calendar_view_week_outlined),
              helperText: l10n.shiftWeekdayHelper,
              helperMaxLines: 2,
            ),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.shiftAnyDay)),
              for (var day = 0; day < 7; day++)
                DropdownMenuItem(
                  value: day,
                  child: Text(weekdayLabel(l10n, day)),
                ),
            ],
            onChanged: busy ? null : (day) => setState(() => _weekday = day),
          ),
        ),
        _MethodField(
          method: _method,
          historyAvailable: historyAvailable,
          historyDays: historyDays.value,
          enabled: !busy,
          onChanged: (method) => setState(() => _method = method),
        ),
        if (_method == EstimationMethod.assumption) ...[
          SectionHeader(title: l10n.shiftAssumptionsTitle),
          number(
            'ordersPerHour',
            _ordersPerHour,
            l10n.shiftFieldOrdersPerHour,
            icon: Icons.shopping_bag_outlined,
            validator: (value) =>
                decimal(value, ShiftLimits.ordersPerHour, required: true),
          ),
          number(
            'incomePerOrder',
            _incomePerOrder,
            l10n.shiftFieldIncomePerOrder,
            icon: Icons.payments_outlined,
            validator: (value) =>
                decimal(value, ShiftLimits.incomePerOrder, required: true),
          ),
          number(
            'kmPerOrder',
            _kmPerOrder,
            l10n.shiftFieldKmPerOrder,
            helper: l10n.shiftKmPerOrderHelper,
            icon: Icons.route_outlined,
            validator: (value) => decimal(value, ShiftLimits.kmPerOrder),
          ),
          number(
            'fuelKmPerLiter',
            _fuelKmPerLiter,
            l10n.onboardingFuelKmPerLiter,
            helper: l10n.shiftProfileFallbackHelper,
            icon: Icons.local_gas_station_outlined,
            validator: (value) =>
                positiveDecimal(value, ShiftLimits.fuelKmPerLiter),
          ),
          number(
            'fuelPrice',
            _fuelPrice,
            l10n.onboardingFuelPricePerLiter,
            helper: l10n.shiftProfileFallbackHelper,
            icon: Icons.local_gas_station_outlined,
            validator: (value) => decimal(value, ShiftLimits.fuelPricePerLiter),
          ),
          number(
            'depreciation',
            _depreciation,
            l10n.onboardingDepreciationPerKm,
            helper: l10n.shiftProfileFallbackHelper,
            icon: Icons.build_outlined,
            validator: (value) => decimal(value, ShiftLimits.depreciationPerKm),
          ),
        ],
        number(
          'otherCosts',
          _otherCosts,
          l10n.shiftFieldOtherCosts,
          helper: l10n.shiftOtherCostsHelper,
          icon: Icons.receipt_long_outlined,
          validator: (value) => decimal(value, ShiftLimits.otherCosts),
        ),
        AppBanner(message: l10n.shiftFormEstimateNote),
      ],
    );
  }
}

/// Assumption (default) or the rider's history. History is only offered with
/// enough worked days; otherwise a note says how many there are. ML is never
/// shown (the API has no model for it).
class _MethodField extends StatelessWidget {
  const _MethodField({
    required this.method,
    required this.historyAvailable,
    required this.historyDays,
    required this.enabled,
    required this.onChanged,
  });

  final EstimationMethod method;
  final bool historyAvailable;
  final int? historyDays;
  final bool enabled;
  final ValueChanged<EstimationMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hint = method == EstimationMethod.historical
        ? l10n.shiftMethodHistoricalHint
        : l10n.shiftMethodAssumptionHint;
    final days = historyDays;
    return LabeledField(
      label: l10n.shiftFieldMethod,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (historyAvailable)
            SegmentedButton<EstimationMethod>(
              key: const Key('shiftForm.method'),
              showSelectedIcon: false,
              segments: [
                for (final m in const [
                  EstimationMethod.assumption,
                  EstimationMethod.historical,
                ])
                  ButtonSegment(
                    value: m,
                    label: Text(
                      methodLabel(l10n, m),
                      key: Key('shiftForm.method.${m.name}'),
                    ),
                  ),
              ],
              selected: {method},
              onSelectionChanged: enabled
                  ? (selection) => onChanged(selection.single)
                  : null,
            )
          else
            Text(
              methodLabel(l10n, EstimationMethod.assumption),
              key: const Key('shiftForm.methodFixed'),
              style: theme.textTheme.bodyLarge,
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(hint, style: theme.textTheme.bodySmall),
          if (!historyAvailable && days != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.shiftHistoryUnavailable(days),
              key: const Key('shiftForm.historyUnavailable'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
