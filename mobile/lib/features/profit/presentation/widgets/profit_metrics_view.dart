import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/profit_summary.dart';

export '../../../../core/widgets/app_cards.dart' show SectionCard;

/// Net profit (large) plus revenue, expenses, hours and per-hour values.
/// [detailed] adds revenue per hour and the record counts.
class ProfitMetricsView extends StatelessWidget {
  const ProfitMetricsView({
    required this.metrics,
    required this.currency,
    this.detailed = false,
    super.key,
  });

  final ProfitMetrics metrics;
  final String currency;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.profitNet,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          Formats.currency(metrics.netProfit, currency),
          key: const Key('metrics.net'),
          style: AppTypography.figures(
            theme.textTheme.headlineSmall?.copyWith(
              color: moneyColor(context, metrics.netProfit),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ProfitTiles(metrics: metrics, currency: currency, detailed: detailed),
      ],
    );
  }
}

/// Headline card of the home screen (§4.2): Forest Green, net profit in the
/// display size, then the revenue / expense / hours tiles.
class ProfitHeroCard extends StatelessWidget {
  const ProfitHeroCard({
    required this.title,
    required this.metrics,
    required this.currency,
    super.key,
  });

  final String title;
  final ProfitMetrics metrics;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final net = metrics.netProfit;
    final netColor = net > Decimal.zero
        ? semantic.heroPositive
        : net < Decimal.zero
        ? semantic.heroNegative
        : semantic.onHero;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: semantic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: semantic.hero,
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.today_rounded,
                      size: 18,
                      color: semantic.onHeroMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: semantic.onHero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.profitNet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: semantic.onHeroMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Formats.currency(net, currency),
                    key: const Key('metrics.net'),
                    style: AppTypography.figures(
                      theme.textTheme.displaySmall?.copyWith(color: netColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: AppSpacing.cardPadding,
            child: ProfitTiles(metrics: metrics, currency: currency),
          ),
        ],
      ),
    );
  }
}

/// Revenue / expenses, hours / net per hour (and per-hour revenue + counts when
/// [detailed]) in two columns, plus the "no hours" explanation.
class ProfitTiles extends StatelessWidget {
  const ProfitTiles({
    required this.metrics,
    required this.currency,
    this.detailed = false,
    super.key,
  });

  final ProfitMetrics metrics;
  final String currency;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String money(Decimal value) => Formats.currency(value, currency);
    String perHour(Decimal? value) =>
        value == null ? l10n.profitNotAvailable : money(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MetricTileRow(
          tiles: [
            MetricTile(
              icon: Icons.payments_outlined,
              label: l10n.profitRevenue,
              value: money(metrics.totalRevenue),
            ),
            MetricTile(
              icon: Icons.receipt_outlined,
              label: l10n.profitExpenses,
              value: money(metrics.totalExpenses),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        MetricTileRow(
          tiles: [
            MetricTile(
              icon: Icons.schedule_rounded,
              label: l10n.profitWorkingHours,
              value: l10n.profitHoursValue(
                Formats.compact(metrics.workingHours),
              ),
            ),
            MetricTile(
              icon: Icons.speed_rounded,
              label: l10n.profitNetPerHour,
              value: perHour(metrics.netProfitPerHour),
              valueColor: metrics.netProfitPerHour == null
                  ? null
                  : moneyColor(context, metrics.netProfitPerHour!),
            ),
          ],
        ),
        if (detailed) ...[
          const SizedBox(height: AppSpacing.md),
          MetricTileRow(
            tiles: [
              MetricTile(
                icon: Icons.trending_up_rounded,
                label: l10n.profitRevenuePerHour,
                value: perHour(metrics.revenuePerHour),
              ),
              MetricTile(
                icon: Icons.format_list_numbered_rounded,
                label: l10n.profitRecordCounts,
                value: l10n.profitRecordCountsValue(
                  metrics.incomeCount,
                  metrics.expenseCount,
                  metrics.workSessionCount,
                ),
              ),
            ],
          ),
        ],
        if (metrics.netProfitPerHour == null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.profitNoWorkingHours,
                  key: const Key('metrics.noHours'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Positive money in the success colour, negative in the error colour, zero in
/// the normal text colour. The minus sign carries the meaning too.
Color? moneyColor(BuildContext context, Decimal value) {
  if (value > Decimal.zero) return context.semanticColors.success;
  if (value < Decimal.zero) return Theme.of(context).colorScheme.error;
  return null;
}
