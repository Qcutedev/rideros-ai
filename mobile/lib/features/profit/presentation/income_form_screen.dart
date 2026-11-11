import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_json.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/profit_records.dart';
import 'profit_labels.dart';
import 'profit_providers.dart';

/// `/income/new` and `/income/:id`.
class IncomeFormScreen extends ConsumerWidget {
  const IncomeFormScreen({this.id, super.key});

  /// `null` = new record.
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = this.id;
    if (id == null) return const _IncomeForm();
    return RecordLoader<Income>(
      provider: incomeDetailProvider(id),
      title: l10n.incomeEditTitle,
      onRetry: () => ref.invalidate(incomeDetailProvider(id)),
      builder: (income) => _IncomeForm(initial: income),
    );
  }
}

class _IncomeForm extends ConsumerStatefulWidget {
  const _IncomeForm({this.initial});

  final Income? initial;

  @override
  ConsumerState<_IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends ConsumerState<_IncomeForm> {
  final _formKey = GlobalKey<FormState>();
  late final Income? _initial = widget.initial;
  late final _amount = TextEditingController(text: fieldText(_initial?.amount));
  late final _source = TextEditingController(text: _initial?.sourceLabel);
  late final _hours = TextEditingController(
    text: fieldText(_initial?.workingHours),
  );
  late final _orders = TextEditingController(
    text: fieldText(_initial?.orderCount),
  );
  late final _distance = TextEditingController(
    text: fieldText(_initial?.distanceKm),
  );
  late final _notes = TextEditingController(text: _initial?.notes);
  late DateTime _date =
      _initial?.occurredOn ?? dateOnly(ref.read(clockProvider)());
  late String? _sessionId = _initial?.workSessionId;

  @override
  void dispose() {
    for (final c in [_amount, _source, _hours, _orders, _distance, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final linked = _sessionId != null;
    final ok = await ref
        .read(incomeFormProvider.notifier)
        .save(
          _initial?.id,
          IncomeInput(
            occurredOn: _date,
            amount: parseDecimalInput(_amount.text)!,
            workSessionId: _sessionId,
            sourceLabel: optionalTextOf(_source),
            // Hours of a linked record come from its work session.
            workingHours: linked ? null : optionalDecimalOf(_hours),
            orderCount: optionalIntOf(_orders),
            distanceKm: optionalDecimalOf(_distance),
            notes: optionalTextOf(_notes),
          ),
        );
    if (ok && mounted) closeForm(context, l10n.recordSaved);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    if (!await confirmDelete(context)) return;
    final ok = await ref.read(incomeFormProvider.notifier).delete(_initial!.id);
    if (ok && mounted) closeForm(context, l10n.recordDeleted);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = Validators(l10n);
    final submit = ref.watch(incomeFormProvider);
    final busy = submit.isLoading;
    final today = dateOnly(ref.watch(clockProvider)());

    return RecordFormScaffold(
      keyPrefix: 'income',
      title: _initial == null ? l10n.incomeAdd : l10n.incomeEditTitle,
      formKey: _formKey,
      submit: submit,
      onSave: _save,
      onDelete: _initial == null ? null : _delete,
      fields: [
        DateField(
          key: const Key('income.date'),
          label: l10n.fieldDate,
          value: _date,
          lastDate: today,
          enabled: !busy,
          onChanged: (date) => setState(() {
            if (date != _date) _sessionId = null;
            _date = date;
          }),
        ),
        AppTextField(
          key: const Key('income.amount'),
          controller: _amount,
          label: l10n.fieldAmount,
          keyboardType: decimalKeyboard,
          prefixIcon: Icons.payments_outlined,
          enabled: !busy,
          validator: (value) => v.requiredDecimal(
            value,
            maxDigits: ProfitLimits.money.maxDigits,
            places: ProfitLimits.money.places,
          ),
        ),
        AppTextField(
          key: const Key('income.source'),
          controller: _source,
          label: l10n.incomeSourceLabel,
          helperText: l10n.incomeSourceHelper,
          maxLength: ProfitLimits.sourceLabelMaxLength,
          prefixIcon: Icons.storefront_outlined,
          enabled: !busy,
          validator: (value) =>
              v.optionalText(value, max: ProfitLimits.sourceLabelMaxLength),
        ),
        _SessionPicker(
          date: _date,
          value: _sessionId,
          enabled: !busy,
          onChanged: (id) => setState(() => _sessionId = id),
        ),
        if (_sessionId == null)
          AppTextField(
            key: const Key('income.hours'),
            controller: _hours,
            label: l10n.fieldWorkingHours,
            helperText: l10n.incomeHoursHelper,
            keyboardType: decimalKeyboard,
            prefixIcon: Icons.timer_outlined,
            enabled: !busy,
            validator: (value) => v.optionalDecimal(
              value,
              maxDigits: ProfitLimits.hours.maxDigits,
              places: ProfitLimits.hours.places,
              positive: true,
              max: ProfitLimits.maxHours,
            ),
          ),
        AppTextField(
          key: const Key('income.orders'),
          controller: _orders,
          label: l10n.fieldOrderCount,
          helperText: l10n.commonOptional,
          keyboardType: intKeyboard,
          prefixIcon: Icons.shopping_bag_outlined,
          enabled: !busy,
          validator: (value) =>
              v.optionalInt(value, max: ProfitLimits.maxOrderCount),
        ),
        AppTextField(
          key: const Key('income.distance'),
          controller: _distance,
          label: l10n.fieldDistanceKm,
          helperText: l10n.commonOptional,
          keyboardType: decimalKeyboard,
          prefixIcon: Icons.route_outlined,
          enabled: !busy,
          validator: (value) => v.optionalDecimal(
            value,
            maxDigits: ProfitLimits.distanceKm.maxDigits,
            places: ProfitLimits.distanceKm.places,
          ),
        ),
        AppTextField(
          key: const Key('income.notes'),
          controller: _notes,
          label: l10n.fieldNotes,
          helperText: l10n.commonOptional,
          maxLength: ProfitLimits.notesMaxLength,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          enabled: !busy,
          validator: (value) =>
              v.optionalText(value, max: ProfitLimits.notesMaxLength),
        ),
      ],
    );
  }
}

/// Optional link to one of the rider's work sessions that started on [date].
class _SessionPicker extends ConsumerWidget {
  const _SessionPicker({
    required this.date,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final DateTime date;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LabeledField(
    label: AppLocalizations.of(context).incomeSessionLabel,
    child: _field(context, ref),
  );

  Widget _field(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sessions = ref.watch(workSessionsOnDateProvider(date));
    final decoration = InputDecoration(
      helperText: l10n.incomeSessionHelper,
      helperMaxLines: 2,
      prefixIcon: const Icon(Icons.link_rounded),
    );

    switch (sessions) {
      case AsyncError():
        return InputDecorator(
          decoration: decoration.copyWith(
            errorText: l10n.incomeSessionLoadFailed,
            helperText: null,
            suffixIcon: IconButton(
              key: const Key('income.session.retry'),
              tooltip: l10n.commonRetry,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(workSessionsOnDateProvider(date)),
            ),
          ),
          child: Text(l10n.incomeSessionNone),
        );
      case AsyncData(value: final list):
        final ids = {for (final s in list) s.id};
        return DropdownButtonFormField<String?>(
          key: const Key('income.session'),
          // Same text size as the other inputs (default is titleMedium).
          style: Theme.of(context).textTheme.bodyLarge,
          initialValue: value,
          isExpanded: true,
          decoration: decoration,
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.incomeSessionNone)),
            for (final session in list)
              DropdownMenuItem(
                value: session.id,
                child: Text(sessionTimeRange(l10n, session)),
              ),
            // Linked to a session of another day (saved elsewhere): keep it selectable.
            if (value != null && !ids.contains(value))
              DropdownMenuItem(
                value: value,
                child: Text(l10n.incomeSessionOtherDay),
              ),
          ],
          onChanged: enabled ? onChanged : null,
        );
      default:
        return InputDecorator(
          decoration: decoration,
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.commonLoading),
            ],
          ),
        );
    }
  }
}
