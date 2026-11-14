import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/profit_summary.dart';
import '../profit_labels.dart';

/// Legend of [NetProfitChart] plus one sentence about the trend (`analysis` of
/// `GET /profit/trends`). Up/down is only claimed when the server found a significant slope.
class TrendSummary extends StatelessWidget {
  const TrendSummary({required this.trends, super.key});

  final ProfitTrends trends;

  @override
  Widget build(BuildContext context) {
    final analysis = trends.analysis;
    if (analysis == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unit = periodName(l10n, trends.granularity);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final hasAverage = trends.points.any((p) => p.movingAverage != null);
    final hasLine = trends.points.any((p) => p.trend != null);
    final slope = analysis.slopePerBucket;

    final sentence = switch ((analysis.status, analysis.direction)) {
      (TrendStatus.insufficientData, _) => l10n.profitTrendNeedMore(
        analysis.minActiveBuckets,
        analysis.activeBuckets,
        unit,
      ),
      (_, TrendDirection.up) when slope != null => l10n.profitTrendUp(
        Formats.currency(slope.abs(), trends.currency),
        unit,
      ),
      (_, TrendDirection.down) when slope != null => l10n.profitTrendDown(
        Formats.currency(slope.abs(), trends.currency),
        unit,
      ),
      _ => l10n.profitTrendFlat,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _LegendItem(
                swatch: _Swatch.bar(context.semanticColors.success),
                label: l10n.profitTrendLegendNet,
              ),
              if (hasAverage)
                _LegendItem(
                  swatch: _Swatch.line(theme.colorScheme.onSurface),
                  label: l10n.profitTrendLegendAverage(analysis.window, unit),
                ),
              if (hasLine)
                _LegendItem(
                  swatch: _Swatch.dashed(theme.colorScheme.tertiary),
                  label: l10n.profitTrendLegendLine,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(sentence, key: const Key('trendSentence')),
          if (analysis.status == TrendStatus.ok) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppBadge(label: l10n.badgeEstimate, tone: BadgeTone.warning),
                Text(
                  l10n.profitTrendBasis(analysis.activeBuckets, unit),
                  style: muted,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.swatch, required this.label});

  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch.bar(this.color) : _kind = 0;
  const _Swatch.line(this.color) : _kind = 1;
  const _Swatch.dashed(this.color) : _kind = 2;

  final Color color;
  final int _kind;

  @override
  Widget build(BuildContext context) {
    if (_kind == 0) {
      return Container(width: 10, height: 10, color: color);
    }
    final segment = Container(
      width: _kind == 1 ? 16 : 6,
      height: 2,
      color: color,
    );
    if (_kind == 1) return segment;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [segment, const SizedBox(width: 4), segment],
    );
  }
}
