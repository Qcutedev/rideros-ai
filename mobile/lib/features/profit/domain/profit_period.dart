import '../../../core/utils/date_json.dart';
import 'profit_summary.dart';

/// Client copy of the backend bucket rules (`app/modules/profit/calculator.py`):
/// a day, a Monday–Sunday week, a calendar month. Dates are date-only (UTC midnight).
DateTime periodStart(DateTime day, ProfitPeriod period) {
  final d = dateOnly(day);
  return switch (period) {
    ProfitPeriod.day => d,
    ProfitPeriod.week => d.subtract(
      Duration(days: d.weekday - DateTime.monday),
    ),
    ProfitPeriod.month => DateTime.utc(d.year, d.month),
  };
}
