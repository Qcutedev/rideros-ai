import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../profit/presentation/widgets/profit_metrics_view.dart';
import '../domain/shift_models.dart';
import 'shift_labels.dart';
import 'shift_providers.dart';

/// `/shifts/compare?ids=a,b` (S-SHIFT-COMPARE): 2-5 scenarios as cards, with the
/// best net profit and the best net profit per hour marked separately (the
/// server picks them; they may be different scenarios).
class ShiftCompareScreen extends ConsumerWidget {
  const ShiftCompareScreen({required this.ids, super.key});

  /// Comma-separated, in the order to show.
  final String ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final comparison = ref.watch(shiftComparisonProvider(ids));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shiftCompareTitle)),
      body: AsyncValueView(
        value: comparison.keepingData,
        onRetry: () => ref.invalidate(shiftComparisonProvider(ids)),
        loading: const SingleChildScrollView(
          padding: AppSpacing.screen,
          child: SummarySkeleton(cards: 2),
        ),
        data: (c) {
          ShiftScenario byId(String id) =>
              c.scenarios.firstWhere((s) => s.id == id);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(shiftComparisonProvider(ids).future),
            child: ListView(
              padding: AppSpacing.screen,
              children: [
                AppBanner(message: l10n.shiftCompareNote),
                const SizedBox(height: AppSpacing.lg),
                _BestSummary(
                  bestNet: byId(c.bestNetProfitId),
                  bestPerHour: byId(c.bestNetProfitPerHourId),
                ),
                for (final s in c.scenarios) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ScenarioCard(
                    scenario: s,
                    bestNet: s.id == c.bestNetProfitId,
                    bestPerHour: s.id == c.bestNetProfitPerHourId,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BestSummary extends ConsumerWidget {
  const _BestSummary({required this.bestNet, required this.bestPerHour});

  final ShiftScenario bestNet;
  final ShiftScenario bestPerHour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currency = ref.watch(shiftCurrencyProvider);
    return MetricTileRow(
      tiles: [
        MetricTile(
          key: const Key('compare.bestNet'),
          label: l10n.shiftBestNet,
          icon: Icons.emoji_events_outlined,
          value:
              '${bestNet.name}\n'
              '${shiftMoney(bestNet.estimatedNetProfit, currency)}',
        ),
        MetricTile(
          key: const Key('compare.bestPerHour'),
          label: l10n.shiftBestPerHour,
          icon: Icons.speed_rounded,
          value:
              '${bestPerHour.name}\n'
              '${l10n.shiftPerHourValue(shiftMoney(bestPerHour.estimatedNetProfitPerHour, currency))}',
        ),
      ],
    );
  }
}

class _ScenarioCard extends ConsumerWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.bestNet,
    required this.bestPerHour,
  });

  final ShiftScenario scenario;
  final bool bestNet;
  final bool bestPerHour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currency = ref.watch(shiftCurrencyProvider);
    final s = scenario;
    final highlighted = bestNet || bestPerHour;
    String money(Decimal v) => shiftMoney(v, currency);

    // The best scenario sits on Electric Lime; the theme inside follows it.
    return ToneCard(
      key: Key('compare.${s.id}'),
      tone: highlighted ? AppTone.lime : AppTone.paper,
      onTap: () => context.push(Routes.shiftDetail(s.id)),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          Widget row(
            String label,
            String value, {
            Color? color,
            bool strong = false,
          }) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: MergeSemantics(
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: theme.textTheme.bodyMedium),
                  ),
                  Text(
                    value,
                    style: AppTypography.figures(
                      (strong
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.bodyMedium)
                          ?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  AppBadge(label: l10n.badgeEstimate, tone: BadgeTone.warning),
                  if (bestNet)
                    AppBadge(
                      key: Key('compare.${s.id}.bestNet'),
                      label: l10n.shiftBestNet,
                    ),
                  if (bestPerHour)
                    AppBadge(
                      key: Key('compare.${s.id}.bestPerHour'),
                      label: l10n.shiftBestPerHour,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${shiftTimeRange(s)} · ${shiftLengthLabel(l10n, s)}\n'
                '${plannedDayLabel(l10n, s.plannedWeekday)} · '
                '${methodLabel(l10n, s.estimationMethod)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              row(l10n.shiftEstimatedRevenue, money(s.estimatedRevenue)),
              row(l10n.shiftEstimatedExpenses, money(s.estimatedExpenses)),
              row(
                l10n.shiftNetEstimate,
                money(s.estimatedNetProfit),
                color: moneyColor(context, s.estimatedNetProfit),
                strong: true,
              ),
              row(
                l10n.shiftPerHourEstimate,
                l10n.shiftPerHourValue(money(s.estimatedNetProfitPerHour)),
                color: moneyColor(context, s.estimatedNetProfitPerHour),
              ),
              if (s.hasRange)
                row(
                  l10n.shiftRangeTitle,
                  l10n.shiftRangeValue(
                    money(s.estimateLow!),
                    money(s.estimateHigh!),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
