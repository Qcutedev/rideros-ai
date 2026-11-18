import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/motion.dart';
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
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: MoneyFigure(
            value: metrics.netProfit,
            currency: currency,
            textKey: const Key('metrics.net'),
            style: theme.textTheme.displaySmall?.copyWith(
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

/// Money that counts up to its value (see [AnimatedFigure]); the final text is
/// the exact formatted amount.
class MoneyFigure extends StatelessWidget {
  const MoneyFigure({
    required this.value,
    required this.currency,
    this.style,
    this.textKey,
    super.key,
  });

  final Decimal value;
  final String currency;
  final TextStyle? style;
  final Key? textKey;

  @override
  Widget build(BuildContext context) => AnimatedFigure(
    value: value.toDouble(),
    text: Formats.currency(value, currency),
    format: (v) =>
        Formats.currency(Decimal.parse(v.toStringAsFixed(2)), currency),
    textKey: textKey,
    style: AppTypography.figures(style),
  );
}

/// Headline card of the home screen (§4.2): an Obsidian card with a soft lime
/// glow, net profit in the largest figure size, then the revenue / expense /
/// hours tiles.
class ProfitHeroCard extends StatelessWidget {
  const ProfitHeroCard({
    required this.title,
    required this.metrics,
    required this.currency,
    this.goal,
    super.key,
  });

  final String title;
  final ProfitMetrics metrics;
  final String currency;

  /// Shown between the net profit and the tiles (Home's daily goal).
  final Widget? goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ToneCard(
      tone: AppTone.obsidian,
      radius: AppRadius.xl,
      padding: EdgeInsets.zero,
      gradient: const RadialGradient(
        center: Alignment(1.1, -1.2),
        radius: 1.25,
        colors: [Color(0x38D5FF83), Color(0x00D5FF83)],
      ),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final semantic = context.semanticColors;
          final scheme = theme.colorScheme;
          final net = metrics.netProfit;
          final netColor = net > Decimal.zero
              ? semantic.heroPositive
              : net < Decimal.zero
              ? semantic.heroNegative
              : scheme.onSurface;
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.card,
              AppSpacing.card,
              AppSpacing.card,
              AppSpacing.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: semantic.mint,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.today_rounded,
                            size: 16,
                            color: semantic.accent,
                          ),
                          const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
                          Flexible(
                            child: Semantics(
                              header: true,
                              child: Text(
                                title,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.profitNet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: MoneyFigure(
                    value: net,
                    currency: currency,
                    textKey: const Key('metrics.net'),
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: netColor,
                    ),
                  ),
                ),
                if (goal case final goal?) ...[
                  const SizedBox(height: AppSpacing.lg),
                  goal,
                ],
                const SizedBox(height: AppSpacing.xl),
                ProfitTiles(metrics: metrics, currency: currency),
              ],
            ),
          );
        },
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
