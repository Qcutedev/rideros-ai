import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/status_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/profit_heatmap.dart';
import '../profit_providers.dart';
import 'minimum_progress_bar.dart';
import 'profit_metrics_view.dart';

/// "กำไรต่อชั่วโมงตามช่วงเวลา": estimated net profit per hour by weekday ×
/// 2-hour slot over the last 90 days. Five sequential steps of one hue
/// ([AppColors.heatLight] / [AppColors.heatDark]) for profit; loss and thin
/// cells carry a glyph, so no state is told by colour alone. Tap a cell (or a
/// row of the best list) for its figures; every cell has a spoken label.
class ProfitHeatmapCard extends ConsumerWidget {
  const ProfitHeatmapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(profitHeatmapProvider);
    final ok = value.value?.status == HeatmapStatus.ok;
    return SectionCard(
      key: const Key('profit.heatmap'),
      title: l10n.profitHeatmapTitle,
      trailing: ok
          ? AppBadge(label: l10n.badgeEstimate, tone: BadgeTone.warning)
          : null,
      child: switch (value) {
        AsyncData(:final value) => switch (value.status) {
          HeatmapStatus.insufficientData => _Insufficient(heatmap: value),
          HeatmapStatus.ok => _HeatmapBody(heatmap: value),
        },
        AsyncError(:final error) => AppBanner.failure(
          context,
          error is AppFailure ? error : UnknownFailure(error),
          key: const Key('heatmap.error'),
        ),
        _ => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: SkeletonBox(height: 160),
        ),
      },
    );
  }
}

TextStyle? _muted(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );
}

class _Insufficient extends StatelessWidget {
  const _Insufficient({required this.heatmap});

  final ProfitHeatmap heatmap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = _muted(context);
    return Column(
      key: const Key('heatmap.insufficient'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.profitHeatmapInsufficient(heatmap.sessionsMissing)),
        const SizedBox(height: AppSpacing.sm),
        MinimumProgressBar(
          have: heatmap.sessionCount,
          need: heatmap.minSessions,
          barKey: const Key('heatmap.progress'),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.profitHeatmapProgress(
            heatmap.sessionCount,
            heatmap.minSessions,
            heatmap.windowDays,
          ),
          style: muted,
        ),
        if (heatmap.excludedSessionCount > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.profitHeatmapUnpaidSessions(heatmap.excludedSessionCount),
            key: const Key('heatmap.unpaid'),
            style: muted,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.profitHeatmapTimerHint, style: muted),
      ],
    );
  }
}

class _HeatmapBody extends StatefulWidget {
  const _HeatmapBody({required this.heatmap});

  final ProfitHeatmap heatmap;

  @override
  State<_HeatmapBody> createState() => _HeatmapBodyState();
}

class _HeatmapBodyState extends State<_HeatmapBody> {
  (int, int)? _selected;

  void _select(int weekday, int slot) =>
      setState(() => _selected = (weekday, slot));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = _muted(context);
    final heatmap = widget.heatmap;
    final scale = HeatScale(heatmap.cells);
    final best = heatmap.best();
    final ranks = {
      for (final (i, c) in best.indexed) (c.weekday, c.slot): i + 1,
    };
    final average = heatmap.netProfitPerHour;
    final excluded =
        heatmap.excludedIncomeCount +
        heatmap.excludedExpenseCount +
        heatmap.excludedSessionCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RevealFromStart(
          child: _HeatGrid(
            heatmap: heatmap,
            scale: scale,
            ranks: ranks,
            selected: _selected,
            onSelect: _select,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Legend(scale: scale, currency: heatmap.currency),
        const SizedBox(height: AppSpacing.md),
        _CellDetail(heatmap: heatmap, selected: _selected, ranks: ranks),
        const Divider(height: AppSpacing.xl),
        Text(l10n.profitHeatmapBestTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        if (best.isEmpty)
          Text(
            l10n.profitHeatmapBestNone(heatmap.minCellSessions),
            key: const Key('heatmap.bestNone'),
            style: muted,
          )
        else
          for (final (i, cell) in best.indexed)
            _BestRow(
              key: Key('heatmap.best.$i'),
              rank: i + 1,
              cell: cell,
              heatmap: heatmap,
              onTap: () => _select(cell.weekday, cell.slot),
            ),
        if (average != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.profitHeatmapAverage(
              Formats.currency(average, heatmap.currency),
            ),
            key: const Key('heatmap.average'),
            style: muted,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.profitHeatmapNote(heatmap.sessionCount, heatmap.windowDays),
          style: muted,
        ),
        if (excluded > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.profitHeatmapExcluded(
              heatmap.excludedIncomeCount,
              heatmap.excludedExpenseCount,
              heatmap.excludedSessionCount,
            ),
            key: const Key('heatmap.excluded'),
            style: muted,
          ),
        ],
      ],
    );
  }
}

