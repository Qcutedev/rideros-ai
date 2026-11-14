import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/profit_summary.dart';

/// Net profit per bucket as bars (negative bars point down), with the moving average (solid line)
/// and the linear trend (dashed, only when significant) drawn over them. Values are converted to
/// `double` only to draw; labels and tooltips use the exact decimals.
class NetProfitChart extends StatelessWidget {
  const NetProfitChart({required this.trends, super.key});

  final ProfitTrends trends;

  static const height = 180.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final points = trends.points;
    final values = [for (final p in points) p.metrics.netProfit.toDouble()];
    final averages = [for (final p in points) p.movingAverage?.toDouble()];
    final trendValues = [for (final p in points) p.trend?.toDouble()];
    final drawn = [...values, ...averages.nonNulls, ...trendValues.nonNulls];
    final maxAbs = drawn.fold<double>(0, (m, v) => v.abs() > m ? v.abs() : m);
    final hasNegative = drawn.any((v) => v < 0);
    final top = maxAbs == 0 ? 1.0 : maxAbs * 1.1;
    final minY = hasNegative ? -top : 0.0;
    final barWidth = points.length > 20 ? 5.0 : 12.0;
    final averageColor = theme.colorScheme.onSurface;
    final trendColor = theme.colorScheme.tertiary;

    return Semantics(
      label: l10n.profitTrendSemantics(points.length),
      // Inset so the first and last date labels stay inside the card.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: _bars(context, minY, top, barWidth)),
              if (averages.any((v) => v != null) ||
                  trendValues.any((v) => v != null))
                // Same y range; inset by half a bar so line points sit on the bar centres
                // (`spaceBetween` puts the first and last bar flush with the edges), and
                // above the date labels. Touches go through to the bars' tooltips.
                Positioned.fill(
                  bottom: _labelsHeight,
                  left: barWidth / 2,
                  right: barWidth / 2,
                  child: IgnorePointer(
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (points.length - 1).toDouble().clamp(1, 1e9),
                        minY: minY,
                        maxY: top,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        lineTouchData: const LineTouchData(enabled: false),
                        lineBarsData: [
                          ..._segments(averages, averageColor, dashed: false),
                          ..._segments(trendValues, trendColor, dashed: true),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static const _labelsHeight = 24.0;

  /// One line per run of consecutive non-null values (fl_chart draws no gaps on its own).
  static List<LineChartBarData> _segments(
    List<double?> values,
    Color color, {
    required bool dashed,
  }) {
    final segments = <LineChartBarData>[];
    var run = <FlSpot>[];
    void close() {
      if (run.isNotEmpty) {
        segments.add(
          LineChartBarData(
            spots: run,
            color: color,
            barWidth: 2,
            dashArray: dashed ? const [6, 4] : null,
            dotData: FlDotData(show: run.length == 1),
          ),
        );
      }
      run = <FlSpot>[];
    }

    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) {
        close();
      } else {
        run.add(FlSpot(i.toDouble(), v));
      }
    }
    close();
    return segments;
  }

  Widget _bars(BuildContext context, double minY, double top, double width) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    final points = trends.points;
    final positive = context.semanticColors.success;
    final negative = theme.colorScheme.error;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    // First, middle and last labels only: 30 daily bars have no room for more.
    final labelled = {0, points.length ~/ 2, points.length - 1};
    final values = [for (final p in points) p.metrics.netProfit.toDouble()];

    String bucketLabel(DateTime start) => switch (trends.granularity) {
      ProfitPeriod.month => Formats.monthShort(start, locale),
      _ => Formats.dayMonth(start, locale),
    };

    return BarChart(
      BarChartData(
        minY: minY,
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
              reservedSize: _labelsHeight,
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
                  width: width,
                  color: points[i].metrics.netProfit < Decimal.zero
                      ? negative
                      : positive,
                  borderRadius: BorderRadius.circular(AppRadius.sm / 4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
