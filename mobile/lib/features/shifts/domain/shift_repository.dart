import '../../../core/network/paged_result.dart';
import 'shift_models.dart';

/// `/shift-scenarios`. Every method throws an `AppFailure` on error; another
/// rider's scenario is a 404. Create and every change of an input estimate at
/// once (400 `invalid_shift_length`, `missing_assumption`, `insufficient_history`).
abstract interface class ShiftRepository {
  /// Newest first.
  Future<PagedResult<ShiftScenario>> list({String? cursor});

  Future<ShiftScenario> get(String id);

  Future<ShiftScenario> create(ShiftScenarioInput input);

  Future<ShiftScenario> update(String id, ShiftScenarioInput input);

  /// Links one of the rider's work sessions; `null` removes the link.
  Future<ShiftScenario> linkWorkSession(String id, String? workSessionId);

  /// Same inputs, latest rider profile and history.
  Future<ShiftScenario> reEstimate(String id);

  Future<void> delete(String id);

  /// 2-5 ids, returned in the same order.
  Future<ShiftComparison> compare(List<String> ids);
}