// ---- grid ----

const _labelWidth = 44.0;
const _cellHeight = 26.0;

/// Fill, glyph and colours of one cell; shared by the grid and the legend.
class _CellStyle {
  const _CellStyle({required this.fill, this.glyph, this.ink, this.outline});

  factory _CellStyle.of(
    BuildContext context,
    HeatmapCell? cell,
    HeatScale scale, {
    int? rank,
  }) {
    final c = _HeatColors.of(context);
    if (cell == null) {
      return _CellStyle(fill: Colors.transparent, outline: c.outline);
    }
    if (!cell.hasEstimate) {
      return _CellStyle(fill: c.thin, glyph: '·', ink: c.thinInk);
    }
    final level = scale.levelOf(cell.netProfitPerHour!);
    if (level == 0) {
      return _CellStyle(fill: c.loss, glyph: '−', ink: c.lossInk);
    }
    final fill = c.ramp[level - 1];
    return _CellStyle(
      fill: fill,
      glyph: rank == null ? null : '$rank',
      ink: ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
          ? AppColors.ivory
          : AppColors.obsidian,
    );
  }

  final Color fill;
  final String? glyph;
  final Color? ink;
  final Color? outline;
}

class _HeatColors {
  const _HeatColors({
    required this.ramp,
    required this.thin,
    required this.thinInk,
    required this.loss,
    required this.lossInk,
    required this.outline,
  });

  factory _HeatColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    return _HeatColors(
      ramp: light ? AppColors.heatLight : AppColors.heatDark,
      thin: light ? AppColors.mist : AppColors.darkSurfaceHighest,
      thinInk: light ? AppColors.textSecondary : AppColors.darkTextSecondary,
      loss: light ? AppColors.errorSurface : AppColors.darkErrorSurface,
      lossInk: theme.colorScheme.error,
      outline: light ? AppColors.border : AppColors.darkBorder,
    );
  }

  final List<Color> ramp;
  final Color thin;
  final Color thinInk;
  final Color loss;
  final Color lossInk;
  final Color outline;
}

class _HeatGrid extends StatelessWidget {
  const _HeatGrid({
    required this.heatmap,
    required this.scale,
    required this.ranks,
    required this.selected,
    required this.onSelect,
  });

