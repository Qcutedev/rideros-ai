import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paged_result.dart';
import '../../../core/presentation/paged_list.dart';
import '../../../core/presentation/submit_notifier.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_json.dart';
import '../data/profit_repositories_impl.dart';
import '../domain/profit_heatmap.dart';
import '../domain/profit_period.dart';
import '../domain/profit_records.dart';
import '../domain/profit_repositories.dart';
import '../domain/profit_summary.dart';
import '../domain/work_patterns.dart';

export '../../../core/presentation/paged_list.dart';

/// Bumped after every create/update/delete of a TrueProfit record. Every list and
/// summary watches it, so they reload with the server's numbers (no local maths).
final profitDataRevisionProvider = NotifierProvider<ProfitDataRevision, int>(
  ProfitDataRevision.new,
);

class ProfitDataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

// ---- TrueProfit dashboard ----

/// Which period the TrueProfit dashboard shows. [anchor] `null` = the current period
/// (the backend decides "today" in the rider's time zone).
class ProfitView {
  const ProfitView({required this.period, this.anchor});

  final ProfitPeriod period;
  final DateTime? anchor;

  bool get isCurrent => anchor == null;

  @override
  bool operator ==(Object other) =>
      other is ProfitView && other.period == period && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(period, anchor);
}

final profitViewProvider =
    NotifierProvider.autoDispose<ProfitViewController, ProfitView>(
      ProfitViewController.new,
    );

class ProfitViewController extends Notifier<ProfitView> {
  @override
  ProfitView build() => const ProfitView(period: ProfitPeriod.day);

  void selectPeriod(ProfitPeriod period) => state = ProfitView(period: period);

  /// [shownStart]: first date of the period on screen.
  void previous(DateTime shownStart) => state = ProfitView(
    period: state.period,
    anchor: dateOnly(shownStart).subtract(const Duration(days: 1)),
  );

  /// [shownEnd]: last date of the period on screen. Reaching the period that holds
  /// today (device date) returns to the current period, which has no "next".
  void next(DateTime shownEnd) {
    if (state.isCurrent) return;
    final target = dateOnly(shownEnd).add(const Duration(days: 1));
    final today = ref.read(clockProvider)();
    final reachedCurrent = !target.isBefore(periodStart(today, state.period));
    state = ProfitView(
      period: state.period,
      anchor: reachedCurrent ? null : target,
    );
  }
}

class TrueProfitData {
  const TrueProfitData({required this.summary, required this.trends});

  final ProfitSummary summary;
  final ProfitTrends trends;
}

final trueProfitDataProvider = FutureProvider.autoDispose<TrueProfitData>((
  ref,
) async {
  ref.watch(profitDataRevisionProvider);
  final view = ref.watch(profitViewProvider);
  final repository = ref.watch(profitRepositoryProvider);
  // Future.wait rethrows the first AppFailure as it is.
  final results = await Future.wait<Object>([
    repository.summary(view.period, date: view.anchor),
    repository.trends(view.period, to: view.anchor),
  ]);
  return TrueProfitData(
    summary: results[0] as ProfitSummary,
    trends: results[1] as ProfitTrends,
  );
});

/// Work patterns of the last 180 days. Independent of the period on screen;
/// reloads after every record change. A failure only affects its own card.
final workPatternsProvider = FutureProvider.autoDispose<WorkPatterns>((ref) {
  ref.watch(profitDataRevisionProvider);
  return ref.watch(profitRepositoryProvider).patterns();
});

/// Profit heat map of the last 90 days. Like [workPatternsProvider]: independent
/// of the period on screen, reloads after every record change, own error state.
final profitHeatmapProvider = FutureProvider.autoDispose<ProfitHeatmap>((ref) {
  ref.watch(profitDataRevisionProvider);
  return ref.watch(profitRepositoryProvider).heatmap();
});

// ---- record lists (cursor pagination) ----

