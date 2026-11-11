import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_shell.dart';
import '../../app/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../errors/app_failure.dart';
import '../utils/date_json.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import 'app_buttons.dart';
import 'app_text_field.dart';
import 'form_layout.dart';
import 'status_views.dart';

/// Earliest date the backend accepts for records (`occurred_on` 2000-01-01).
final firstRecordDate = DateTime.utc(2000);

/// Read-only field that opens the date picker. Values are date-only (UTC midnight).
class DateField extends StatelessWidget {
  const DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.lastDate,
    this.firstDate,
    this.enabled = true,
    super.key,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  /// Defaults to [firstRecordDate].
  final DateTime? firstDate;

  /// Usually today; never earlier than [value] so an existing record still opens.
  final DateTime lastDate;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final last = value.isAfter(lastDate) ? value : lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: _local(value),
      firstDate: _local(firstDate ?? firstRecordDate),
      lastDate: _local(last),
    );
    if (picked != null) onChanged(dateOnly(picked));
  }

  static DateTime _local(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LabeledField(
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: enabled ? () => _pick(context) : null,
        child: InputDecorator(
          isEmpty: false,
          decoration: InputDecoration(
            enabled: enabled,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            suffixIcon: const Icon(Icons.expand_more_rounded),
          ),
          child: Text(Formats.date(value, l10n.localeName)),
        ),
      ),
    );
  }
}

/// Read-only field that opens the time picker. [errorText] shows a validation error.
class TimeField extends StatelessWidget {
  const TimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.helperText,
    this.enabled = true,
    super.key,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;
  final String? errorText;
  final String? helperText;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: value,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return LabeledField(
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: enabled ? () => _pick(context) : null,
        child: InputDecorator(
          decoration: InputDecoration(
            enabled: enabled,
            errorText: errorText,
            helperText: helperText,
            helperMaxLines: 2,
            prefixIcon: const Icon(Icons.schedule_outlined),
            suffixIcon: const Icon(Icons.expand_more_rounded),
          ),
          child: Text(
            '$hh:$mm',
            style: AppTypography.figures(Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ),
    );
  }
}

/// Edit/create scaffold: title, delete action (edit only), form body, error banner
/// and the save button.
class RecordFormScaffold extends StatelessWidget {
  const RecordFormScaffold({
    required this.title,
    required this.formKey,
    required this.fields,
    required this.submit,
    required this.onSave,
    this.onDelete,
    this.keyPrefix = 'record',
    super.key,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final AsyncValue<void> submit;
  final VoidCallback onSave;

  /// `null` when creating.
  final VoidCallback? onDelete;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = submit.isLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onDelete != null)
            IconButton(
              key: Key('$keyPrefix.delete'),
              tooltip: l10n.recordDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: busy ? null : onDelete,
            ),
        ],
      ),
      body: FormLayout(
        children: [
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < fields.length; i++) ...[
                  if (i > 0) formGap,
                  fields[i],
                ],
              ],
            ),
          ),
          formGap,
          if (submit case AsyncError(:final AppFailure error)) ...[
            AppBanner.failure(context, error),
            formGap,
          ],
          AppPrimaryButton(
            key: Key('$keyPrefix.submit'),
            label: l10n.recordSave,
            isLoading: busy,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

/// Asks before deleting. `true` = confirmed. Defaults to the record texts.
Future<bool> confirmDelete(
  BuildContext context, {
  String? title,
  String? message,
  String? confirmLabel,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        Icons.delete_outline_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text(title ?? l10n.recordDeleteTitle),
      content: Text(message ?? l10n.recordDeleteMessage),
      actions: [
        TextButton(
          key: const Key('confirm.cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('confirm.delete'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(96, AppSizes.minTouch),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel ?? l10n.recordDelete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// After a successful save/delete: tell the rider and leave the form. The
/// message goes to the tab page underneath (see `shellMessengerKeyProvider`), so
/// it sits above that page's FAB or bottom bar.
void closeForm(BuildContext context, String message) {
  final messenger =
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(shellMessengerKeyProvider).currentState ??
      ScaffoldMessenger.of(context);
  context.pop();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Loads the record for an edit screen with loading / error states.
class RecordLoader<T> extends ConsumerWidget {
  const RecordLoader({
    required this.provider,
    required this.title,
    required this.builder,
    required this.onRetry,
    super.key,
  });

  final ProviderListenable<AsyncValue<T>> provider;
  final String title;
  final Widget Function(T record) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    if (value case AsyncData(:final value)) return builder(value);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AsyncValueView(
        value: value,
        data: (_) => const SizedBox.shrink(),
        onRetry: onRetry,
      ),
    );
  }
}

/// Text of an optional decimal/int field: empty when `null`.
String fieldText(Object? value) => switch (value) {
  null => '',
  final Decimal d => Formats.decimalInput(d),
  _ => value.toString(),
};

Decimal? optionalDecimalOf(TextEditingController c) {
  final text = c.text.trim();
  return text.isEmpty ? null : parseDecimalInput(text);
}

int? optionalIntOf(TextEditingController c) {
  final text = c.text.trim();
  return text.isEmpty ? null : int.parse(text);
}

String? optionalTextOf(TextEditingController c) {
  final text = c.text.trim();
  return text.isEmpty ? null : text;
}

const decimalKeyboard = TextInputType.numberWithOptions(decimal: true);
const intKeyboard = TextInputType.number;
