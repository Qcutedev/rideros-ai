import 'dart:async';
import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/utils/clock.dart';
import 'package:rideros_ai/core/utils/uuid.dart';
import 'package:rideros_ai/features/auth/data/auth_repository_impl.dart';
import 'package:rideros_ai/features/auth/domain/session_state.dart';
import 'package:rideros_ai/features/auth/presentation/session_controller.dart';
import 'package:rideros_ai/features/profile/data/rider_profile_repository_impl.dart';
import 'package:rideros_ai/features/profile/presentation/profile_providers.dart';
import 'package:rideros_ai/features/profit/data/pending_record_store.dart';
import 'package:rideros_ai/features/profit/data/profit_repositories_impl.dart';
import 'package:rideros_ai/features/profit/domain/pending_record.dart';
import 'package:rideros_ai/features/profit/domain/profit_records.dart';
import 'package:rideros_ai/features/profit/presentation/pending_sync_controller.dart';
import 'package:rideros_ai/features/profit/presentation/profit_providers.dart';

import '../../helpers/fakes.dart';
import '../../helpers/profit_fakes.dart';

Decimal d(String v) => Decimal.parse(v);

final _session = WorkSessionInput(
  startedAt: DateTime(2026, 11, 10, 10),
  endedAt: DateTime(2026, 11, 10, 14),
  orderCount: 9,
);

IncomeInput _income({String amount = '420.50', String? session}) => IncomeInput(
  occurredOn: DateTime.utc(2026, 11, 10),
  amount: d(amount),
  workSessionId: session,
);

final _expense = ExpenseInput(
  occurredOn: DateTime.utc(2026, 11, 10),
  category: ExpenseCategory.fuel,
  amount: d('80'),
);

PendingRecord _queued(String id, {String? session}) => PendingRecord(
  id: id,
  kind: PendingKind.income,
  body: {
    'occurred_on': '2026-11-10',
    'amount': '100',
    'work_session_id': session,
  },
  queuedAt: DateTime.utc(2026, 11, 10, 7),
);