  final ProfitHeatmap heatmap;
  final HeatScale scale;
  final Map<(int, int), int> ranks;
  final (int, int)? selected;
  final void Function(int weekday, int slot) onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final axis = AppTypography.figures(theme.textTheme.labelSmall);
    return Semantics(
      container: true,
      label: l10n.profitHeatmapGridLabel(heatmap.slotHours),
      child: Column(
        key: const Key('heatmap.grid'),
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                const SizedBox(width: _labelWidth),
                for (var day = 0; day < 7; day++)
                  Expanded(
                    child: Text(
                      weekdayShort(l10n, day),
                      textAlign: TextAlign.center,
                      style: axis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var slot = 0; slot < heatmap.slotsPerDay; slot++)
            Row(
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: ExcludeSemantics(
                    child: Text(
                      hourLabel(slot * heatmap.slotHours),
                      style: axis,
                    ),
                  ),
                ),
                for (var day = 0; day < 7; day++)
                  Expanded(
                    child: _Cell(
                      key: Key('heatmap.cell.$day.$slot'),
                      heatmap: heatmap,
                      cell: heatmap.cellAt(day, slot),
                      weekday: day,
                      slot: slot,
                      style: _CellStyle.of(
                        context,
                        heatmap.cellAt(day, slot),
                        scale,
                        rank: ranks[(day, slot)],
                      ),
                      rank: ranks[(day, slot)],
                      selected: selected == (day, slot),
                      onTap: () => onSelect(day, slot),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.heatmap,
    required this.cell,
    required this.weekday,
    required this.slot,
    required this.style,
    required this.rank,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final ProfitHeatmap heatmap;
  final HeatmapCell? cell;
  final int weekday;
  final int slot;
  final _CellStyle style;
  final int? rank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final glyph = style.glyph == null
        ? null
        : Text(
            style.glyph!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: style.ink,
              fontWeight: FontWeight.w700,
            ),
          );
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.profitHeatmapCellSemantics(
        weekdayLabelFull(l10n, weekday),
        slotRange(slot, heatmap.slotHours),
        cellDetailText(l10n, heatmap, cell, rank: rank),
      ),
      onTap: onTap,
      excludeSemantics: true,
      child: Padding(
        // 1 dp on every side: a 2 dp surface gap between neighbouring cells.
        padding: const EdgeInsets.all(1),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: motionEnabled(context)
                ? AppDurations.fast
                : Duration.zero,
            height: _cellHeight,
            alignment: Alignment.center,
            // Selected: an ink ring, then a surface hairline, then the fill,
            // so the ring stands out on the lightest and the darkest step.
            padding: EdgeInsets.all(selected ? 2 : 0),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.onSurface : style.fill,
              borderRadius: BorderRadius.circular(4),
              border: selected || style.outline == null
                  ? null
                  : Border.all(color: style.outline!),
            ),
            child: selected
                ? Container(
                    key: const Key('heatmap.selected'),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: style.fill,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                    child: glyph,
                  )
                : glyph,
          ),
        ),
      ),
    );
  }
}

// ---- legend, detail, best list ----

class _Legend extends StatelessWidget {
  const _Legend({required this.scale, required this.currency});

  final HeatScale scale;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = _muted(context);
    final colors = _HeatColors.of(context);
    final lo = scale.min, hi = scale.max;
    return Wrap(
      key: const Key('heatmap.legend'),
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (lo != null && hi != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.profitHeatmapLegendLow, style: muted),
              const SizedBox(width: AppSpacing.xs),
              for (final color in colors.ramp) _Swatch(fill: color),
              const SizedBox(width: AppSpacing.xs),
              Text(l10n.profitHeatmapLegendHigh, style: muted),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.profitHeatmapLegendRange(
                  Formats.currency(lo, currency),
                  Formats.currency(hi, currency),
                ),
                key: const Key('heatmap.legendRange'),
                style: muted,
              ),
            ],
          ),
        _LegendItem(
          swatch: _Swatch(fill: colors.loss, glyph: '−', ink: colors.lossInk),
          label: l10n.profitHeatmapLegendLoss,
        ),
        _LegendItem(
          swatch: _Swatch(fill: colors.thin, glyph: '·', ink: colors.thinInk),
          label: l10n.profitHeatmapLegendThin,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.swatch, required this.label});

  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      swatch,
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: _muted(context)),
    ],
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.fill, this.glyph, this.ink});

  final Color fill;
  final String? glyph;
  final Color? ink;

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    margin: const EdgeInsets.symmetric(horizontal: 1),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(3),
    ),
    child: glyph == null
        ? null
        : Text(
            glyph!,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: ink, fontWeight: FontWeight.w700, height: 1),
          ),
  );
}

class _CellDetail extends StatelessWidget {
  const _CellDetail({
    required this.heatmap,
    required this.selected,
    required this.ranks,
  });

