import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

enum BadgeTone {
  /// Sample data and estimates (amber).
  warning,

  /// Neutral source labels such as "Dataset" (mint).
  info,

  /// Neutral, low emphasis (outlined).
  neutral,
}

/// Small rounded label (§5.5): `DEMO`, `ค่าประมาณ`, `Dataset`, `ร้านของฉัน`,
/// data levels. Always text, never colour alone.
class AppBadge extends StatelessWidget {
  const AppBadge({required this.label, this.tone = BadgeTone.info, super.key});

  /// `DEMO` on sample records.
  factory AppBadge.demo(BuildContext context, {Key? key}) => AppBadge(
    key: key,
    label: AppLocalizations.of(context).demoLabel,
    tone: BadgeTone.warning,
  );

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final (Color background, Color foreground, Color? border) = switch (tone) {
      BadgeTone.warning => (semantic.warningContainer, semantic.warning, null),
      BadgeTone.info => (
        semantic.mint,
        theme.colorScheme.onPrimaryContainer,
        null,
      ),
      BadgeTone.neutral => (
        Colors.transparent,
        theme.colorScheme.onSurfaceVariant,
        semantic.border,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
