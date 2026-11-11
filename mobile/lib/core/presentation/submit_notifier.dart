import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/failure_mapper.dart';

/// State of a one-shot action such as a form submit.
/// Idle and done are `AsyncData(null)`, running is `AsyncLoading`, a failure is
/// `AsyncError` whose error is always an `AppFailure`.
abstract class SubmitNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Runs [action] once at a time. Returns `true` when it succeeded.
  Future<bool> run(Future<void> Function() action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await action();
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      if (ref.mounted) state = AsyncError(mapToFailure(error), stackTrace);
      return false;
    }
  }
}