  final ProfitHeatmap heatmap;
  final (int, int)? selected;
  final Map<(int, int), int> ranks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = _muted(context);
    final key = selected;
    final Widget content;
    if (key == null) {
      content = Text(l10n.profitHeatmapTapHint, style: muted);
    } else {
      final (weekday, slot) = key;
      final cell = heatmap.cellAt(weekday, slot);
      final perHour = cell?.netProfitPerHour;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${weekdayLabelFull(l10n, weekday)} '
                  '${slotRange(slot, heatmap.slotHours)}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (ranks[key] case final rank?)
                AppBadge(label: l10n.profitHeatmapRank(rank)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (cell != null && perHour != null) ...[
            Text(
              l10n.profitHeatmapPerHour(
                Formats.currency(perHour, heatmap.currency),
              ),
              key: const Key('heatmap.detail.perHour'),
              style: AppTypography.figures(theme.textTheme.titleMedium)
                  ?.copyWith(color: moneyColor(context, perHour)),
            ),
            Text(
              l10n.profitHeatmapCellDetail(
                Formats.currency(cell.revenuePerHour!, heatmap.currency),
                Formats.compact(cell.hours),
                cell.sessionCount,
              ),
              style: muted,
            ),
          ] else
            Text(cellDetailText(l10n, heatmap, cell), style: muted),
        ],
      );
    }
    return Container(
      key: const Key('heatmap.detail'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.semanticColors.mint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: content,
    );
  }
}

class _BestRow extends StatelessWidget {
  const _BestRow({
    required this.rank,
    required this.cell,
    required this.heatmap,
    required this.onTap,
    super.key,
  });

  final int rank;
  final HeatmapCell cell;
  final ProfitHeatmap heatmap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final perHour = cell.netProfitPerHour!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: semantic.accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: semantic.onAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                '${weekdayLabelFull(l10n, cell.weekday)} '
                '${slotRange(cell.slot, heatmap.slotHours)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              l10n.profitHeatmapPerHour(
                Formats.currency(perHour, heatmap.currency),
              ),
              style: AppTypography.figures(theme.textTheme.titleSmall)
                  ?.copyWith(color: moneyColor(context, perHour)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- labels (public for tests) ----

/// `จ.` for 0 (Monday) ... `อา.` for 6.
String weekdayShort(AppLocalizations l10n, int weekday) =>
    // 1 Jan 2024 was a Monday.
    DateFormat.E(l10n.localeName).format(DateTime(2024, 1, 1 + weekday));

/// `วันจันทร์` for 0 (Monday) ... `วันอาทิตย์` for 6.
String weekdayLabelFull(AppLocalizations l10n, int weekday) =>
    DateFormat.EEEE(l10n.localeName).format(DateTime(2024, 1, 1 + weekday));

/// `08:00`
String hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

/// `18:00–20:00`; the last slot ends at `24:00`.
String slotRange(int slot, int slotHours) =>
    '${hourLabel(slot * slotHours)}–${hourLabel((slot + 1) * slotHours)}';

/// What one cell holds, in words: the spoken label and the detail panel.
String cellDetailText(
  AppLocalizations l10n,
  ProfitHeatmap heatmap,
  HeatmapCell? cell, {
  int? rank,
}) {
  if (cell == null) return l10n.profitHeatmapCellEmpty;
  final perHour = cell.netProfitPerHour;
  if (perHour == null) {
    return l10n.profitHeatmapCellThin(
      cell.sessionCount,
      Formats.compact(cell.hours),
      heatmap.minCellSessions,
      heatmap.minCellHours,
    );
  }
  return [
    if (rank != null) l10n.profitHeatmapRank(rank),
    '${l10n.profitNetPerHour} '
        '${Formats.currency(perHour, heatmap.currency)}',
    l10n.profitHeatmapCellDetail(
      Formats.currency(cell.revenuePerHour!, heatmap.currency),
      Formats.compact(cell.hours),
      cell.sessionCount,
    ),
  ].join(' · ');
}
