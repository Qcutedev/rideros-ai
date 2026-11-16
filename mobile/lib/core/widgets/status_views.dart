import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../errors/app_failure.dart';
import '../errors/failure_messages.dart';
import 'app_surfaces.dart';
import 'motion.dart';

/// Spinner with a message (never a bare spinner, §5.6).
class LoadingView extends StatelessWidget {
  const LoadingView({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message ?? l10n.commonLoading,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Waiting for a model: the pulsing AI mark with a message.
class AiLoadingView extends StatelessWidget {
  const AiLoadingView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Semantics(
          liveRegion: true,
          label: message,
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AiPulse(key: Key('aiLoading.pulse'), size: 88),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grey placeholder block for skeleton loading states.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.height = 16,
    this.width,
    this.radius = AppRadius.sm,
    super.key,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: context.semanticColors.mint,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Skeleton shaped like a summary card: title, big figure, two rows of tiles.
/// Announced as "loading" to screen readers.
class SummarySkeleton extends StatelessWidget {
  const SummarySkeleton({this.cards = 1, super.key});

  final int cards;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget tileRow() => const Row(
      children: [
        Expanded(child: SkeletonBox(height: 56, radius: AppRadius.md)),
        SizedBox(width: AppSpacing.md),
        Expanded(child: SkeletonBox(height: 56, radius: AppRadius.md)),
      ],
    );
    return Semantics(
      label: l10n.commonLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Shimmer(
          child: Column(
            key: const Key('skeleton'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.lg),
                ToneCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBox(width: 140),
                      const SizedBox(height: AppSpacing.lg),
                      const SkeletonBox(width: 180, height: 40),
                      const SizedBox(height: AppSpacing.lg),
                      tileRow(),
                      const SizedBox(height: AppSpacing.md),
                      tileRow(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton shaped like a card of list rows (icon + two lines each).
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({this.rows = 3, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.commonLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Shimmer(
          child: ToneCard(
            key: const Key('skeleton.list'),
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < rows; i++)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          SkeletonBox(
                            width: 40,
                            height: 40,
                            radius: AppRadius.pill,
                          ),
                          SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonBox(width: 160),
                                SizedBox(height: AppSpacing.sm),
                                SkeletonBox(width: 100, height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered icon + title + message + optional action. Used for empty and error states.
class StatusView extends StatelessWidget {
  const StatusView({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconWell(
                icon: icon,
                size: AppSizes.iconXl + AppSpacing.lg,
                square: true,
                color: isError ? scheme.errorContainer : null,
                iconColor: isError ? scheme.onErrorContainer : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(160, AppSizes.minTouch),
                  ),
                  onPressed: onAction,
                  icon: Icon(isError ? Icons.refresh_rounded : Icons.add),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({required this.failure, this.title, this.onRetry, super.key});

  final AppFailure failure;
  final String? title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = failureMessage(l10n, failure);
    return StatusView(
      icon: failure is NetworkFailure
          ? Icons.wifi_off_rounded
          : Icons.error_outline_rounded,
      title: title ?? message,
      message: title == null ? null : message,
      actionLabel: onRetry == null ? null : l10n.commonRetry,
      onAction: onRetry,
      isError: true,
    );
  }
}

/// Renders an [AsyncValue] with the four required states: loading, error, empty, data.
/// [loading] replaces the default spinner, e.g. with a skeleton of the content.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.isEmpty,
    this.empty,
    this.loading,
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget? loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) when isEmpty?.call(value) ?? false =>
        empty ?? const SizedBox.shrink(),
      AsyncData(:final value) => data(value),
      AsyncError(:final error) => ErrorView(
        failure: error is AppFailure ? error : UnknownFailure(error),
        onRetry: onRetry,
      ),
      _ => loading ?? const LoadingView(),
    };
  }
}

/// While a provider reloads (e.g. after an action bumped a revision) it is
/// loading but still holds the last data: keep showing that data instead of the
/// skeleton, so the screen does not flash or lose its scroll position.
extension KeepDataWhileReloading<T> on AsyncValue<T> {
  AsyncValue<T> get keepingData => switch (this) {
    AsyncLoading(hasValue: true, :final value) => AsyncData(value as T),
    _ => this,
  };
}

enum BannerTone { info, warning, error, success }

/// Inline message inside a form or card (§5.4): icon + short text.
class AppBanner extends StatelessWidget {
  const AppBanner({
    required this.message,
    this.tone = BannerTone.info,
    super.key,
  });

  factory AppBanner.failure(
    BuildContext context,
    AppFailure failure, {
    Key? key,
  }) => AppBanner(
    key: key,
    message: failureMessage(AppLocalizations.of(context), failure),
    tone: BannerTone.error,
  );

  final String message;
  final BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final semantic = context.semanticColors;
    final (Color background, Color foreground, IconData icon) = switch (tone) {
      BannerTone.info => (
        semantic.mint,
        scheme.onSurface,
        Icons.info_outline_rounded,
      ),
      BannerTone.warning => (
        semantic.warningContainer,
        semantic.warning,
        Icons.warning_amber_rounded,
      ),
      BannerTone.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline_rounded,
      ),
      // Text in the normal colour; the icon carries the success colour.
      BannerTone.success => (
        semantic.mint,
        scheme.onSurface,
        Icons.check_circle_outline_rounded,
      ),
    };
    final iconColor = tone == BannerTone.success
        ? semantic.success
        : foreground;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: foreground.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
