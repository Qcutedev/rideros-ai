import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/pickup_models.dart';
import '../pickup_labels.dart';

/// 24 hourly cells (6 x 4) of the dataset median Order-to-Pickup minutes.
///
/// One-hue sequential scale in five steps (mint → primary, stronger = longer) relative to this
/// restaurant's own range. Hours without a median stay empty: nothing is filled in.
/// Each cell has a tooltip and a screen-reader label with the hour, median and
/// order count; the text colour is chosen for contrast on the cell.
class HourlyHeatmap extends StatelessWidget {
  const HourlyHeatmap({required this.cells, super.key});

  final List<StatCell> cells;

  static const _columns = 6;

  @override
  Widget build(BuildContext context) {
    final byHour = {for (final c in cells) c.hour: c};
    final medians = [
      for (final c in cells)
        if (c.nOrders > 0 && c.medianMin != null) c.medianMin!.toDouble(),
    ];
    final min = medians.isEmpty ? 0.0 : medians.reduce((a, b) => a < b ? a : b);
    final max = medians.isEmpty ? 0.0 : medians.reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (var row = 0; row < 24 ~/ _columns; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                for (var col = 0; col < _columns; col++) ...[
                  if (col > 0) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _Cell(
                      hour: row * _columns + col,
                      cell: byHour[row * _columns + col],
                      min: min,
                      max: max,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.hour,
    required this.cell,
    required this.min,
    required this.max,
  });

  final int hour;
  final StatCell? cell;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final hourText = hour.toString().padLeft(2, '0');
    final Decimal? median = (cell != null && cell!.nOrders > 0)
        ? cell!.medianMin
        : null;

    if (median == null) {
      final label = l10n.heatmapCellEmpty(hourText);
      return Tooltip(
        message: label,
        child: Semantics(
          label: label,
          child: ExcludeSemantics(
            child: Container(
              key: Key('heatmap.$hour'),
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: semantic.border),
              ),
              alignment: Alignment.center,
              child: Text(
                hourText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final t = max > min ? (median.toDouble() - min) / (max - min) : 0.5;
    final steps = theme.brightness == Brightness.dark
        ? _darkSteps
        : _lightSteps;
    final step = (t * steps.length).floor().clamp(0, steps.length - 1);
    final fill = Color.lerp(
      semantic.mint,
      theme.colorScheme.primary,
      steps[step],
    )!;
    final ink = _inkFor(fill);
    final label = l10n.heatmapCell(hourText, minutes1(median), cell!.nOrders);
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: ExcludeSemantics(
          child: Container(
            key: Key('heatmap.$hour'),
            height: 52,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hourText,
                  style: theme.textTheme.labelSmall?.copyWith(color: ink),
                ),
                Text(
                  minutes1(median),
                  style: AppTypography.figures(
                    theme.textTheme.labelLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Five steps from mint to the primary colour. Chosen so that the better of
  /// dark text and white keeps >= 4.5:1 on every step (WCAG AA), in both themes.
  static const _lightSteps = [0.12, 0.3, 0.5, 0.7, 1.0];
  static const _darkSteps = [0.1, 0.25, 0.45, 0.7, 1.0];

  /// The text colour (dark ink or white) with the higher contrast on [fill].
  static Color _inkFor(Color fill) {
    const dark = AppColors.textPrimary;
    const light = Colors.white;
    return _contrast(fill, dark) >= _contrast(fill, light) ? dark : light;
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }
}
