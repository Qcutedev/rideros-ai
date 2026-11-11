import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_failure.dart';
import '../errors/failure_mapper.dart';
import '../network/paged_result.dart';

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

/// First page on build (and whenever a watched dependency changes); [loadMore]
/// appends the next one.
abstract class PagedListNotifier<T> extends AsyncNotifier<PagedState<T>> {
  Future<PagedResult<T>> fetchPage(String? cursor);

  /// Watch whatever must reload the list (e.g. a data revision counter).
  void watchDependencies() {}

  @override
  Future<PagedState<T>> build() async {
    watchDependencies();
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
