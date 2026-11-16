import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/profit_summary.dart';
import 'profit_labels.dart';
import 'profit_providers.dart';
import 'widgets/net_profit_chart.dart';
import 'widgets/profit_metrics_view.dart';
import 'widgets/trend_summary.dart';
import 'widgets/work_patterns_card.dart';

/// TrueProfit dashboard: actual revenue, expenses, net profit and hours for a day,
/// week or month, with the net-profit trend leading up to it and the rider's
/// work patterns (last 180 days, independent of the period).
class TrueProfitScreen extends ConsumerWidget {
  const TrueProfitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(profitViewProvider);
    final data = ref.watch(trueProfitDataProvider);
    final controller = ref.read(profitViewProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trueProfitTitle),
        actions: [
          IconButton(
            key: const Key('profit.records'),
            tooltip: l10n.recordsTitle,
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.push(Routes.records),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(trueProfitDataProvider.future),
        child: PageColumn(
          child: ListView(
            padding: AppSpacing.screen,
            children: [
              SegmentedButton<ProfitPeriod>(
                key: const Key('profit.period'),
                showSelectedIcon: false,
                segments: [
                  for (final period in ProfitPeriod.values)
                    ButtonSegment(
                      value: period,
                      label: Text(periodName(l10n, period)),
                    ),
                ],
                selected: {view.period},
                onSelectionChanged: (selection) =>
                    controller.selectPeriod(selection.single),
              ),
              const SizedBox(height: AppSpacing.lg),
              AsyncValueView(
                value: data,
                onRetry: () => ref.invalidate(trueProfitDataProvider),
                loading: const SummarySkeleton(cards: 2),
                data: (d) => _Content(data: d, view: view),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.data, required this.view});

  final TrueProfitData data;
  final ProfitView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = data.summary;
    final controller = ref.read(profitViewProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToneCard(
          tone: AppTone.mist,
          radius: AppRadius.xl,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Builder(
            builder: (context) => Row(
              children: [
                IconButton(
                  key: const Key('profit.previous'),
                  tooltip: l10n.profitPreviousPeriod,
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => controller.previous(summary.startDate),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        periodRangeLabel(
                          l10n,
                          summary.period,
                          summary.startDate,
                          summary.endDate,
                        ),
                        key: const Key('profit.periodLabel'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      if (view.isCurrent)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: AppBadge(label: l10n.profitCurrentPeriod),
                        )
                      else
                        TextButton(
                          key: const Key('profit.current'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, AppSizes.minTouch),
                          ),
                          onPressed: () => controller.selectPeriod(view.period),
                          child: Text(l10n.profitBackToCurrent),
                        ),
                    ],
                  ),
                ),
                // The current period has no "next": hidden, not a dead button.
                Visibility.maintain(
                  visible: !view.isCurrent,
                  child: IconButton(
                    key: const Key('profit.next'),
                    tooltip: l10n.profitNextPeriod,
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: view.isCurrent
                        ? null
                        : () => controller.next(summary.endDate),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        RevealIn(
          child: SectionCard(
            tone: AppTone.obsidian,
            title: l10n.profitSummaryTitle,
            child: summary.metrics.isEmpty
                ? _EmptyPeriod(message: l10n.profitEmptyPeriod)
                : ProfitMetricsView(
                    metrics: summary.metrics,
                    currency: summary.currency,
                    detailed: true,
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        RevealIn(
          index: 1,
          child: SectionCard(
            title: l10n.profitTrendTitle(
              periodName(l10n, data.trends.granularity),
            ),
            child: data.trends.isEmpty
                ? _EmptyPeriod(message: l10n.profitTrendEmpty)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RevealFromStart(
                        child: NetProfitChart(trends: data.trends),
                      ),
                      TrendSummary(trends: data.trends),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        const RevealIn(index: 2, child: WorkPatternsCard()),
        const SizedBox(height: AppSpacing.lg),
        AppBanner(message: l10n.profitActualOnlyNote(summary.timezone)),
      ],
    );
  }
}

class _EmptyPeriod extends StatelessWidget {
  const _EmptyPeriod({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          const IconWell(icon: Icons.inbox_outlined, square: true),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
