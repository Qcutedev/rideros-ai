import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/network/paged_result.dart';
import 'package:rideros_ai/features/shifts/domain/shift_models.dart';
import 'package:rideros_ai/features/shifts/domain/shift_repository.dart';

// ---- JSON as the API sends it ----

Map<String, Object?> scenarioJson({
  String id = 's-1',
  String name = 'Friday evening',
  String start = '17:00:00',
  String end = '22:00:00',
  int duration = 300,
  int? weekday = 4,
  String method = 'assumption',
  Map<String, Object?>? assumptions,
  String revenue = '1125.00',
  String expenses = '155.50',
  String net = '969.50',
  String perHour = '193.90',
  String? low,
  String? high,
  Map<String, Object?>? details,
  String? sessionId,
}) => {
  'id': id,
  'name': name,
  'start_time': start,
  'end_time': end,
  'duration_minutes': duration,
  'planned_weekday': weekday,
  'estimation_method': method,
  'assumptions':
      assumptions ??
      {'orders_per_hour': '2.5', 'income_per_order': '90', 'km_per_order': '4'},
  'is_estimate': true,
  'estimated_revenue': revenue,
  'estimated_expenses': expenses,
  'estimated_net_profit': net,
  'estimated_net_profit_per_hour': perHour,
  'estimate_low': low,
  'estimate_high': high,
  'estimate_details':
      details ??
      {
        'method': 'assumption',
        'hours': '5.00',
        'expected_orders': '12.50',
        'expected_km': '50.00',
        'fuel_cost': '130.50',
        'depreciation_cost': '25.00',
        'other_costs': '0.00',
        'sources': {
          'fuel_km_per_liter': 'rider_profile',
          'fuel_price_per_liter': 'rider_profile',
          'depreciation_per_km': 'scenario',
        },
        'warnings': <String>[],
      },
  'model_version_id': null,
  'actual_work_session_id': sessionId,
  'created_at': '2026-11-10T03:00:00Z',
  'updated_at': '2026-11-10T07:07:00Z',
};

Map<String, Object?> historicalDetailsJson({
  String basis = 'same_weekday',
  int days = 6,
  List<String> warnings = const [],
}) => {
  'method': 'historical',
  'hours': '5.00',
  'basis': basis,
  'window_start': '2026-08-19',
  'window_end': '2026-11-10',
  'n_days': days,
  'historical_hours': '42.5',
  'revenue_per_hour': '210.00',
  'expenses_per_hour': '35.00',
  'other_costs': '40.00',
  'range': 'P20-P80 of daily net profit per hour x shift hours',
  'note':
      'Uses whole-day averages; the time of day of the shift is not modelled.',
  'warnings': warnings,
  'timezone': 'Asia/Bangkok',
};

ShiftScenario scenario({
  String id = 's-1',
  String name = 'Friday evening',
  String net = '969.50',
  String perHour = '193.90',
  String method = 'assumption',
  int? weekday = 4,
  String? sessionId,
  String? low,
  String? high,
  Map<String, Object?>? details,
}) => ShiftScenario.fromJson(
  scenarioJson(
    id: id,
    name: name,
    net: net,
    perHour: perHour,
    method: method,
    weekday: weekday,
    sessionId: sessionId,
    low: low,
    high: high,
    details: details,
  ),
);

Decimal _d(String v) => Decimal.parse(v);

/// In-memory [ShiftRepository], newest first. A save computes a simple estimate
/// from the inputs so screens show changed figures; errors and gates are
/// scriptable.
class FakeShiftRepository implements ShiftRepository {
  FakeShiftRepository({List<ShiftScenario>? items, this.pageSize = 50})
    : items = items ?? [];

  final List<ShiftScenario> items;
  int pageSize;
  Object? listError;
  Object? getError;
  Object? saveError;
  Object? actionError;
  Object? compareError;
  Completer<void>? saveGate;
  Completer<void>? actionGate;
  final calls = <String>[];
  ShiftScenarioInput? lastInput;
  var _next = 1;

