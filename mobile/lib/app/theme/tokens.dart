import 'package:flutter/material.dart';

/// Design tokens ("Rider Green", `docs/RIDEROS_UI_DESIGN.md` §2). Widgets use
/// these (or the `ThemeData` built from them), never raw numbers or colours.
abstract final class AppColors {
  // Light mode (§2.2).
  static const brand = Color(0xFF00796B);
  static const primaryAction = Color(0xFF00A884);
  static const forest = Color(0xFF123B32);
  static const mint = Color(0xFFDDF5EB);
  static const background = Color(0xFFF5FAF7);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF17231F);
  static const textSecondary = Color(0xFF63736B);
  static const border = Color(0xFFDCE8E1);
  static const success = Color(0xFF1B7F3B);
  static const warning = Color(0xFF8A5A00);
  static const warningSurface = Color(0xFFFFF1D6);
  static const error = Color(0xFFC62828);
  static const errorSurface = Color(0xFFFDE8E7);

  /// Input outlines. [border] is too faint (≈1.2:1) for a control boundary, so
  /// inputs use this darker shade of it (≥3:1 against the surface, WCAG 1.4.11).
  static const borderStrong = Color(0xFF84968D);

  // Dark mode (§2.3).
  static const darkBackground = Color(0xFF0D1915);
  static const darkSurface = Color(0xFF172820);
  static const darkSurfaceElevated = Color(0xFF20372D);
  static const darkBrand = Color(0xFF55C7A5);
  static const darkPrimaryAction = Color(0xFF00A884);
  static const darkMint = Color(0xFF1E4034);
  static const darkTextPrimary = Color(0xFFF1F7F3);
  static const darkTextSecondary = Color(0xFFA9BDB2);
  static const darkBorder = Color(0xFF30483C);
  static const darkSuccess = Color(0xFF7FD69A);
  static const darkWarning = Color(0xFFFFC266);
  static const darkWarningSurface = Color(0xFF4A3200);
  static const darkError = Color(0xFFFF7770);
  static const darkErrorSurface = Color(0xFF482321);

  /// Dark-mode counterpart of [borderStrong] (≥3:1 against [darkSurface]).
  static const darkBorderStrong = Color(0xFF5E7A6C);

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
  static const screen = EdgeInsets.symmetric(horizontal: lg, vertical: xl);

  /// Padding inside a card.
  static const cardPadding = EdgeInsets.all(card);
}

abstract final class AppRadius {
  static const sm = 8.0;

  /// Inputs and tiles.
  static const md = 12.0;

  /// Buttons.
  static const button = 14.0;

  /// Cards.
  static const lg = 16.0;

  /// Dialogs, bottom sheets and the hero card.
  static const xl = 20.0;

  static const pill = 999.0;
}

abstract final class AppSizes {
  /// Primary button height.
  static const buttonHeight = 52.0;

  /// Minimum touch target.
  static const minTouch = 48.0;
  static const iconLg = 48.0;
  static const iconXl = 72.0;

  /// Forms and status views stay readable on tablets.
  static const maxContentWidth = 480.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);

  /// Brand intro at app start: logo reveal and hold, then the hand-over fade (≈3 s).
  static const introReveal = Duration(milliseconds: 2600);
  static const introExit = Duration(milliseconds: 400);
}

/// Type scale (§2.4): IBM Plex Sans Thai, bundled under `assets/fonts/` (OFL).
abstract final class AppTypography {
  static const fontFamily = 'IBMPlexSansThai';

  /// Display 32 · H1 24 · H2 20 · H3 18 · Body 16 · Body small 14 · Caption 12.
  static TextTheme textTheme(Color primary, Color secondary) {
    TextStyle style(double size, FontWeight weight, double height, Color c) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: c,
          letterSpacing: 0,
        );
    final display = style(32, FontWeight.w700, 1.2, primary);
    final h1 = style(24, FontWeight.w700, 1.3, primary);
    return TextTheme(
      displayLarge: display,
      displayMedium: display,
      displaySmall: display,
      headlineLarge: h1,
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
      labelSmall: style(12, FontWeight.w500, 1.3, secondary),
    );
  }

  /// Money and other figures: equal-width digits so columns line up.
  static TextStyle? figures(TextStyle? style) =>
      style?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

/// Semantic colours Material 3 does not provide: positive money, warnings and
/// estimates, the dark hero card and the secondary text/border tokens.
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
  });

  static const light = AppSemanticColors(
    success: AppColors.success,
    warning: AppColors.warning,
    warningContainer: AppColors.warningSurface,
    mint: AppColors.mint,
    border: AppColors.border,
    textSecondary: AppColors.textSecondary,
    hero: AppColors.forest,
    onHero: Colors.white,
    onHeroMuted: Color(0xFFB9D3C8),
    heroPositive: AppColors.darkSuccess,
    heroNegative: AppColors.darkError,
  );

  static const dark = AppSemanticColors(
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    warningContainer: AppColors.darkWarningSurface,
    mint: AppColors.darkMint,
    border: AppColors.darkBorder,
    textSecondary: AppColors.darkTextSecondary,
    hero: AppColors.darkMint,
    onHero: AppColors.darkTextPrimary,
    onHeroMuted: AppColors.darkTextSecondary,
    heroPositive: AppColors.darkSuccess,
    heroNegative: AppColors.darkError,
  );

  /// Positive money, success.
  final Color success;
  final Color warning;
  final Color warningContainer;

  /// Secondary cards and selected states.
  final Color mint;
  final Color border;
  final Color textSecondary;

  /// Background of the headline card (Forest Green in light mode).
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;

  /// Profit colours that keep ≥4.5:1 contrast on [hero].
  final Color heroPositive;
  final Color heroNegative;

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
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