/// A TrueProfit list: reloads after every record change.
abstract class ProfitPagedListNotifier<T> extends PagedListNotifier<T> {
  @override
  void watchDependencies() => ref.watch(profitDataRevisionProvider);
}

class IncomeListNotifier extends ProfitPagedListNotifier<Income> {
  @override
  Future<PagedResult<Income>> fetchPage(String? cursor) =>
      ref.read(incomeRepositoryProvider).list(cursor: cursor);
}

class ExpenseListNotifier extends ProfitPagedListNotifier<Expense> {
  @override
  Future<PagedResult<Expense>> fetchPage(String? cursor) =>
      ref.read(expenseRepositoryProvider).list(cursor: cursor);
}

class WorkSessionListNotifier extends ProfitPagedListNotifier<WorkSession> {
  @override
  Future<PagedResult<WorkSession>> fetchPage(String? cursor) =>
      ref.read(workSessionRepositoryProvider).list(cursor: cursor);
}

final incomeListProvider =
    AsyncNotifierProvider.autoDispose<IncomeListNotifier, PagedState<Income>>(
      IncomeListNotifier.new,
    );

final expenseListProvider =
    AsyncNotifierProvider.autoDispose<ExpenseListNotifier, PagedState<Expense>>(
      ExpenseListNotifier.new,
    );

final workSessionListProvider =
    AsyncNotifierProvider.autoDispose<
      WorkSessionListNotifier,
      PagedState<WorkSession>
    >(WorkSessionListNotifier.new);

// ---- single records (edit screens) ----

final incomeDetailProvider = FutureProvider.autoDispose.family<Income, String>(
  (ref, id) => ref.watch(incomeRepositoryProvider).get(id),
);

final expenseDetailProvider = FutureProvider.autoDispose
    .family<Expense, String>(
      (ref, id) => ref.watch(expenseRepositoryProvider).get(id),
    );

final workSessionDetailProvider = FutureProvider.autoDispose
    .family<WorkSession, String>(
      (ref, id) => ref.watch(workSessionRepositoryProvider).get(id),
    );

/// Work sessions that started on [date] (rider's local date): choices for linking
/// an income record. One page (50) is far more than a day can hold.
final workSessionsOnDateProvider = FutureProvider.autoDispose
    .family<List<WorkSession>, DateTime>((ref, date) async {
      ref.watch(profitDataRevisionProvider);
      final page = await ref
          .watch(workSessionRepositoryProvider)
          .list(from: date, to: date);
      return page.items;
    });

// ---- forms ----

/// Create/update/delete of one record type. Success bumps [profitDataRevisionProvider].
class RecordFormController<T, I> extends SubmitNotifier {
  RecordFormController(this._repository);

  final Provider<RecordRepository<T, I>> _repository;

  /// Creates when [id] is `null`, otherwise updates.
  Future<bool> save(String? id, I input) => run(() async {
    final repository = ref.read(_repository);
    if (id == null) {
      await repository.create(input);
    } else {
      await repository.update(id, input);
    }
    ref.read(profitDataRevisionProvider.notifier).bump();
  });

  Future<bool> delete(String id) => run(() async {
    await ref.read(_repository).delete(id);
    ref.read(profitDataRevisionProvider.notifier).bump();
  });
}

final incomeFormProvider =
    NotifierProvider.autoDispose<
      RecordFormController<Income, IncomeInput>,
      AsyncValue<void>
    >(() => RecordFormController(incomeRepositoryProvider));

final expenseFormProvider =
    NotifierProvider.autoDispose<
      RecordFormController<Expense, ExpenseInput>,
      AsyncValue<void>
    >(() => RecordFormController(expenseRepositoryProvider));

final workSessionFormProvider =
    NotifierProvider.autoDispose<
      RecordFormController<WorkSession, WorkSessionInput>,
      AsyncValue<void>
    >(() => RecordFormController(workSessionRepositoryProvider));
