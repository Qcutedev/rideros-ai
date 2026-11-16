import 'package:flutter/material.dart';

import '../../app/intro/brand_logo.dart';
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
                  Text(
                    title!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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

/// RiderOS AI logo mark: the brand emblem (speed trails and rider) from
/// `assets/brand/rideros_logo.svg`, the same artwork as the ride intro and the
/// launcher icon. On the Obsidian headers it is drawn in ivory on the dark
/// itself; elsewhere in ivory on a rounded Obsidian tile.
/// [size] is the height; the emblem is wider than tall.
class AppLogoMark extends StatefulWidget {
  const AppLogoMark({this.size = 64, this.onDark = false, super.key});

  final double size;

  /// On the Obsidian header: no tile.
  final bool onDark;

  @override
  State<AppLogoMark> createState() => _AppLogoMarkState();
}

class _AppLogoMarkState extends State<AppLogoMark> {
  /// Parsed once per asset bundle (the app has one; tests may swap it).
  static final _logos = Expando<Future<BrandLogo>>();

  Future<BrandLogo>? _logo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    _logo = _logos[bundle] ??= BrandLogo.load(bundle);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    // Emblem box: wider than tall; inside a tile it gets a margin.
    final emblem = widget.onDark
        ? Size(size * 1.5, size)
        : Size(size * 0.72, size * 0.72);
    Widget mark = FutureBuilder<BrandLogo>(
      future: _logo,
      builder: (context, snapshot) => SizedBox.fromSize(
        size: emblem,
        child: snapshot.data == null
            ? null
            : CustomPaint(
                painter: BrandEmblemPainter(
                  snapshot.data!,
                  AppColors.logoIvory,
                ),
              ),
      ),
    );
    if (!widget.onDark) {
      mark = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // Raised a step in dark mode so the tile reads on the dark page.
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurfaceHighest
              : AppColors.obsidian,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: mark,
      );
    }
    return ExcludeSemantics(child: mark);
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
