import '../../../core/network/paged_result.dart';
import 'profit_records.dart';
import 'profit_summary.dart';
import 'work_patterns.dart';

/// CRUD of one TrueProfit record type (`/income`, `/expenses`, `/work-sessions`).
/// Every method throws an `AppFailure` on error; another user's id is a 404.
abstract interface class RecordRepository<T, I> {
  /// Newest first. [from]/[to] are inclusive local dates.
  Future<PagedResult<T>> list({String? cursor, DateTime? from, DateTime? to});

  Future<T> get(String id);

  Future<T> create(I input);

  Future<T> update(String id, I input);

  Future<void> delete(String id);
}

typedef IncomeRepository = RecordRepository<Income, IncomeInput>;
typedef ExpenseRepository = RecordRepository<Expense, ExpenseInput>;
typedef WorkSessionRepository = RecordRepository<WorkSession, WorkSessionInput>;

abstract interface class ProfitRepository {
  /// The period that contains [date] (default: today in the rider's zone).
  Future<ProfitSummary> summary(ProfitPeriod period, {DateTime? date});

  /// Buckets from [from] to [to] (inclusive local dates). Without [from]: the
  /// backend's default window (30 days / 12 weeks / 12 months) ending with the
  /// bucket that contains [to] (default: today in the rider's zone).
  Future<ProfitTrends> trends(
    ProfitPeriod granularity, {
    DateTime? from,
    DateTime? to,
  });

  /// K-Means groups of the work sessions of the last 180 days.
  Future<WorkPatterns> patterns();
}
