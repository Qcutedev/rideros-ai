import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/profit_summary.dart';

/// Net profit per bucket as bars (negative bars point down). Values are converted to
/// `double` only to draw; labels and tooltips use the exact decimals.
class NetProfitChart extends StatelessWidget {
  const NetProfitChart({required this.trends, super.key});

  final ProfitTrends trends;

  static const height = 180.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    final points = trends.points;
    final positive = context.semanticColors.success;
    final negative = theme.colorScheme.error;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    String bucketLabel(DateTime start) => switch (trends.granularity) {
      ProfitPeriod.month => Formats.monthShort(start, locale),
      _ => Formats.dayMonth(start, locale),
    };

    // First, middle and last labels only: 30 daily bars have no room for more.
    final labelled = {0, points.length ~/ 2, points.length - 1};
    final values = [for (final p in points) p.metrics.netProfit.toDouble()];
    final maxAbs = values.fold<double>(0, (m, v) => v.abs() > m ? v.abs() : m);
    final hasNegative = values.any((v) => v < 0);
    final top = maxAbs == 0 ? 1.0 : maxAbs * 1.1;

    return Semantics(
      label: l10n.profitTrendSemantics(points.length),
      // Inset so the first and last date labels stay inside the card.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              minY: hasNegative ? -top : 0,
              maxY: top,
              alignment: BarChartAlignment.spaceBetween,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: top,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: value == 0 ? 1 : 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (!labelled.contains(i) || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          bucketLabel(points[i].startDate),
                          style: labelStyle,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final point = points[group.x];
                    return BarTooltipItem(
                      '${bucketLabel(point.startDate)}\n'
                      '${Formats.currency(point.metrics.netProfit, trends.currency)}',
                      TextStyle(color: theme.colorScheme.onInverseSurface),
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < points.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        width: points.length > 20 ? 5 : 12,
                        color: points[i].metrics.netProfit < Decimal.zero
                            ? negative
                            : positive,
                        borderRadius: BorderRadius.circular(AppRadius.sm / 4),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