  @override
  Future<PagedResult<ShiftScenario>> list({String? cursor}) async {
    calls.add('list:${cursor ?? '-'}');
    if (listError != null) throw listError!;
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, items.length);
    return PagedResult(
      items: items.sublist(start, end),
      nextCursor: end < items.length ? '$end' : null,
    );
  }

  ShiftScenario _find(String id) => items.firstWhere(
    (s) => s.id == id,
    orElse: () => throw const ApiFailure(
      statusCode: 404,
      code: 'shift_scenario_not_found',
    ),
  );

  @override
  Future<ShiftScenario> get(String id) async {
    calls.add('get:$id');
    if (getError != null) throw getError!;
    return _find(id);
  }

  ShiftScenario _estimate(String id, ShiftScenarioInput input, String? link) {
    final minutes = shiftMinutes(input.startTime, input.endTime);
    final hours = (Decimal.fromInt(minutes) / Decimal.fromInt(60)).toDecimal(
      scaleOnInfinitePrecision: 4,
    );
    final a = input.assumptions;
    final other = a.otherCosts ?? Decimal.zero;
    final revenue = input.estimationMethod == EstimationMethod.historical
        ? (_d('200') * hours).round(scale: 2)
        : ((a.ordersPerHour ?? Decimal.zero) *
                  (a.incomePerOrder ?? Decimal.zero) *
                  hours)
              .round(scale: 2);
    final net = revenue - other;
    return ShiftScenario(
      id: id,
      name: input.name,
      startTime: input.startTime,
      endTime: input.endTime,
      durationMinutes: minutes,
      plannedWeekday: input.plannedWeekday,
      estimationMethod: input.estimationMethod,
      assumptions: a,
      estimatedRevenue: revenue,
      estimatedExpenses: other,
      estimatedNetProfit: net,
      estimatedNetProfitPerHour: minutes == 0
          ? Decimal.zero
          : (net * Decimal.fromInt(60) / Decimal.fromInt(minutes))
                .toDecimal(scaleOnInfinitePrecision: 2)
                .round(scale: 2),
      estimateDetails: ShiftEstimateDetails(
        method: input.estimationMethod.name,
      ),
      actualWorkSessionId: link,
      createdAt: DateTime.utc(2026, 11, 10, 7),
      updatedAt: DateTime.utc(2026, 11, 10, 7),
    );
  }

  @override
  Future<ShiftScenario> create(ShiftScenarioInput input) async {
    calls.add('create');
    lastInput = input;
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    final created = _estimate('new-${_next++}', input, null);
    items.insert(0, created);
    return created;
  }

  @override
  Future<ShiftScenario> update(String id, ShiftScenarioInput input) async {
    calls.add('update:$id');
    lastInput = input;
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    final i = items.indexWhere((s) => s.id == id);
    final updated = _estimate(id, input, items[i].actualWorkSessionId);
    items[i] = updated;
    return updated;
  }

  Future<ShiftScenario> _action(
    String name,
    String id,
    ShiftScenario Function(ShiftScenario s) change,
  ) async {
    calls.add('$name:$id');
    await actionGate?.future;
    if (actionError != null) throw actionError!;
    final i = items.indexWhere((s) => s.id == id);
    return items[i] = change(items[i]);
  }

  @override
  Future<ShiftScenario> linkWorkSession(String id, String? workSessionId) =>
      _action(
        'link=${workSessionId ?? 'none'}',
        id,
        (s) => s.copyWith(actualWorkSessionId: workSessionId),
      );

  @override
  Future<ShiftScenario> reEstimate(String id) => _action(
    'estimate',
    id,
    (s) => s.copyWith(updatedAt: DateTime.utc(2026, 11, 10, 7, 30)),
  );

  @override
  Future<void> delete(String id) async {
    calls.add('delete:$id');
    await actionGate?.future;
    if (actionError != null) throw actionError!;
    items.removeWhere((s) => s.id == id);
  }

  @override
  Future<ShiftComparison> compare(List<String> ids) async {
    calls.add('compare:${ids.join(',')}');
    if (compareError != null) throw compareError!;
    final scenarios = [for (final id in ids) _find(id)];
    ShiftScenario best(Decimal Function(ShiftScenario s) by) =>
        scenarios.reduce((a, b) => by(b) > by(a) ? b : a);
    return ShiftComparison(
      scenarios: scenarios,
      bestNetProfitId: best((s) => s.estimatedNetProfit).id,
      bestNetProfitPerHourId: best((s) => s.estimatedNetProfitPerHour).id,
    );
  }
}
