import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/clock.dart';
import '../../../core/utils/date_json.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/profit_records.dart';
import '../domain/session_times.dart';
import 'profit_labels.dart';
import 'profit_providers.dart';
import 'widgets/record_form_widgets.dart';

/// `/work-sessions/new` and `/work-sessions/:id`.
class WorkSessionFormScreen extends ConsumerWidget {
  const WorkSessionFormScreen({this.id, super.key});

  /// `null` = new record.
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = this.id;
    if (id == null) return const _SessionForm();
    return RecordLoader<WorkSession>(
      provider: workSessionDetailProvider(id),
      title: l10n.sessionEditTitle,
      onRetry: () => ref.invalidate(workSessionDetailProvider(id)),
      builder: (session) => _SessionForm(initial: session),
    );
  }
}

class _SessionForm extends ConsumerStatefulWidget {
  const _SessionForm({this.initial});

  final WorkSession? initial;

  @override
  ConsumerState<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends ConsumerState<_SessionForm> {
  final _formKey = GlobalKey<FormState>();
  late final WorkSession? _initial = widget.initial;
  late final _orders = TextEditingController(
    text: fieldText(_initial?.orderCount),
  );
  late final _distance = TextEditingController(
    text: fieldText(_initial?.distanceKm),
  );
  late final _notes = TextEditingController(text: _initial?.notes);
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;

  /// Shown under the end time after a save attempt with equal times.
  bool _showTimeError = false;

  @override
  void initState() {
    super.initState();
    final initial = _initial;
    if (initial != null) {
      _date = dateOnly(initial.startedAt);
      _start = TimeOfDay.fromDateTime(initial.startedAt);
      _end = TimeOfDay.fromDateTime(initial.endedAt);
    } else {
      // Default: the four hours up to now (5-minute steps).
      final now = ref.read(clockProvider)();
      final end = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute - now.minute % 5,
      );
      final start = end.subtract(const Duration(hours: 4));
      _date = dateOnly(start);
      _start = TimeOfDay.fromDateTime(start);
      _end = TimeOfDay.fromDateTime(end);
    }
  }

  @override
  void dispose() {
    _orders.dispose();
    _distance.dispose();
    _notes.dispose();
    super.dispose();
  }

  ({DateTime start, DateTime end})? get _times => sessionTimes(
    _date,
    (hour: _start.hour, minute: _start.minute),
    (hour: _end.hour, minute: _end.minute),
  );

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final times = _times;
    final fieldsValid = _formKey.currentState!.validate();
    if (times == null) setState(() => _showTimeError = true);
    if (!fieldsValid || times == null) return;
    final l10n = AppLocalizations.of(context);
    final ok = await ref
        .read(workSessionFormProvider.notifier)
        .save(
          _initial?.id,
          WorkSessionInput(
            startedAt: times.start,
            endedAt: times.end,
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
    final ok = await ref
        .read(workSessionFormProvider.notifier)
        .delete(_initial!.id);
    if (ok && mounted) closeForm(context, l10n.recordDeleted);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = Validators(l10n);
    final submit = ref.watch(workSessionFormProvider);
    final busy = submit.isLoading;
    final today = dateOnly(ref.watch(clockProvider)());
    final times = _times;
    final crossesMidnight = times != null && times.end.day != times.start.day;

    return RecordFormScaffold(
      keyPrefix: 'session',
      title: _initial == null ? l10n.sessionAdd : l10n.sessionEditTitle,
      formKey: _formKey,
      submit: submit,
      onSave: _save,
      onDelete: _initial == null ? null : _delete,
      fields: [
        DateField(
          key: const Key('session.date'),
          label: l10n.sessionStartDate,
          value: _date,
          lastDate: today,
          enabled: !busy,
          onChanged: (date) => setState(() => _date = date),
        ),
        TimeField(
          key: const Key('session.start'),
          label: l10n.sessionStartTime,
          value: _start,
          enabled: !busy,
          onChanged: (time) => setState(() => _start = time),
        ),
        TimeField(
          key: const Key('session.end'),
          label: l10n.sessionEndTime,
          value: _end,
          enabled: !busy,
          errorText: times == null && _showTimeError
              ? l10n.sessionTimesEqual
              : null,
          helperText: times == null
              ? null
              : [
                  l10n.sessionDuration(
                    durationLabel(l10n, times.end.difference(times.start)),
                  ),
                  if (crossesMidnight) l10n.sessionCrossesMidnight,
                ].join(' · '),
          onChanged: (time) => setState(() => _end = time),
        ),
        AppTextField(
          key: const Key('session.orders'),
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
          key: const Key('session.distance'),
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
          key: const Key('session.notes'),
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
