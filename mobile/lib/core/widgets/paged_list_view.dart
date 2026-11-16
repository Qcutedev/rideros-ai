import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../errors/failure_messages.dart';
import '../presentation/paged_list.dart';
import 'status_views.dart';

/// Loading / error / empty / items, pull-to-refresh, and the next page when the
/// end comes near (or on the "load more" button).
class PagedListView<T> extends ConsumerWidget {
  const PagedListView({
    required this.provider,
    required this.itemBuilder,
    required this.empty,
    this.header,
    this.loading,
    this.keyPrefix = 'records',
    this.bottomPadding = AppSpacing.xxxl * 2,
    super.key,
  });

  final AsyncNotifierProvider<PagedListNotifier<T>, PagedState<T>> provider;
  final Widget Function(T item) itemBuilder;

  /// Shown instead of the list when the first page has no items.
  final Widget empty;

  /// First row of the list (scrolls with it); not shown in the empty state.
  final Widget? header;

  /// Replaces the default spinner, e.g. with a [ListSkeleton].
  final Widget? loading;

  /// Prefix of the footer button keys (`<prefix>.loadMore`, `<prefix>.loadMoreRetry`).
  final String keyPrefix;

  /// Room below the last row, e.g. for a floating button.
  final double bottomPadding;

  /// Distance from the end (px) at which the next page is requested.
  static const _prefetchExtent = 400.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    final header = this.header;
    final lead = header == null ? 0 : 1;
    return AsyncValueView(
      value: state,
      onRetry: () => ref.invalidate(provider),
      isEmpty: (s) => s.items.isEmpty,
      empty: empty,
      loading: loading,
      data: (s) => NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < _prefetchExtent &&
              s.hasMore &&
              !s.isLoadingMore &&
              s.loadMoreError == null) {
            ref.read(provider.notifier).loadMore();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(provider.future),
          child: ListView.separated(
            padding: EdgeInsets.only(
              top: lead == 0 ? AppSpacing.md : 0,
              bottom: bottomPadding,
            ),
            itemCount: lead + s.items.length + 1,
            separatorBuilder: (_, index) => index < lead
                ? const SizedBox.shrink()
                : const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index < lead) return header!;
              final i = index - lead;
              // Each row is its own rounded card on the page background.
              return i < s.items.length
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md + 2),
                        child: itemBuilder(s.items[i]),
                      ),
                    )
                  : _ListFooter(
                      state: s,
                      keyPrefix: keyPrefix,
                      onLoadMore: () => ref.read(provider.notifier).loadMore(),
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({
    required this.state,
    required this.keyPrefix,
    required this.onLoadMore,
  });

  final PagedState<Object?> state;
  final String keyPrefix;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final Widget child;
    if (state.isLoadingMore) {
      child = const CircularProgressIndicator();
    } else if (state.loadMoreError case final error?) {
      child = Column(
        children: [
          Text(failureMessage(l10n, error), textAlign: TextAlign.center),
          TextButton(
            key: Key('$keyPrefix.loadMoreRetry'),
            onPressed: onLoadMore,
            child: Text(l10n.commonRetry),
          ),
        ],
      );
    } else if (state.hasMore) {
      child = TextButton(
        key: Key('$keyPrefix.loadMore'),
        onPressed: onLoadMore,
        child: Text(l10n.recordsLoadMore),
      );
    } else {
      child = Text(
        l10n.recordsEnd,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(child: child),
    );
  }
}

/// Rounded-square icon in front of a list row, on the soft secondary surface.
class RoundIcon extends StatelessWidget {
  const RoundIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: context.semanticColors.mint,
      borderRadius: BorderRadius.circular(AppRadius.sm + 4),
    ),
    child: Icon(
      icon,
      size: 20,
      color: Theme.of(context).brightness == Brightness.light
          ? Theme.of(context).colorScheme.onSurface
          : AppColors.lime,
    ),
  );
}
