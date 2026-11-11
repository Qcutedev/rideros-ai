import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/pickup_models.dart';
import 'pickup_labels.dart';
import 'pickup_providers.dart';
import 'widgets/hourly_heatmap.dart';

/// `/pickup/restaurants/:id` (S-RESTAURANT): header, predict button (dataset
/// restaurants only), dataset statistics with the hourly heatmap, the rider's own
/// wait statistics and the log button.
class RestaurantScreen extends ConsumerWidget {
  const RestaurantScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final analytics = ref.watch(restaurantAnalyticsProvider(id));
    final name = analytics.value?.restaurant.name;
    return Scaffold(
      appBar: AppBar(title: Text(name ?? l10n.restaurantTitle)),
      body: AsyncValueView(
        value: analytics,
        onRetry: () => ref.invalidate(restaurantAnalyticsProvider(id)),
        loading: const SingleChildScrollView(
          padding: AppSpacing.screen,
          child: SummarySkeleton(cards: 2),
        ),
        data: (a) => RefreshIndicator(
          onRefresh: () {
            ref.invalidate(waitStatsProvider(id));
            return ref.refresh(restaurantAnalyticsProvider(id).future);
          },
          child: ListView(
            padding: AppSpacing.screen,
            children: [
              _Header(restaurant: a.restaurant),
              const SizedBox(height: AppSpacing.lg),
              if (a.restaurant.supportsPrediction) ...[
                AppPrimaryButton(
                  key: const Key('restaurant.predict'),
                  label: l10n.restaurantPredictNow,
                  onPressed: () => context.push(Routes.prediction(id)),
                ),
                const SizedBox(height: AppSpacing.xl),
              ] else ...[
                AppBanner(message: l10n.restaurantOwnNoPrediction),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (!a.restaurant.isOwn) ...[
                _DatasetStatsCard(analytics: a),
                const SizedBox(height: AppSpacing.lg),
              ],
              _WaitStatsCard(restaurantId: id),
              const SizedBox(height: AppSpacing.lg),
              AppSecondaryButton(
                key: const Key('restaurant.log'),
                label: l10n.restaurantLogPickup,
                onPressed: () => context.push(
                  Routes.pickupLogNewFor(
                    restaurantId: id,
                    name: a.restaurant.name,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final location = restaurant.location;
    final orders = restaurant.nOrders;
    return Card(
      key: const Key('restaurant.header'),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(restaurant.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            RestaurantBadges(restaurant: restaurant),
            if (!restaurant.isOwn && orders != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.pickupOrdersInData(Formats.count(orders)),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (location != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.restaurantLocation(
                  location.lat.toStringAsFixed(6),
                  location.lng.toStringAsFixed(6),
                ),
                key: const Key('restaurant.location'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _DayType { weekday, weekend }

class _DatasetStatsCard extends StatefulWidget {
  const _DatasetStatsCard({required this.analytics});

  final RestaurantAnalytics analytics;

  @override
  State<_DatasetStatsCard> createState() => _DatasetStatsCardState();
}

class _DatasetStatsCardState extends State<_DatasetStatsCard> {
  _DayType _day = _DayType.weekday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final overall = widget.analytics.overall;
    final cells = widget.analytics.byHour[_day.name] ?? const <StatCell>[];
    final median = overall?.medianMin;
    final p25 = overall?.p25Min;
    final p75 = overall?.p75Min;
    final peak = overall?.peakHour;
    return SectionCard(
      key: const Key('restaurant.stats'),
      title: l10n.restaurantStatsTitle,
      trailing: AppBadge(label: l10n.badgeDataset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.restaurantStatsHint, style: muted),
          const SizedBox(height: AppSpacing.md),
          if (overall == null || median == null)
            Text(l10n.restaurantNoOverall, key: const Key('restaurant.noStats'))
          else ...[
            MetricTileRow(
              tiles: [
                MetricTile(
                  label: l10n.restaurantMedian,
                  value: l10n.pickupMinutesValue(minutes1(median)),
                ),
                MetricTile(
                  label: l10n.restaurantP25P75,
                  value: p25 == null || p75 == null
                      ? '—'
                      : l10n.pickupMinutesRange(minutes1(p25), minutes1(p75)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            MetricTileRow(
              tiles: [
                MetricTile(
                  label: l10n.restaurantOrders,
                  value: Formats.count(overall.nOrders),
                ),
                MetricTile(
                  label: l10n.restaurantPeakHour,
                  value: peak == null
                      ? '—'
                      : l10n.restaurantHourValue(
                          peak.toString().padLeft(2, '0'),
                        ),
                ),
              ],
            ),
          ],
          if (cells.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.heatmapTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<_DayType>(
              key: const Key('heatmap.day'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _DayType.weekday,
                  label: Text(l10n.heatmapWeekday),
                ),
                ButtonSegment(
                  value: _DayType.weekend,
                  label: Text(l10n.heatmapWeekend),
                ),
              ],
              selected: {_day},
              onSelectionChanged: (s) => setState(() => _day = s.single),
            ),
            const SizedBox(height: AppSpacing.md),
            HourlyHeatmap(cells: cells),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.heatmapLegend, style: muted),
          ],
        ],
      ),
    );
  }
}

class _WaitStatsCard extends ConsumerWidget {
  const _WaitStatsCard({required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stats = ref.watch(waitStatsProvider(restaurantId));
    return SectionCard(
      key: const Key('restaurant.waitStats'),
      title: l10n.waitStatsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.waitStatsHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          switch (stats) {
            AsyncData(:final value) => _WaitStatsBody(stats: value),
            AsyncError(:final error) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppBanner.failure(
                  context,
                  error is AppFailure ? error : UnknownFailure(error),
                ),
                TextButton(
                  key: const Key('waitStats.retry'),
                  onPressed: () =>
                      ref.invalidate(waitStatsProvider(restaurantId)),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
            _ => const SkeletonBox(height: 56, radius: AppRadius.md),
          },
        ],
      ),
    );
  }
}

class _WaitStatsBody extends StatelessWidget {
  const _WaitStatsBody({required this.stats});

  final WaitStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final median = stats.medianMinutes;
    final p80 = stats.p80Minutes;
    if (stats.confidence == WaitConfidence.insufficient ||
        median == null ||
        p80 == null) {
      final missing = WaitStats.minLogs - stats.n;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.waitStatsCount(stats.n), key: const Key('waitStats.count')),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.waitStatsNeedMore(missing < 1 ? 1 : missing),
            key: const Key('waitStats.needMore'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MetricTileRow(
          tiles: [
            MetricTile(
              label: l10n.waitStatsMedian,
              value: l10n.pickupMinutesValue(minutes1(median)),
            ),
            MetricTile(
              label: l10n.waitStatsP80,
              value: l10n.pickupMinutesValue(minutes1(p80)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.waitStatsCount(stats.n),
              key: const Key('waitStats.count'),
            ),
            AppBadge(
              key: const Key('waitStats.confidence'),
              label: stats.confidence == WaitConfidence.ok
                  ? l10n.confidenceOk
                  : l10n.confidenceLow,
              tone: stats.confidence == WaitConfidence.ok
                  ? BadgeTone.neutral
                  : BadgeTone.warning,
            ),
          ],
        ),
      ],
    );
  }
}
