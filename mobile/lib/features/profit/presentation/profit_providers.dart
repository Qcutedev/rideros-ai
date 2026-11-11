import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/paged_result.dart';
import '../../../core/presentation/submit_notifier.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_json.dart';
import '../data/profit_repositories_impl.dart';
import '../domain/profit_period.dart';
import '../domain/profit_records.dart';
import '../domain/profit_repositories.dart';
import '../domain/profit_summary.dart';

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

// ---- record lists (cursor pagination) ----

class PagedState<T> {
  const PagedState({
    required this.items,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<T> items;
  final String? nextCursor;
  final bool isLoadingMore;

  /// Loading the next page failed; the loaded items stay on screen.
  final AppFailure? loadMoreError;

  bool get hasMore => nextCursor != null;
}

/// First page on build (and after every data change); [loadMore] appends the next one.
abstract class PagedListNotifier<T> extends AsyncNotifier<PagedState<T>> {
  Future<PagedResult<T>> fetchPage(String? cursor);

  @override
  Future<PagedState<T>> build() async {
    ref.watch(profitDataRevisionProvider);
    final page = await fetchPage(null);
    return PagedState(items: page.items, nextCursor: page.nextCursor);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (state.isLoading ||
        current == null ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    final loading = PagedState(
      items: current.items,
      nextCursor: current.nextCursor,
      isLoadingMore: true,
    );
    state = AsyncData(loading);
    try {
      final page = await fetchPage(current.nextCursor);
      if (_superseded(loading)) return;
      state = AsyncData(
        PagedState(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (error) {
      if (_superseded(loading)) return;
      state = AsyncData(
        PagedState(
          items: current.items,
          nextCursor: current.nextCursor,
          loadMoreError: mapToFailure(error),
        ),
      );
    }
  }

  /// A reload (pull-to-refresh, data change) started meanwhile: its first page wins.
  bool _superseded(PagedState<T> loading) =>
      !ref.mounted || state.isLoading || !identical(state.value, loading);
}

class IncomeListNotifier extends PagedListNotifier<Income> {
  @override
  Future<PagedResult<Income>> fetchPage(String? cursor) =>
      ref.read(incomeRepositoryProvider).list(cursor: cursor);
}

class ExpenseListNotifier extends PagedListNotifier<Expense> {
  @override
  Future<PagedResult<Expense>> fetchPage(String? cursor) =>
      ref.read(expenseRepositoryProvider).list(cursor: cursor);
}

class WorkSessionListNotifier extends PagedListNotifier<WorkSession> {
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
