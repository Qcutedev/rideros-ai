import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import 'app_surfaces.dart';

export 'app_surfaces.dart'
    show AppTone, IconWell, PageColumn, ToneCard, ToneScope;

/// Section title with an optional trailing action, above a group of content.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.1),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Card with a header and content (§5.3 summary card). [tone] picks the
/// surface; screens alternate tones so not every card is white.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    this.tone = AppTone.paper,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    return ToneCard(
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, trailing: trailing),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

/// Label + value tile on the soft secondary surface; two per row on phones.
class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md + AppSpacing.xxs,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: semantic.mint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: theme.colorScheme.onSurface),
                  const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTypography.figures(
                theme.textTheme.titleMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiles in equal columns (two on a phone).
class MetricTileRow extends StatelessWidget {
  const MetricTileRow({required this.tiles, super.key});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(child: tiles[i]),
        ],
      ],
    ),
  );
}

/// Card holding list rows (e.g. settings or entry points), divided by thin lines.
class TileGroup extends StatelessWidget {
  const TileGroup({
    required this.children,
    this.tone = AppTone.paper,
    super.key,
  });

  final List<Widget> children;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    return ToneCard(
      tone: tone,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Builder(
                builder: (context) => Divider(
                  height: 1,
                  indent: AppSpacing.lg,
                  endIndent: AppSpacing.lg,
                  color: context.semanticColors.border,
                ),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
