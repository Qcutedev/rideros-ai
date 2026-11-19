import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/utils/clock.dart';
import 'package:rideros_ai/features/auth/data/auth_repository_impl.dart';
import 'package:rideros_ai/features/profit/data/pending_record_store.dart';
import 'package:rideros_ai/features/profit/data/profit_repositories_impl.dart';
import 'package:rideros_ai/features/profit/domain/profit_records.dart';
import 'package:rideros_ai/features/profit/domain/profit_summary.dart';
import 'package:rideros_ai/features/profit/presentation/profit_providers.dart';

import '../../helpers/fakes.dart';
import '../../helpers/profit_fakes.dart';

void main() {
  late ProfitFakes fakes;
  late ProviderContainer container;

  ProviderContainer create({DateTime Function()? now}) =>
      ProviderContainer.test(
        retry: (retryCount, error) => null,
        overrides: [
          profitRepositoryProvider.overrideWithValue(fakes.profit),
          incomeRepositoryProvider.overrideWithValue(fakes.income),
          expenseRepositoryProvider.overrideWithValue(fakes.expenses),
          workSessionRepositoryProvider.overrideWithValue(fakes.sessions),
          clockProvider.overrideWithValue(now ?? testNow),
          // Signed out: a create that fails is never queued here (see pending_sync_test).
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          pendingRecordStoreProvider.overrideWithValue(fakes.pendingStore),
          pendingRecordSenderProvider.overrideWithValue(fakes.sender),
        ],
      );

  IncomeInput income(int day, [String amount = '100']) =>
      IncomeInput(occurredOn: DateTime.utc(2026, 11, day), amount: d(amount));

  setUp(() {
    fakes = ProfitFakes();
    container = create();
  });

  group('ProfitViewController', () {
    ProfitView view() => container.read(profitViewProvider);
    ProfitViewController ctrl() => container.read(profitViewProvider.notifier);

    setUp(() => container.listen(profitViewProvider, (_, _) {}));

    test('starts on the current day', () {
      expect(view(), const ProfitView(period: ProfitPeriod.day));
      expect(view().isCurrent, isTrue);
    });

    test('previous anchors on the day before the shown period', () {
      ctrl().previous(DateTime.utc(2026, 11, 9));
      expect(view().anchor, DateTime.utc(2026, 11, 8));
      expect(view().isCurrent, isFalse);
    });

    test('next moves forward and returns to "current" at today', () {
      ctrl()
        ..previous(DateTime.utc(2026, 11, 10)) // anchor 9 Nov
        ..previous(DateTime.utc(2026, 11, 9)); // anchor 8 Nov
      ctrl().next(DateTime.utc(2026, 11, 8));
      expect(view().anchor, DateTime.utc(2026, 11, 9));
      ctrl().next(DateTime.utc(2026, 11, 9));
      expect(view().isCurrent, isTrue);
    });

    test('next in week view stops at the week holding today', () {
      ctrl()
        ..selectPeriod(ProfitPeriod.week)
        ..previous(DateTime.utc(2026, 11, 9)); // anchor Sun 8 Nov (last week)
      expect(view().anchor, DateTime.utc(2026, 11, 8));
      ctrl().next(DateTime.utc(2026, 11, 8)); // → Mon 9 Nov = this week
      expect(view().isCurrent, isTrue);
    });

    test('next does nothing on the current period', () {
      ctrl().next(DateTime.utc(2026, 11, 10));
      expect(view().isCurrent, isTrue);
    });

    test('selecting a period resets to its current one', () {
      ctrl()
        ..previous(DateTime.utc(2026, 11, 10))
        ..selectPeriod(ProfitPeriod.month);
      expect(view(), const ProfitView(period: ProfitPeriod.month));
    });
  });

  test('trueProfitData asks for the view period and anchor', () async {
    container.listen(trueProfitDataProvider, (_, _) {});
    await container.read(trueProfitDataProvider.future);
    container
        .read(profitViewProvider.notifier)
        .previous(DateTime.utc(2026, 11, 10));
    final data = await container.read(trueProfitDataProvider.future);
    expect(fakes.profit.calls, [
      'summary:day:-',
      'trends:day:-',
      'summary:day:2026-11-09',
      'trends:day:2026-11-09',
    ]);
    expect(data.summary.startDate, DateTime.utc(2026, 11, 9));
  });

  test('trueProfitData surfaces the first failure as it is', () async {
    fakes.profit.trendsError = const NetworkFailure();
    container.listen(trueProfitDataProvider, (_, _) {});
    await expectLater(
      container.read(trueProfitDataProvider.future),
      throwsA(isA<NetworkFailure>()),
    );
  });

  group('PagedListNotifier', () {
    setUp(() {
      fakes.income.pageSize = 2;
      for (var day = 1; day <= 5; day++) {
        fakes.income.add(income(day));
      }
      container.listen(incomeListProvider, (_, _) {});
    });

    test('first page, then appends pages until the end', () async {
      var state = await container.read(incomeListProvider.future);
      expect(state.items, hasLength(2));
      expect(state.hasMore, isTrue);

      await container.read(incomeListProvider.notifier).loadMore();
      await container.read(incomeListProvider.notifier).loadMore();
      state = container.read(incomeListProvider).requireValue;
      expect(state.items.map((i) => i.occurredOn.day), [5, 4, 3, 2, 1]);
      expect(state.hasMore, isFalse);

      // Nothing left: no request.
      final before = fakes.income.calls.length;
      await container.read(incomeListProvider.notifier).loadMore();
      expect(fakes.income.calls, hasLength(before));
    });

    test('a failed next page keeps the items and can be retried', () async {
      await container.read(incomeListProvider.future);
      fakes.income.listError = const NetworkFailure();
      await container.read(incomeListProvider.notifier).loadMore();
      var state = container.read(incomeListProvider).requireValue;
      expect(state.items, hasLength(2));
      expect(state.loadMoreError, isA<NetworkFailure>());

      fakes.income.listError = null;
      await container.read(incomeListProvider.notifier).loadMore();
      state = container.read(incomeListProvider).requireValue;
      expect(state.items, hasLength(4));
      expect(state.loadMoreError, isNull);
    });

    test('loadMore is single flight', () async {
      await container.read(incomeListProvider.future);
      fakes.income.listGate = Completer<void>();
      final notifier = container.read(incomeListProvider.notifier);
      final first = notifier.loadMore();
      expect(
        container.read(incomeListProvider).requireValue.isLoadingMore,
        isTrue,
      );
      await notifier.loadMore();
      fakes.income.listGate!.complete();
      await first;
      expect(
        fakes.income.calls.where((c) => c.startsWith('list:2')),
        hasLength(1),
      );
    });

    test('a reload during loadMore wins over the old page', () async {
      await container.read(incomeListProvider.future);
      fakes.income.listGate = Completer<void>();
      final pending = container.read(incomeListProvider.notifier).loadMore();
      container.read(profitDataRevisionProvider.notifier).bump();
      fakes.income.listGate!.complete();
      await pending;
      final state = await container.read(incomeListProvider.future);
      expect(state.items, hasLength(2));
      expect(state.isLoadingMore, isFalse);
    });
  });

  group('RecordFormController', () {
    test('create succeeds, bumps the revision and reloads lists', () async {
      container
        ..listen(incomeListProvider, (_, _) {})
        ..listen(incomeFormProvider, (_, _) {});
      expect((await container.read(incomeListProvider.future)).items, isEmpty);

      final saved = await container
          .read(incomeFormProvider.notifier)
          .save(null, income(10, '800'));
      expect(saved!.record.amount, d('800'));
      expect(saved.queued, isFalse);
      expect(container.read(profitDataRevisionProvider), 1);
      final items = (await container.read(incomeListProvider.future)).items;
      expect(items.single.amount, d('800'));
    });

    test('update and delete call the repository with the id', () async {
      final existing = fakes.income.add(income(9));
      container.listen(incomeFormProvider, (_, _) {});
      final form = container.read(incomeFormProvider.notifier);
      final updated = await form.save(existing.id, income(9, '50'));
      expect(updated!.record.id, existing.id);
      expect(updated.record.amount, d('50'));
      expect(await form.delete(existing.id), isTrue);
      expect(fakes.income.calls, [
        'update:${existing.id}',
        'delete:${existing.id}',
      ]);
      expect(container.read(profitDataRevisionProvider), 2);
    });

    test(
      'failure: AsyncError with the typed failure, no revision bump',
      () async {
        fakes.sessions.saveError = const ApiFailure(
          statusCode: 409,
          code: ApiErrorCode.workSessionOverlap,
        );
        container.listen(workSessionFormProvider, (_, _) {});
        final saved = await container
            .read(workSessionFormProvider.notifier)
            .save(
              null,
              WorkSessionInput(
                startedAt: DateTime(2026, 11, 10, 9),
                endedAt: DateTime(2026, 11, 10, 12),
              ),
            );
        expect(saved, isNull);
        expect(
          container.read(workSessionFormProvider).error,
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            'work_session_overlap',
          ),
        );
        expect(container.read(profitDataRevisionProvider), 0);
      },
    );
  });

  test('workSessionsOnDate lists sessions that started on that date', () async {
    fakes.sessions
      ..add(
        WorkSessionInput(
          startedAt: DateTime(2026, 11, 9, 20),
          endedAt: DateTime(2026, 11, 10, 1),
        ),
      )
      ..add(
        WorkSessionInput(
          startedAt: DateTime(2026, 11, 10, 9),
          endedAt: DateTime(2026, 11, 10, 12),
        ),
      );
    final provider = workSessionsOnDateProvider(DateTime.utc(2026, 11, 10));
    container.listen(provider, (_, _) {});
    final sessions = await container.read(provider.future);
    expect(sessions.single.startedAt, DateTime(2026, 11, 10, 9));
    expect(fakes.sessions.calls.single, 'list:-:2026-11-10');
  });
}
