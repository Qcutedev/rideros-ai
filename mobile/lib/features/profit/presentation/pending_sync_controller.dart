import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../auth/domain/session_state.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/pending_record_store.dart';
import '../domain/pending_record.dart';
import 'profit_providers.dart';

/// No connection, or a gateway in front of the API that cannot reach it: the
/// create goes to the offline queue instead of showing an error.
bool isOfflineFailure(AppFailure failure) => switch (failure) {
  NetworkFailure() => true,
  ApiFailure(statusCode: 502 || 503 || 504) => true,
  _ => false,
};

/// A failure worth another attempt later. Any other 4xx means the server refused
/// the record itself (e.g. an overlapping work session) and will refuse it again.
bool _isTemporary(AppFailure failure) => switch (failure) {
  ApiFailure(:final statusCode) =>
    statusCode >= 500 || statusCode == 401 || statusCode == 408,
  _ => true, // no connection, rate limited, session expired, unknown
};

class PendingSyncState {
  const PendingSyncState({this.items = const [], this.syncing = false});

  /// Oldest first, the order they are sent in.
  final List<PendingRecord> items;
  final bool syncing;

  int get waitingCount => items.where((item) => !item.isFailed).length;
  int get failedCount => items.length - waitingCount;
  bool get isEmpty => items.isEmpty;

  PendingSyncState copyWith({List<PendingRecord>? items, bool? syncing}) =>
      PendingSyncState(
        items: items ?? this.items,
        syncing: syncing ?? this.syncing,
      );
}

/// The offline queue of new TrueProfit records for the signed-in rider. Lives as
/// long as the app (`RiderOsApp` keeps it and calls [PendingSyncController.flushIfWaiting]
/// when the app comes back to the foreground), so it sends whatever screen is open.
final pendingSyncProvider =
    NotifierProvider<PendingSyncController, PendingSyncState>(
      PendingSyncController.new,
    );

class PendingSyncController extends Notifier<PendingSyncState> {
  /// Waits between automatic attempts while items wait; the last one repeats.
  static const retryDelays = [
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
  ];

  String? _userId;
  Future<void> _loaded = Future.value();
  Future<void>? _flushing;
  Timer? _retry;
  int _failedAttempts = 0;

  @override
  PendingSyncState build() {
    final userId = ref.watch(
      sessionControllerProvider.select((s) => s is SignedIn ? s.user.id : null),
    );
    _userId = userId;
    _flushing = null;
    _retry = null;
    _failedAttempts = 0;
    ref.onDispose(() => _retry?.cancel());
    _loaded = userId == null ? Future.value() : _load(userId);
    return const PendingSyncState();
  }

  bool _isCurrent(String userId) => ref.mounted && _userId == userId;

  Future<void> _load(String userId) async {
    List<PendingRecord> items;
    try {
      items = await ref.read(pendingRecordStoreProvider).read(userId);
    } catch (_) {
      items = const []; // unreadable storage: nothing to send
    }
    if (!_isCurrent(userId) || items.isEmpty) return;
    state = state.copyWith(items: [...items, ...state.items]);
    unawaited(flushIfWaiting());
  }

  Future<void> _persist(String userId) =>
      ref.read(pendingRecordStoreProvider).write(userId, state.items);

  /// Whether [id] is a work session that waits in the queue (a record linked to
  /// it has to wait too).
  bool isQueuedSession(String id) => state.items.any(
    (item) => item.kind == PendingKind.workSession && item.id == id,
  );

  /// How many records the queue holds, once it has been read from the device.
  Future<int> loadedCount() async {
    await _loaded;
    return state.items.length;
  }

  /// Queued records linked to the work session [id].
  int linkedCount(String id) =>
      state.items.where((item) => item.workSessionId == id).length;

  /// Adds [item] to the end of the queue and stores it on the device. Throws
  /// when it cannot be stored, so the form stays open with an error.
  Future<void> enqueue(PendingRecord item) async {
    await _loaded;
    final userId = _userId;
    if (userId == null || !ref.mounted) throw const SessionExpiredFailure();
    state = state.copyWith(items: [...state.items, item]);
    try {
      await _persist(userId);
    } catch (_) {
      if (_isCurrent(userId)) {
        state = state.copyWith(
          items: [
            for (final i in state.items)
              if (i.id != item.id) i,
          ],
        );
      }
      rethrow;
    }
    if (_isCurrent(userId)) _scheduleRetry();
  }

  /// Drops [id] from the queue, and for a work session the records linked to it.
  Future<void> remove(String id) async {
    final userId = _userId;
    if (userId == null || state.syncing) return;
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id != id && item.workSessionId != id) item,
      ],
    );
    await _persist(userId);
  }

  Future<void> flushIfWaiting() async {
    if (state.waitingCount > 0) await flush();
  }

  /// "ส่งตอนนี้": sends at once and starts the retry delays over.
  Future<void> retryNow() {
    _failedAttempts = 0;
    return flush();
  }

  /// Sends the waiting items in order, one at a time. A call while a run is going
  /// on joins that run.
  Future<void> flush() =>
      _flushing ??= _flush().whenComplete(() => _flushing = null);

  Future<void> _flush() async {
    await _loaded;
    final userId = _userId;
    if (userId == null || !_isCurrent(userId)) return;
    _retry?.cancel();
    _retry = null;
    if (state.waitingCount == 0) return;
    state = state.copyWith(syncing: true);
    var sent = false;
    var interrupted = false;
    try {
      while (_isCurrent(userId)) {
        final item = _nextWaiting();
        if (item == null) break;
        if (_linkedSessionFailed(item)) {
          _replace(item, item.failed(0, linkedSessionFailedCode));
        } else {
          try {
            await ref.read(pendingRecordSenderProvider).send(item);
            if (!_isCurrent(userId)) return;
            state = state.copyWith(
              items: [
                for (final i in state.items)
                  if (i.id != item.id) i,
              ],
            );
            sent = true;
          } on AppFailure catch (failure) {
            if (!_isCurrent(userId)) return;
            if (_isTemporary(failure)) {
              interrupted = true;
              break;
            }
            final refused = failure as ApiFailure;
            _replace(item, item.failed(refused.statusCode, refused.code));
          }
        }
        // A failed write only means the item is sent again next time, and the
        // server answers a resent id with the record it already has.
        unawaited(_persist(userId).catchError((Object _) {}));
      }
    } finally {
      if (_isCurrent(userId)) {
        state = state.copyWith(syncing: false);
        if (sent) ref.read(profitDataRevisionProvider.notifier).bump();
        if (interrupted) {
          _scheduleRetry();
        } else {
          _failedAttempts = 0;
        }
      }
    }
  }

  PendingRecord? _nextWaiting() {
    for (final item in state.items) {
      if (!item.isFailed) return item;
    }
    return null;
  }

  bool _linkedSessionFailed(PendingRecord item) {
    final sessionId = item.workSessionId;
    return sessionId != null &&
        state.items.any((i) => i.id == sessionId && i.isFailed);
  }

  void _replace(PendingRecord item, PendingRecord replacement) {
    state = state.copyWith(
      items: [for (final i in state.items) i.id == item.id ? replacement : i],
    );
  }

  void _scheduleRetry() {
    if (_retry?.isActive ?? false) return;
    final delay = retryDelays[min(_failedAttempts, retryDelays.length - 1)];
    _failedAttempts++;
    _retry = Timer(delay, () {
      _retry = null;
      unawaited(flush());
    });
  }
}
