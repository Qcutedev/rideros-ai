import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Scrollable, width-limited (480 dp) column for form screens. Scrolls above
/// the keyboard so the save button is never covered.
class FormLayout extends StatelessWidget {
  const FormLayout({
    required this.children,
    this.title,
    this.subtitle,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Top-aligned: a short form (one field) starts under the app bar, not mid-screen.
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Text(title!, style: theme.textTheme.headlineSmall),
                if (subtitle != null) ...[
                  if (title != null) const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (title != null || subtitle != null)
                  const SizedBox(height: AppSpacing.xl),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical gap between form fields.
const formGap = SizedBox(height: AppSpacing.lg);

/// RiderOS AI logo mark: rider icon in a rounded green tile.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({this.size = 64, this.onDark = false, super.key});

  final double size;

  /// On the Forest Green splash: mint tile with a green icon.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final background = onDark ? AppColors.mint : AppColors.brand;
    final foreground = onDark ? AppColors.forest : Colors.white;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.two_wheeler_rounded,
              size: size * 0.6,
              color: foreground,
            ),
            Positioned(
              right: size * 0.14,
              top: size * 0.14,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: size * 0.22,
                color: onDark ? AppColors.brand : AppColors.mint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo, app name and tagline (login and splash).
class AppWordmark extends StatelessWidget {
  const AppWordmark({
    required this.title,
    this.tagline,
    this.onDark = false,
    super.key,
  });

  final String title;
  final String? tagline;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = onDark ? Colors.white : theme.colorScheme.onSurface;
    final taglineColor = onDark
        ? context.semanticColors.onHeroMuted
        : theme.colorScheme.onSurfaceVariant;
    return Column(
      children: [
        AppLogoMark(size: 72, onDark: onDark),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(color: titleColor),
        ),
        if (tagline != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            tagline!,
            style: theme.textTheme.bodyMedium?.copyWith(color: taglineColor),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
