import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/profit_records.dart';
import '../domain/profit_summary.dart';

String periodName(AppLocalizations l10n, ProfitPeriod period) =>
    switch (period) {
      ProfitPeriod.day => l10n.periodDay,
      ProfitPeriod.week => l10n.periodWeek,
      ProfitPeriod.month => l10n.periodMonth,
    };

/// `10 พ.ย. 2026` · `9 พ.ย. – 15 พ.ย. 2026` · `พฤศจิกายน 2026`.
String periodRangeLabel(
  AppLocalizations l10n,
  ProfitPeriod period,
  DateTime start,
  DateTime end,
) {
  final locale = l10n.localeName;
  return switch (period) {
    ProfitPeriod.day => Formats.date(start, locale),
    ProfitPeriod.week =>
      '${Formats.dayMonth(start, locale)} – ${Formats.date(end, locale)}',
    ProfitPeriod.month => Formats.monthYear(start, locale),
  };
}

String expenseCategoryLabel(AppLocalizations l10n, ExpenseCategory category) =>
    switch (category) {
      ExpenseCategory.fuel => l10n.expenseCategoryFuel,
      ExpenseCategory.maintenance => l10n.expenseCategoryMaintenance,
      ExpenseCategory.depreciation => l10n.expenseCategoryDepreciation,
      ExpenseCategory.other => l10n.expenseCategoryOther,
    };

/// `18:00 – 22:30` (and the end date when the session crossed midnight).
String sessionTimeRange(AppLocalizations l10n, WorkSession session) {
  final locale = l10n.localeName;
  final start = session.startedAt;
  final end = session.endedAt;
  final sameDay =
      start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  final endText = sameDay
      ? Formats.time(end, locale)
      : l10n.sessionEndsNextDay(Formats.time(end, locale));
  return '${Formats.time(start, locale)} – $endText';
}

/// `4 ชม. 30 นาที`
String durationLabel(AppLocalizations l10n, Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours == 0) return l10n.durationMinutes(minutes);
  if (minutes == 0) return l10n.durationHours(hours);
  return l10n.durationHoursMinutes(hours, minutes);
}
