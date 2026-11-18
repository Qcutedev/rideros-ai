import 'package:decimal/decimal.dart';

import '../../../core/utils/date_json.dart';

/// `status` of `GET /profit/heatmap`.
enum HeatmapStatus {
  ok,

  /// Fewer than [ProfitHeatmap.minSessions] counted sessions in the window.
  insufficientData;

  static HeatmapStatus fromJson(String value) => switch (value) {
    'ok' => ok,
    'insufficient_data' => insufficientData,
    _ => throw FormatException('Unknown heatmap status: $value'),
  };
}

/// One local weekday × time slot. The per-hour figures are server estimates
/// (money is spread evenly over each work session) and are `null` while the
/// cell holds fewer sessions or hours than the server's cell minimum.
class HeatmapCell {
  const HeatmapCell({
    required this.weekday,
    required this.slot,
    required this.hours,
    required this.sessionCount,
    this.revenuePerHour,
    this.netProfitPerHour,
  });

  factory HeatmapCell.fromJson(Map<String, dynamic> json) => HeatmapCell(
    weekday: json['weekday'] as int,
    slot: json['slot'] as int,
    hours: Decimal.parse(json['hours'] as String),
    sessionCount: json['session_count'] as int,
    revenuePerHour: _decimalOrNull(json['revenue_per_hour']),
    netProfitPerHour: _decimalOrNull(json['net_profit_per_hour']),
  );

  /// 0 = Monday.
  final int weekday;

  /// Starts at `slot × slotHours` o'clock, local time.
  final int slot;
  final Decimal hours;
  final int sessionCount;
  final Decimal? revenuePerHour;
  final Decimal? netProfitPerHour;

  bool get hasEstimate => netProfitPerHour != null;
}

/// `GET /profit/heatmap`: estimated net profit per hour by weekday × slot.
class ProfitHeatmap {
  ProfitHeatmap({
    required this.status,
    required this.windowDays,
    required this.startDate,
    required this.endDate,
    required this.slotHours,
    required this.sessionCount,
    required this.minSessions,
    required this.minCellSessions,
    required this.minCellHours,
    required this.excludedSessionCount,
    required this.excludedIncomeCount,
    required this.excludedExpenseCount,
    required this.hours,
    required this.cells,
    required this.currency,
    this.netProfitPerHour,
  }) : _byKey = {for (final c in cells) (c.weekday, c.slot): c};

  factory ProfitHeatmap.fromJson(Map<String, dynamic> json) => ProfitHeatmap(
    status: HeatmapStatus.fromJson(json['status'] as String),
    windowDays: json['window_days'] as int,
    startDate: parseIsoDate(json['start_date'] as String),
    endDate: parseIsoDate(json['end_date'] as String),
    slotHours: json['slot_hours'] as int,
    sessionCount: json['session_count'] as int,
    minSessions: json['min_sessions'] as int,
    minCellSessions: json['min_cell_sessions'] as int,
    minCellHours: json['min_cell_hours'] as int,
    excludedSessionCount: json['excluded_session_count'] as int,
    excludedIncomeCount: json['excluded_income_count'] as int,
    excludedExpenseCount: json['excluded_expense_count'] as int,
    hours: Decimal.parse(json['hours'] as String),
    netProfitPerHour: _decimalOrNull(json['net_profit_per_hour']),
    cells: [
      for (final cell in json['cells'] as List<dynamic>)
        HeatmapCell.fromJson(cell as Map<String, dynamic>),
    ],
    currency: json['currency'] as String,
  );

  final HeatmapStatus status;
  final int windowDays;
  final DateTime startDate;
  final DateTime endDate;
  final int slotHours;

  /// Counted sessions: those with linked or same-day unlinked income.
  final int sessionCount;
  final int minSessions;
  final int minCellSessions;
  final int minCellHours;

  /// Sessions without any income, left out of every cell.
  final int excludedSessionCount;
  final int excludedIncomeCount;
  final int excludedExpenseCount;
  final Decimal hours;

  /// Over all counted sessions; `null` without any.
  final Decimal? netProfitPerHour;

  /// Cells with any counted time; empty unless [status] is ok.
  final List<HeatmapCell> cells;
  final String currency;
  final Map<(int, int), HeatmapCell> _byKey;

  int get slotsPerDay => 24 ~/ slotHours;

  /// Counted sessions still to record before the map is shown (0 when enough).
  int get sessionsMissing =>
      sessionCount >= minSessions ? 0 : minSessions - sessionCount;

  HeatmapCell? cellAt(int weekday, int slot) => _byKey[(weekday, slot)];

  /// Up to [count] cells with the highest positive estimate; ties keep the
  /// server's weekday-then-slot order.
  List<HeatmapCell> best([int count = 3]) {
    final ranked =
        cells
            .where((c) => c.hasEstimate && c.netProfitPerHour! > Decimal.zero)
            .toList()
          ..sort((a, b) => b.netProfitPerHour!.compareTo(a.netProfitPerHour!));
    return ranked.take(count).toList();
  }
}

/// Five equal-width colour levels over the positive estimates of one map
/// (1 = lowest, 5 = highest); level 0 is a loss or break-even. The range is
/// the map's own minimum to maximum, so the steps show which slots pay more
/// than others; the legend prints the real amounts.
class HeatScale {
  HeatScale(Iterable<HeatmapCell> cells) {
    final values = [
      for (final c in cells)
        if (c.hasEstimate && c.netProfitPerHour! > Decimal.zero)
          c.netProfitPerHour!,
    ];
    if (values.isEmpty) return;
    values.sort();
    min = values.first;
    max = values.last;
  }

  static const levels = 5;

  /// Lowest and highest positive estimate; `null` when there is none.
  Decimal? min;
  Decimal? max;

  int levelOf(Decimal value) {
    if (value <= Decimal.zero) return 0;
    final lo = min, hi = max;
    if (lo == null || hi == null || hi == lo) return levels;
    final t = ((value - lo) / (hi - lo)).toDouble();
    return (1 + (t * levels).floor()).clamp(1, levels);
  }
}

Decimal? _decimalOrNull(Object? value) =>
    value == null ? null : Decimal.parse(value as String);
