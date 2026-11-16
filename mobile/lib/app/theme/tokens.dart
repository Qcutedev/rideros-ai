import 'package:flutter/material.dart';

/// Design tokens ("Lime Obsidian", `docs/RIDEROS_UI_DESIGN.md` §2). Widgets use
/// these (or the `ThemeData` built from them), never raw numbers or colours.
///
/// Contrast (WCAG 2.1, checked by hand against the relative luminance):
/// Obsidian on Electric Lime ≈ 15:1, on Sage ≈ 9.6:1, on Muted Teal ≈ 7.6:1,
/// on Mist ≈ 13:1. Lime on Ivory is only ≈ 1.05:1, so lime is never a text or
/// boundary colour on light surfaces: light-mode filled buttons are Obsidian
/// with a lime label, and lime fills always carry Obsidian content.
abstract final class AppColors {
  // Brand palette.
  static const lime = Color(0xFFD5FF83);
  static const sage = Color(0xFF9DC9B4);
  static const teal = Color(0xFF78B6A4);
  static const obsidian = Color(0xFF151A17);
  static const ivory = Color(0xFFF5F6F1);
  static const mist = Color(0xFFDDE3DC);

  // Light mode.
  static const background = ivory;
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = obsidian;
  static const textSecondary = Color(0xFF56615A);
  static const border = Color(0xFFE4E8E2);

  /// Input outlines: ≥ 3:1 against [surface] (WCAG 1.4.11).
  static const borderStrong = Color(0xFF828E86);

  /// Positive money on light surfaces (≥ 4.5:1 on white, Ivory and Mist).
  static const success = Color(0xFF3D6B12);
  static const warning = Color(0xFF8A5A00);
  static const warningSurface = Color(0xFFFFF1D6);
  static const error = Color(0xFFB3261E);
  static const errorSurface = Color(0xFFFBE9E7);

  /// Text accents (links, focus) that need contrast on light surfaces.
  static const tealInk = Color(0xFF2C6658);

  // Dark mode: true dark Obsidian surfaces, not an inverted light theme.
  static const darkBackground = Color(0xFF0D100E);
  static const darkSurface = Color(0xFF171D19);
  static const darkSurfaceElevated = Color(0xFF1F2621);
  static const darkSurfaceHighest = Color(0xFF29312C);
  static const darkTextPrimary = Color(0xFFEEF1EA);
  static const darkTextSecondary = Color(0xFFA3ADA5);
  static const darkBorder = Color(0xFF29312C);
  static const darkBorderStrong = Color(0xFF6B776E);
  static const darkSuccess = lime;
  static const darkWarning = Color(0xFFFFC266);
  static const darkWarningSurface = Color(0xFF3B2C0A);
  static const darkError = Color(0xFFFF8F80);
  static const darkErrorSurface = Color(0xFF3A1E1B);

  // Brand logo (`assets/brand/rideros_logo.svg`): ivory mark, muted mint "OS".
  static const logoIvory = Color(0xFFF3EEE5);
  static const logoMint = Color(0xFF8FD1A6);
}

/// Spacing scale: 4, 8, 12, 16, 20, 24, 32 dp (plus 2 and 48 for fine/large gaps).
abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const card = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Padding of a screen body.
  static const screen = EdgeInsets.fromLTRB(lg + xxs, lg, lg + xxs, xxl);

  /// Padding inside a card.
  static const cardPadding = EdgeInsets.all(card);

  /// Gap between stacked cards.
  static const cardGap = md;
}

abstract final class AppRadius {
  static const sm = 10.0;

  /// Inputs, tiles and chips.
  static const md = 16.0;

  /// Buttons are stadium shaped.
  static const button = 999.0;

  /// Cards.
  static const lg = 24.0;

  /// Dialogs, bottom sheets and the hero card.
  static const xl = 28.0;

  static const pill = 999.0;
}

abstract final class AppSizes {
  /// Primary button height.
  static const buttonHeight = 54.0;

  /// Minimum touch target.
  static const minTouch = 48.0;
  static const iconLg = 48.0;
  static const iconXl = 72.0;

  /// Forms and status views stay readable on tablets.
  static const maxContentWidth = 480.0;

  /// Tab pages stay in one comfortable column on tablets.
  static const maxPageWidth = 640.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 450);

  /// Counters and charts drawing in.
  static const reveal = Duration(milliseconds: 900);

  /// Ride intro at app start: ride in and hold, then ride off and fade (≈3 s).
  static const introReveal = Duration(milliseconds: 2400);
  static const introExit = Duration(milliseconds: 600);
}

abstract final class AppCurves {
  /// Content entering: quick start, soft landing.
  static const enter = Curves.easeOutCubic;

  /// Press feedback and selection changes.
  static const standard = Curves.easeInOutCubic;
}

/// Soft layered shadows (light mode only; dark mode separates by surface tone).
abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x0F151A17), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A151A17), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const floating = [
    BoxShadow(color: Color(0x29151A17), blurRadius: 30, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x14151A17), blurRadius: 6, offset: Offset(0, 2)),
  ];
}

