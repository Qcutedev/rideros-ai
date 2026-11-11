import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../profit/domain/profit_records.dart';
import '../../profit/presentation/profit_labels.dart';
import '../domain/shift_models.dart';

String methodLabel(AppLocalizations l10n, EstimationMethod method) =>
    switch (method) {
      EstimationMethod.assumption => l10n.shiftMethodAssumption,
      EstimationMethod.historical => l10n.shiftMethodHistorical,
      EstimationMethod.ml => l10n.shiftMethodUnavailable,
    };

/// `วันจันทร์` for 0 (Monday) ... `วันอาทิตย์` for 6.
String weekdayLabel(AppLocalizations l10n, int weekday) =>
    // 1 Jan 2024 was a Monday.
    DateFormat.EEEE(l10n.localeName).format(DateTime(2024, 1, 1 + weekday));

/// `วันศุกร์` or `ทุกวัน`.
String plannedDayLabel(AppLocalizations l10n, int? weekday) =>
    weekday == null ? l10n.shiftAnyDay : weekdayLabel(l10n, weekday);

/// `17:00–22:00`
String shiftTimeRange(ShiftScenario s) =>
    '${s.startTime.format()}–${s.endTime.format()}';

/// `5 ชม. 30 นาที`, plus `เลิกวันถัดไป` across midnight.
String shiftLengthLabel(AppLocalizations l10n, ShiftScenario s) => [
  durationLabel(l10n, Duration(minutes: s.durationMinutes)),
  if (s.crossesMidnight) l10n.sessionCrossesMidnight,
].join(' · ');

String warningLabel(AppLocalizations l10n, String code) => switch (code) {
  ShiftWarning.distanceCostsNotIncluded => l10n.shiftWarningDistance,
  ShiftWarning.fuelCostNotIncluded => l10n.shiftWarningFuel,
  ShiftWarning.depreciationNotIncluded => l10n.shiftWarningDepreciation,
  ShiftWarning.fewDaysForWeekday => l10n.shiftWarningFewWeekdays,
  _ => l10n.shiftWarningOther(code),
};

/// `฿1,049.50` when the currency is known, else `1,049.50`.
String shiftMoney(Decimal value, String? currency) =>
    currency == null ? Formats.money(value) : Formats.currency(value, currency);

/// `10 พ.ย. 2026 17:00–22:00 (5 ชม.)`
String workSessionLabel(AppLocalizations l10n, WorkSession s) =>
    '${Formats.date(s.startedAt, l10n.localeName)} '
    '${Formats.time(s.startedAt, l10n.localeName)}'
    '–${Formats.time(s.endedAt, l10n.localeName)} '
    '(${durationLabel(l10n, s.duration)})';
