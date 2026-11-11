import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paged_result.dart';
import '../../../core/presentation/submit_notifier.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_json.dart';
import '../../auth/domain/session_state.dart';
import '../../auth/presentation/session_controller.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../profit/data/profit_repositories_impl.dart';
import '../../profit/domain/profit_summary.dart';
import '../../profit/presentation/profit_providers.dart';
import '../data/shift_repository_impl.dart';
import '../domain/shift_models.dart';
import '../domain/shift_repository.dart';

/// Bumped after every create/update/re-estimate/link/delete of a scenario. The
/// list, the details and comparisons watch it and reload the server's figures.
final shiftDataRevisionProvider = NotifierProvider<ShiftDataRevision, int>(
  ShiftDataRevision.new,
);

class ShiftDataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

class ShiftListNotifier extends PagedListNotifier<ShiftScenario> {
  @override
  void watchDependencies() => ref.watch(shiftDataRevisionProvider);

  @override
  Future<PagedResult<ShiftScenario>> fetchPage(String? cursor) =>
      ref.read(shiftRepositoryProvider).list(cursor: cursor);
}

final shiftListProvider =
    AsyncNotifierProvider.autoDispose<
      ShiftListNotifier,
      PagedState<ShiftScenario>
    >(ShiftListNotifier.new);

/// One scenario. Also reloads after TrueProfit changes: deleting a work session
/// removes its link on the server.
final shiftScenarioProvider = FutureProvider.autoDispose
    .family<ShiftScenario, String>((ref, id) {
      ref.watch(shiftDataRevisionProvider);
      ref.watch(profitDataRevisionProvider);
      return ref.watch(shiftRepositoryProvider).get(id);
    });

/// `POST /shift-scenarios/compare` for comma-separated ids (in that order).
final shiftComparisonProvider = FutureProvider.autoDispose
    .family<ShiftComparison, String>((ref, ids) {
      ref.watch(shiftDataRevisionProvider);
      return ref.watch(shiftRepositoryProvider).compare(ids.split(','));
    });

/// Currency of the rider (from the rider profile); `null` until it is known, and
/// money is then shown without a symbol. The shift API carries no currency.
final shiftCurrencyProvider = Provider.autoDispose<String?>(
  (ref) => ref.watch(riderProfileProvider).value?.currency,
);

/// Days with working hours in the last [ShiftLimits.historyDays] days, from the
/// rider's own TrueProfit daily figures. The `historical` method needs
/// [ShiftLimits.minHistoryDays]; the server checks again on save.
final workedHistoryDaysProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(profitDataRevisionProvider);
  final today = dateOnly(ref.watch(clockProvider)());
  final trends = await ref
      .watch(profitRepositoryProvider)
      .trends(
        ProfitPeriod.day,
        from: today.subtract(const Duration(days: ShiftLimits.historyDays - 1)),
      );
  return trends.points.where((p) => p.metrics.workingHours.sign > 0).length;
});

// ---- selection for the comparison ----

/// Scenario ids picked on the list for comparing, in the order they were picked.
/// Kept alive so a delete on the details can always drop its id; starts empty
/// for every signed-in rider.
final shiftSelectionProvider = NotifierProvider<ShiftSelection, List<String>>(
  ShiftSelection.new,
);

class ShiftSelection extends Notifier<List<String>> {
  @override
  List<String> build() {
    ref.watch(
      sessionControllerProvider.select((s) => s is SignedIn ? s.user.id : null),
    );
    return const [];
  }

  bool get isFull => state.length >= ShiftLimits.maxCompare;

  /// Adds or removes [id]; adding beyond [ShiftLimits.maxCompare] is ignored.
  void toggle(String id) {
    if (state.contains(id)) {
      state = [...state.where((s) => s != id)];
    } else if (!isFull) {
      state = [...state, id];
    }
  }

  void remove(String id) {
    if (state.contains(id)) state = [...state.where((s) => s != id)];
  }

  void clear() => state = const [];
}

// ---- forms and actions ----

/// Create/update in the form; re-estimate, link and delete on the details.
/// Success bumps [shiftDataRevisionProvider]. Each action reads what it needs
/// before awaiting: the screen may close while the request runs.
class ShiftActionController extends SubmitNotifier {
  /// The saved scenario (with its new estimate), `null` on failure.
  ShiftScenario? saved;

  /// Creates when [id] is `null`, otherwise updates.
  Future<bool> save(String? id, ShiftScenarioInput input) =>
      _run((repo) => id == null ? repo.create(input) : repo.update(id, input));

  Future<bool> reEstimate(String id) => _run((repo) => repo.reEstimate(id));

  Future<bool> link(String id, String? workSessionId) =>
      _run((repo) => repo.linkWorkSession(id, workSessionId));

  Future<bool> delete(String id) {
    final selection = ref.read(shiftSelectionProvider.notifier);
    return _run((repo) async {
      await repo.delete(id);
      selection.remove(id);
      return null;
    });
  }

  Future<bool> _run(
    Future<ShiftScenario?> Function(ShiftRepository repo) action,
  ) {
    final repo = ref.read(shiftRepositoryProvider);
    final revision = ref.read(shiftDataRevisionProvider.notifier);
    return run(() async {
      saved = await action(repo);
      revision.bump();
    });
  }
}

final shiftFormProvider =
    NotifierProvider.autoDispose<ShiftActionController, AsyncValue<void>>(
      ShiftActionController.new,
    );

final shiftDetailActionProvider =
    NotifierProvider.autoDispose<ShiftActionController, AsyncValue<void>>(
      ShiftActionController.new,
    );
