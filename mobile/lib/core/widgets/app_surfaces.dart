import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import 'motion.dart';

export '../../app/theme/app_theme.dart' show AppTone;

/// Gives [child] the theme of a [tone] surface: text, icons, buttons and
/// semantic colours inside switch to the ones made for that background.
class ToneScope extends StatelessWidget {
  const ToneScope({required this.tone, required this.child, super.key});

  final AppTone tone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (tone == AppTone.paper) return child;
    final theme = AppTheme.toned(Theme.of(context).brightness, tone);
    return Theme(
      data: theme,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: theme.colorScheme.onSurface),
        child: IconTheme.merge(
          data: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
          child: child,
        ),
      ),
    );
  }
}

/// Rounded card on a [tone] surface, the building block of every screen.
/// With [onTap] it becomes a pressable card (scale + ripple).
class ToneCard extends StatelessWidget {
  const ToneCard({
    required this.child,
    this.tone = AppTone.paper,
    this.onTap,
    this.padding = AppSpacing.cardPadding,
    this.radius = AppRadius.lg,
    this.gradient,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final AppTone tone;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Optional overlay gradient over the tone colour (hero cards).
  final Gradient? gradient;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;
    final color = AppTheme.toneColor(brightness, tone);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: isLight
          ? BorderSide.none
          : BorderSide(
              color: tone == AppTone.lime
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.06),
            ),
    );
    Widget content = Padding(padding: padding, child: child);
    if (gradient != null) {
      content = DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: content,
      );
    }
    Widget card = Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    // Soft layered shadow on the light paper and Obsidian cards; colour
    // carries the separation for the others.
    if (isLight && (tone == AppTone.paper || tone == AppTone.obsidian)) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: tone == AppTone.obsidian
              ? AppShadows.floating
              : AppShadows.card,
        ),
        child: card,
      );
    }
    card = ToneScope(tone: tone, child: card);
    if (semanticLabel != null) {
      card = Semantics(label: semanticLabel, child: card);
    }
    return onTap == null ? card : PressableScale(child: card);
  }
}

/// Icon in a filled circle or rounded square. Lime by default.
class IconWell extends StatelessWidget {
  const IconWell({
    required this.icon,
    this.size = 44,
    this.color,
    this.iconColor,
    this.square = false,
    super.key,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Color? iconColor;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? semantic.accent,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(size * 0.32) : null,
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: iconColor ?? semantic.onAccent,
      ),
    );
  }
}

/// Tab-page body: one comfortable column on tablets, centred.
class PageColumn extends StatelessWidget {
  const PageColumn({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSizes.maxPageWidth),
      child: child,
    ),
  );
}

/// Tabs as a segmented pill under the app bar: a sliding Obsidian (light) or
/// lime (dark) pill marks the selected tab.
class PillTabBar extends StatelessWidget implements PreferredSizeWidget {
  const PillTabBar({required this.tabs, this.controller, super.key});

  final List<Widget> tabs;
  final TabController? controller;

  static const _tabHeight = 44.0;
  static const _inset = 4.0;

  @override
  Size get preferredSize =>
      const Size.fromHeight(_tabHeight + _inset * 2 + AppSpacing.md);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.semanticColors.mint,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.all(_inset),
          child: SizedBox(
            height: _tabHeight,
            child: TabBar(
              controller: controller,
              tabs: tabs,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
