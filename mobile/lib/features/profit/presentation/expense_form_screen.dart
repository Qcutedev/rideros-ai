import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/clock.dart';
import '../../../core/utils/date_json.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/profit_records.dart';
import 'profit_labels.dart';
import 'profit_providers.dart';
import 'widgets/record_form_widgets.dart';

/// `/expenses/new` and `/expenses/:id`.
class ExpenseFormScreen extends ConsumerWidget {
  const ExpenseFormScreen({this.id, super.key});

  /// `null` = new record.
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = this.id;
    if (id == null) return const _ExpenseForm();
    return RecordLoader<Expense>(
      provider: expenseDetailProvider(id),
      title: l10n.expenseEditTitle,
      onRetry: () => ref.invalidate(expenseDetailProvider(id)),
      builder: (expense) => _ExpenseForm(initial: expense),
    );
  }
}

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({this.initial});

  final Expense? initial;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final Expense? _initial = widget.initial;
  late final _amount = TextEditingController(text: fieldText(_initial?.amount));
  late final _description = TextEditingController(text: _initial?.description);
  late DateTime _date =
      _initial?.occurredOn ?? dateOnly(ref.read(clockProvider)());
  late ExpenseCategory? _category = _initial?.category;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final ok = await ref
        .read(expenseFormProvider.notifier)
        .save(
          _initial?.id,
          ExpenseInput(
            occurredOn: _date,
            category: _category!,
            amount: parseDecimalInput(_amount.text)!,
            description: optionalTextOf(_description),
          ),
        );
    if (ok && mounted) closeForm(context, l10n.recordSaved);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    if (!await confirmDelete(context)) return;
    final ok = await ref
        .read(expenseFormProvider.notifier)
        .delete(_initial!.id);
    if (ok && mounted) closeForm(context, l10n.recordDeleted);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = Validators(l10n);
    final submit = ref.watch(expenseFormProvider);
    final busy = submit.isLoading;
    final today = dateOnly(ref.watch(clockProvider)());

    return RecordFormScaffold(
      keyPrefix: 'expense',
      title: _initial == null ? l10n.expenseAdd : l10n.expenseEditTitle,
      formKey: _formKey,
      submit: submit,
      onSave: _save,
      onDelete: _initial == null ? null : _delete,
      fields: [
        DateField(
          key: const Key('expense.date'),
          label: l10n.fieldDate,
          value: _date,
          lastDate: today,
          enabled: !busy,
          onChanged: (date) => setState(() => _date = date),
        ),
        LabeledField(
          label: l10n.expenseCategoryLabel,
          child: DropdownButtonFormField<ExpenseCategory>(
            key: const Key('expense.category'),
            // Same text size as the other inputs (default is titleMedium).
            style: Theme.of(context).textTheme.bodyLarge,
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.category_outlined),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) =>
                value == null ? l10n.validationRequired : null,
            items: [
              for (final category in ExpenseCategory.values)
                DropdownMenuItem(
                  value: category,
                  child: Text(expenseCategoryLabel(l10n, category)),
                ),
            ],
            onChanged: busy
                ? null
                : (value) => setState(() => _category = value),
          ),
        ),
        AppTextField(
          key: const Key('expense.amount'),
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
          key: const Key('expense.description'),
          controller: _description,
          label: l10n.expenseDescriptionLabel,
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