void main() {
  late ProfitFakes fakes;
  late FakeAuthRepository auth;
  late int ids;

  setUp(() {
    fakes = ProfitFakes();
    auth = FakeAuthRepository()..restoreUser = testUser;
    ids = 0;
  });

  /// Signed in as [testUser], the queue loaded (and its first run, if any, done).
  Future<ProviderContainer> signedIn(
    Future<void> Function() settle, {
    FakeAuthRepository? withAuth,
  }) async {
    final container = ProviderContainer.test(
      retry: (retryCount, error) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(withAuth ?? auth),
        riderProfileRepositoryProvider.overrideWithValue(
          FakeRiderProfileRepository(configured: true),
        ),
        profitRepositoryProvider.overrideWithValue(fakes.profit),
        incomeRepositoryProvider.overrideWithValue(fakes.income),
        expenseRepositoryProvider.overrideWithValue(fakes.expenses),
        workSessionRepositoryProvider.overrideWithValue(fakes.sessions),
        pendingRecordStoreProvider.overrideWithValue(fakes.pendingStore),
        pendingRecordSenderProvider.overrideWithValue(fakes.sender),
        clockProvider.overrideWithValue(testNow),
        uuidProvider.overrideWithValue(() => 'cid-${++ids}'),
      ],
    );
    container
      ..listen(pendingSyncProvider, (_, _) {})
      ..listen(incomeFormProvider, (_, _) {})
      ..listen(expenseFormProvider, (_, _) {})
      ..listen(workSessionFormProvider, (_, _) {});
    while (container.read(sessionControllerProvider) is! SignedIn) {
      await settle();
    }
    await settle();
    return container;
  }

  Future<void> realSettle() => pumpEventQueue();

  PendingSyncState queueOf(ProviderContainer c) => c.read(pendingSyncProvider);
  PendingSyncController ctrl(ProviderContainer c) =>
      c.read(pendingSyncProvider.notifier);

  group('saving a new record', () {
    test('online: sent at once under a client id, nothing queued', () async {
      final c = await signedIn(realSettle);
      final saved = await c
          .read(incomeFormProvider.notifier)
          .save(null, _income());
      expect(saved!.queued, isFalse);
      expect(saved.record.id, 'cid-1');
      expect(fakes.income.lastCreateId, 'cid-1');
      expect(queueOf(c).isEmpty, isTrue);
      expect(c.read(profitDataRevisionProvider), 1);
    });

    test('no connection: queued under the id it was sent with', () async {
      final c = await signedIn(realSettle);
      fakes.income.saveError = const NetworkFailure(isTimeout: true);
      final saved = await c
          .read(incomeFormProvider.notifier)
          .save(null, _income());

      expect(saved!.queued, isTrue);
      expect(saved.record.id, 'cid-1');
      expect(saved.record.amount, d('420.50'));
      expect(saved.record.occurredOn, DateTime.utc(2026, 11, 10));
      // The first attempt used the same id, so a lost response is harmless.
      expect(fakes.income.lastCreateId, 'cid-1');
      final item = queueOf(c).items.single;
      expect(item.kind, PendingKind.income);
      expect(item.requestBody['id'], 'cid-1');
      expect(item.requestBody['amount'], '420.5'); // as the API body sends it
      expect(fakes.pendingStore.of(testUser.id).single.id, 'cid-1');
      // Not on the server: the figures are not reloaded.
      expect(c.read(profitDataRevisionProvider), 0);
      expect(c.read(incomeFormProvider), const AsyncData<void>(null));
    });

    test(
      'a queued work session comes back as the record the form pops',
      () async {
        final c = await signedIn(realSettle);
        fakes.sessions.saveError = const NetworkFailure();
        final saved = await c
            .read(workSessionFormProvider.notifier)
            .save(null, _session);
        expect(saved!.queued, isTrue);
        expect(saved.record.id, 'cid-1');
        expect(saved.record.startedAt, DateTime(2026, 11, 10, 10));
        expect(saved.record.endedAt, DateTime(2026, 11, 10, 14));
        expect(saved.record.orderCount, 9);
      },
    );

    test('a gateway error queues; other errors stay in the form', () async {
      final c = await signedIn(realSettle);
      final form = c.read(expenseFormProvider.notifier);
      for (final status in [502, 503, 504]) {
        fakes.expenses.saveError = ApiFailure(statusCode: status, code: 'x');
        expect((await form.save(null, _expense))!.queued, isTrue);
      }
      expect(queueOf(c).items, hasLength(3));

      for (final failure in [
        const ApiFailure(statusCode: 500, code: 'internal_error'),
        const ApiFailure(statusCode: 422, code: 'validation_error'),
        const RateLimitedFailure(),
      ]) {
        fakes.expenses.saveError = failure;
        expect(await form.save(null, _expense), isNull);
        expect(c.read(expenseFormProvider).error, failure);
      }
      expect(queueOf(c).items, hasLength(3));
    });

    test('an edit without a connection is not queued', () async {
      final c = await signedIn(realSettle);
      final existing = fakes.income.add(_income());
      fakes.income.saveError = const NetworkFailure();
      final form = c.read(incomeFormProvider.notifier);
      expect(await form.save(existing.id, _income(amount: '1')), isNull);
      expect(c.read(incomeFormProvider).error, isA<NetworkFailure>());
      expect(queueOf(c).isEmpty, isTrue);
    });

    test(
      'a record linked to a queued session waits behind it, even online',
      () async {
        final c = await signedIn(realSettle);
        fakes.sessions.saveError = const NetworkFailure();
        await c.read(workSessionFormProvider.notifier).save(null, _session);
        fakes.sessions.saveError = null;
        fakes.sender.error =
            const NetworkFailure(); // still offline for the queue

        final saved = await c
            .read(incomeFormProvider.notifier)
            .save(null, _income(session: 'cid-1'));
        expect(saved!.queued, isTrue);
        expect(saved.record.workSessionId, 'cid-1');
        expect(
          fakes.income.calls,
          isEmpty,
        ); // never tried: the server lacks cid-1
        expect(queueOf(c).items.map((i) => i.id), ['cid-1', 'cid-2']);
      },
    );

    test('the queue cannot be stored: the form shows an error', () async {
      final c = await signedIn(realSettle);
      fakes.income.saveError = const NetworkFailure();
      fakes.pendingStore.writeError = Exception('disk full');
      expect(
        await c.read(incomeFormProvider.notifier).save(null, _income()),
        isNull,
      );
      expect(c.read(incomeFormProvider).error, isA<UnknownFailure>());
      expect(queueOf(c).isEmpty, isTrue);
    });

    test('a successful save sends what was waiting', () async {
      final c = await signedIn(realSettle);
      fakes.income.saveError = const NetworkFailure();
      fakes.sender.error = const NetworkFailure();
      await c.read(incomeFormProvider.notifier).save(null, _income());
      fakes.income.saveError = null;
      fakes.sender.error = null;

      await c.read(expenseFormProvider.notifier).save(null, _expense);
      await realSettle();
      expect(fakes.sender.sent.map((i) => i.id), ['cid-1']);
      expect(queueOf(c).isEmpty, isTrue);
    });
  });

  group('sending the queue', () {
    Future<ProviderContainer> withQueue(List<PendingRecord> items) async {
      fakes.pendingStore.entries[testUser.id] = encodePendingRecords(items)!;
      fakes.sender.error = const NetworkFailure(); // keep them for the test
      final c = await signedIn(realSettle);
      fakes.sender.error = null;
      fakes.sender.attempts = 0;
      return c;
    }

    test('loads the account\'s queue on start and sends it in order', () async {
      fakes.pendingStore.entries['someone-else'] = encodePendingRecords([
        _queued('theirs'),
      ])!;
      fakes.pendingStore.entries[testUser.id] = encodePendingRecords([
        _queued('a'),
        _queued('b'),
      ])!;
      final c = await signedIn(realSettle);

      expect(fakes.sender.sent.map((i) => i.id), ['a', 'b']);
      expect(fakes.sender.sent.first.requestBody['id'], 'a');
      expect(queueOf(c).isEmpty, isTrue);
      expect(queueOf(c).syncing, isFalse);
      expect(fakes.pendingStore.entries.containsKey(testUser.id), isFalse);
      expect(fakes.pendingStore.of('someone-else').single.id, 'theirs');
      expect(c.read(profitDataRevisionProvider), 1);
    });

    test('a temporary failure stops the run and keeps everything', () async {
      for (final failure in <Object>[
        const NetworkFailure(),
        const RateLimitedFailure(),
        const SessionExpiredFailure(),
        const ApiFailure(statusCode: 500, code: 'internal_error'),
        const UnknownFailure(),
      ]) {
        final c = await withQueue([_queued('a'), _queued('b')]);
        fakes.sender.errors.add(failure);
        await ctrl(c).flush();
        expect(fakes.sender.attempts, 1, reason: '$failure');
        expect(queueOf(c).waitingCount, 2, reason: '$failure');
        expect(queueOf(c).syncing, isFalse);
      }
    });

    test(
      'a refused record is marked, its linked records too; the rest goes',
      () async {
        final session = PendingRecord(
          id: 's1',
          kind: PendingKind.workSession,
          body: const {
            'started_at': '2026-11-10T10:00:00+07:00',
            'ended_at': '2026-11-10T14:00:00+07:00',
          },
          queuedAt: DateTime.utc(2026, 11, 10, 7),
        );
        final c = await withQueue([
          session,
          _queued('linked', session: 's1'),
          _queued('free'),
        ]);
        fakes.sender.errors.add(
          const ApiFailure(statusCode: 409, code: 'work_session_overlap'),
        );
        await ctrl(c).flush();

        expect(fakes.sender.sent.map((i) => i.id), ['free']);
        final items = queueOf(c).items;
        expect(items.map((i) => (i.id, i.failureCode)), [
          ('s1', 'work_session_overlap'),
          ('linked', linkedSessionFailedCode),
        ]);
        expect(items.first.failureStatus, 409);
        expect(queueOf(c).failedCount, 2);
        expect(queueOf(c).waitingCount, 0);
        // Stored with the reason, so it survives a restart.
        expect(
          fakes.pendingStore.of(testUser.id).first.failureCode,
          'work_session_overlap',
        );

        // Failed items are not sent again.
        await ctrl(c).flush();
        expect(fakes.sender.attempts, 2);
      },
    );

    test('two runs at once share one', () async {
      final c = await withQueue([_queued('a')]);
      fakes.sender.gate = Completer();
      final first = ctrl(c).flush();
      final second = ctrl(c).flush();
      await pumpEventQueue();
      expect(queueOf(c).syncing, isTrue);
      fakes.sender.gate!.complete();
      await Future.wait([first, second]);
      expect(fakes.sender.attempts, 1);
      expect(queueOf(c).isEmpty, isTrue);
    });

    test('remove drops a session with the records linked to it', () async {
      final c = await withQueue([
        _queued('s1').failed(409, 'work_session_overlap'),
        _queued('linked', session: 's1'),
        _queued('free'),
      ]);
      fakes.sender.error = const NetworkFailure();
      expect(ctrl(c).linkedCount('s1'), 1);
      await ctrl(c).remove('s1');
      expect(queueOf(c).items.map((i) => i.id), ['free']);
      expect(fakes.pendingStore.of(testUser.id).map((i) => i.id), ['free']);
    });

    test(
      'sign out empties the screen state but keeps the stored queue',
      () async {
        final c = await withQueue([_queued('a')]);
        fakes.sender.error = const NetworkFailure();
        await c.read(sessionControllerProvider.notifier).logout();
        await realSettle();
        expect(queueOf(c).isEmpty, isTrue);
        expect(fakes.pendingStore.of(testUser.id).single.id, 'a');
      },
    );

    test('deleting the account drops its queue', () async {
      final c = await withQueue([_queued('a')]);
      fakes.sender.error = const NetworkFailure();
      c.listen(deleteAccountProvider, (_, _) {});
      expect(await c.read(deleteAccountProvider.notifier).delete('pw'), isTrue);
      expect(fakes.pendingStore.entries, isEmpty);
    });

    test('an unreadable store just means an empty queue', () async {
      fakes.pendingStore.readError = Exception('broken');
      final c = await signedIn(realSettle);
      expect(queueOf(c).isEmpty, isTrue);
      expect(fakes.sender.attempts, 0);
    });
  });

  group('retry timer', () {
    testWidgets(
      '15 s, 30 s, 1 min, 2 min, then sent when the connection is back',
      (tester) async {
        final c = await signedIn(() => tester.pump());
        fakes.income.saveError = const NetworkFailure();
        fakes.sender.error = const NetworkFailure();
        await c.read(incomeFormProvider.notifier).save(null, _income());
        expect(fakes.sender.attempts, 0);

        Future<void> wait(Duration d) async {
          await tester.pump(d);
          await tester.pump();
        }

        await wait(const Duration(seconds: 14));
        expect(fakes.sender.attempts, 0);
        await wait(const Duration(seconds: 1));
        expect(fakes.sender.attempts, 1);
        await wait(const Duration(seconds: 29));
        expect(fakes.sender.attempts, 1);
        await wait(const Duration(seconds: 1));
        expect(fakes.sender.attempts, 2);
        await wait(const Duration(minutes: 1));
        expect(fakes.sender.attempts, 3);
        await wait(const Duration(minutes: 2));
        expect(fakes.sender.attempts, 4);
        await wait(const Duration(minutes: 2)); // the last delay repeats
        expect(fakes.sender.attempts, 5);

        fakes.sender.error = null;
        await wait(const Duration(minutes: 2));
        expect(fakes.sender.sent.single.id, 'cid-1');
        expect(c.read(pendingSyncProvider).isEmpty, isTrue);
        await wait(const Duration(minutes: 5));
        expect(fakes.sender.attempts, 6); // nothing left: no more timers
        c.dispose();
      },
    );

    testWidgets('"ส่งตอนนี้" starts the delays over', (tester) async {
      final c = await signedIn(() => tester.pump());
      fakes.income.saveError = const NetworkFailure();
      fakes.sender.error = const NetworkFailure();
      await c.read(incomeFormProvider.notifier).save(null, _income());
      await tester.pump(const Duration(seconds: 15));
      await tester.pump(const Duration(seconds: 30));
      expect(fakes.sender.attempts, 2);

      await ctrl(c).retryNow();
      expect(fakes.sender.attempts, 3);
      await tester.pump(const Duration(seconds: 15));
      expect(fakes.sender.attempts, 4);
      c.dispose();
    });
  });

  group('PendingRecord', () {
    test('round trip through storage, unreadable items dropped', () {
      final item = PendingRecord(
        id: 'a',
        kind: PendingKind.workSession,
        body: const {'started_at': 'x', 'notes': null},
        queuedAt: DateTime.utc(2026, 11, 10, 7),
      ).failed(409, 'work_session_overlap');
      final encoded = encodePendingRecords([item])!;
      final back = decodePendingRecords(encoded).single;
      expect(back.id, 'a');
      expect(back.kind, PendingKind.workSession);
      expect(back.body, {'started_at': 'x', 'notes': null});
      expect(back.queuedAt, DateTime.utc(2026, 11, 10, 7));
      expect(back.failureStatus, 409);
      expect(back.isFailed, isTrue);

      expect(encodePendingRecords(const []), isNull);
      expect(decodePendingRecords(null), isEmpty);
      expect(decodePendingRecords('not json'), isEmpty);
      expect(decodePendingRecords('{"a": 1}'), isEmpty);
      final mixed = decodePendingRecords(
        '[{"id": "x", "kind": "spaceship", "body": {}, "queued_at": "2026-11-10T07:00:00Z"},'
        ' 3, {"id": "y", "kind": "income", "body": {}, "queued_at": "never"},'
        ' {"id": "z", "kind": "expense", "body": {}, "queued_at": "2026-11-10T07:00:00Z"}]',
      );
      expect(mixed.map((i) => i.id), ['z']);
    });

    test('shown as the record the server would store', () {
      final income = Income.fromJson(_queued('q1', session: 's1').asStoredJson);
      expect(income.id, 'q1');
      expect(income.amount, d('100'));
      expect(income.workSessionId, 's1');
      expect(income.createdAt, DateTime.utc(2026, 11, 10, 7));
    });
  });

  test('newUuidV4: version 4, RFC 4122 variant, unique', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final seen = <String>{};
    for (var i = 0; i < 200; i++) {
      final id = newUuidV4();
      expect(id, matches(pattern));
      seen.add(id);
    }
    expect(seen, hasLength(200));
    expect(newUuidV4(Random(1)), newUuidV4(Random(1)));
  });
}