/// Type scale (§2.4): IBM Plex Sans Thai, bundled under `assets/fonts/` (OFL).
abstract final class AppTypography {
  static const fontFamily = 'IBMPlexSansThai';

  /// Display 32 · H1 24 · H2 20 · H3 18 · Body 16 · Body small 14 · Caption 12.
  /// Display large (44) is reserved for the hero figure.
  static TextTheme textTheme(Color primary, Color secondary) {
    TextStyle style(
      double size,
      FontWeight weight,
      double height,
      Color c, [
      double spacing = 0,
    ]) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: c,
      letterSpacing: spacing,
    );
    final display = style(32, FontWeight.w700, 1.15, primary, -0.5);
    final h1 = style(24, FontWeight.w700, 1.3, primary, -0.2);
    return TextTheme(
      displayLarge: style(44, FontWeight.w700, 1.1, primary, -1),
      displayMedium: style(38, FontWeight.w700, 1.1, primary, -0.8),
      displaySmall: display,
      headlineLarge: style(28, FontWeight.w700, 1.25, primary, -0.4),
      headlineMedium: h1,
      headlineSmall: h1,
      titleLarge: style(20, FontWeight.w600, 1.3, primary),
      titleMedium: style(18, FontWeight.w600, 1.35, primary),
      titleSmall: style(16, FontWeight.w600, 1.4, primary),
      bodyLarge: style(16, FontWeight.w400, 1.5, primary),
      bodyMedium: style(14, FontWeight.w400, 1.45, primary),
      bodySmall: style(12, FontWeight.w400, 1.4, secondary),
      labelLarge: style(16, FontWeight.w600, 1.25, primary),
      labelMedium: style(14, FontWeight.w500, 1.3, primary),
      labelSmall: style(12, FontWeight.w500, 1.3, secondary, 0.2),
    );
  }

  /// Money and other figures: equal-width digits so columns line up.
  static TextStyle? figures(TextStyle? style) =>
      style?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

/// Semantic colours Material 3 does not provide: positive money, warnings and
/// estimates, the hero card, the accent fill and the secondary text/border
/// tokens. Inside a [toned surface](AppTone) these are re-derived for that tone.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.warningContainer,
    required this.mint,
    required this.border,
    required this.textSecondary,
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.heroPositive,
    required this.heroNegative,
    required this.accent,
    required this.onAccent,
  });

  static const light = AppSemanticColors(
    success: AppColors.success,
    warning: AppColors.warning,
    warningContainer: AppColors.warningSurface,
    mint: AppColors.mist,
    border: AppColors.border,
    textSecondary: AppColors.textSecondary,
    hero: AppColors.obsidian,
    onHero: AppColors.ivory,
    onHeroMuted: Color(0xFFAEB8B0),
    heroPositive: AppColors.lime,
    heroNegative: AppColors.darkError,
    accent: AppColors.lime,
    onAccent: AppColors.obsidian,
  );

  static const dark = AppSemanticColors(
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    warningContainer: AppColors.darkWarningSurface,
    mint: AppColors.darkSurfaceHighest,
    border: AppColors.darkBorder,
    textSecondary: AppColors.darkTextSecondary,
    hero: AppColors.darkSurfaceElevated,
    onHero: AppColors.darkTextPrimary,
    onHeroMuted: AppColors.darkTextSecondary,
    heroPositive: AppColors.lime,
    heroNegative: AppColors.darkError,
    accent: AppColors.lime,
    onAccent: AppColors.obsidian,
  );

  /// Positive money, success.
  final Color success;
  final Color warning;
  final Color warningContainer;

  /// Soft secondary surface: metric tiles, info banners, icon wells.
  final Color mint;
  final Color border;
  final Color textSecondary;

  /// Background of the headline card (Obsidian).
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;

  /// Profit colours that keep ≥ 4.5:1 contrast on [hero].
  final Color heroPositive;
  final Color heroNegative;

  /// Electric Lime fill (active states, highlights) and its content colour.
  final Color accent;
  final Color onAccent;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? warningContainer,
    Color? mint,
    Color? border,
    Color? textSecondary,
    Color? hero,
    Color? onHero,
    Color? onHeroMuted,
    Color? heroPositive,
    Color? heroNegative,
    Color? accent,
    Color? onAccent,
  }) => AppSemanticColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    mint: mint ?? this.mint,
    border: border ?? this.border,
    textSecondary: textSecondary ?? this.textSecondary,
    hero: hero ?? this.hero,
    onHero: onHero ?? this.onHero,
    onHeroMuted: onHeroMuted ?? this.onHeroMuted,
    heroPositive: heroPositive ?? this.heroPositive,
    heroNegative: heroNegative ?? this.heroNegative,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
  );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppSemanticColors(
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      warningContainer: mix(warningContainer, other.warningContainer),
      mint: mix(mint, other.mint),
      border: mix(border, other.border),
      textSecondary: mix(textSecondary, other.textSecondary),
      hero: mix(hero, other.hero),
      onHero: mix(onHero, other.onHero),
      onHeroMuted: mix(onHeroMuted, other.onHeroMuted),
      heroPositive: mix(heroPositive, other.heroPositive),
      heroNegative: mix(heroNegative, other.heroNegative),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
