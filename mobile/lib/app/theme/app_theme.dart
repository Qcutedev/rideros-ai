import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Surface tones of the "Lime Obsidian" design. Cards alternate between them
/// instead of all being white; each tone has its own text and accent colours
/// (see [AppTheme.toned]), so content inside stays readable.
enum AppTone {
  /// White card (light) / raised Obsidian (dark).
  paper,

  /// Mist Gray secondary surface.
  mist,

  /// Sage Mint feature card.
  sage,

  /// Muted Teal feature card.
  teal,

  /// Electric Lime highlight card.
  lime,

  /// Obsidian high-contrast card.
  obsidian,
}

/// Material 3 light and dark themes built from the tokens, plus one derived
/// theme per [AppTone].
///
/// Contrast notes: lime on Ivory is ≈ 1.05:1, so in light mode filled buttons
/// are Obsidian with a lime label (≈ 15:1) and lime appears as fills with
/// Obsidian content. Dark mode is designed separately: near-black background,
/// raised Obsidian surfaces, lime as the primary action colour.
abstract final class AppTheme {
  static final ThemeData light = _build(_Palette.light);

  static final ThemeData dark = _build(_Palette.dark);

  static final _toned = <(Brightness, AppTone), ThemeData>{};

  /// Theme for content on a [tone] surface, given the app [brightness]. Built
  /// once per pair and cached.
  static ThemeData toned(Brightness brightness, AppTone tone) {
    if (tone == AppTone.paper) {
      return brightness == Brightness.light ? light : dark;
    }
    return _toned[(brightness, tone)] ??= _build(
      _Palette.tone(brightness, tone),
    );
  }

  /// Background colour of a [tone] surface.
  static Color toneColor(Brightness brightness, AppTone tone) =>
      toned(brightness, tone).colorScheme.surface;

  static ThemeData _build(_Palette p) {
    final isLight = p.brightness == Brightness.light;
    final scheme = p.scheme;
    final semantic = p.semantic;
    final text = AppTypography.textTheme(p.onSurface, p.muted);

    RoundedRectangleBorder rounded(double radius, [BorderSide? side]) =>
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: side ?? BorderSide.none,
        );
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );
    const buttonSize = Size(double.infinity, AppSizes.buttonHeight);
    final buttonText = text.labelLarge;
    final overlay = isLight
        ? SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: p.background,
            systemNavigationBarIconBrightness: Brightness.dark,
          )
        : SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: p.background,
            systemNavigationBarIconBrightness: Brightness.light,
          );

    // Bottom navigation is always an Obsidian bar with a lime pill.
    const navMuted = Color(0xFF9AA49D);
    final navBackground = isLight
        ? AppColors.obsidian
        : AppColors.darkSurfaceElevated;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: p.brightness,
      fontFamily: AppTypography.fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      dividerColor: p.border,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkRipple.splashFactory,
      extensions: [semantic],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: RiderPageTransitionsBuilder(),
          TargetPlatform.fuchsia: RiderPageTransitionsBuilder(),
          TargetPlatform.linux: RiderPageTransitionsBuilder(),
          TargetPlatform.windows: RiderPageTransitionsBuilder(),
          // Keeps the native swipe-back gesture.
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: p.background,
        foregroundColor: p.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: isLight ? 1 : 0,
        shadowColor: AppColors.obsidian.withValues(alpha: 0.12),
        titleSpacing: AppSpacing.lg + AppSpacing.xxs,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: p.onSurface),
        actionsIconTheme: IconThemeData(color: p.onSurface),
        systemOverlayStyle: overlay,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onPrimary,
        unselectedLabelColor: p.muted,
        indicator: ShapeDecoration(
          shape: const StadiumBorder(),
          color: scheme.primary,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorAnimation: TabIndicatorAnimation.elastic,
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(AppRadius.pill),
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.lime,
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.obsidian
                : navMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            letterSpacing: 0,
            color: states.contains(WidgetState.selected)
                ? AppColors.ivory
                : navMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.field,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + AppSpacing.xxs,
        ),
        border: inputBorder(p.borderStrong),
        enabledBorder: inputBorder(p.borderStrong),
        disabledBorder: inputBorder(p.border),
        focusedBorder: inputBorder(p.focus, 2),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 2),
        hintStyle: text.bodyLarge?.copyWith(color: p.muted),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: p.muted,
        suffixIconColor: p.muted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: const StadiumBorder(),
          textStyle: buttonText,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: p.border,
          disabledForegroundColor: p.muted,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: const StadiumBorder(),
          textStyle: buttonText,
          foregroundColor: p.onSurface,
          side: BorderSide(
            color: p.onSurface.withValues(alpha: 0.7),
            width: 1.4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
          shape: const StadiumBorder(),
          foregroundColor: p.link,
          textStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.onSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.obsidian,
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 4,
        highlightElevation: 1,
        shape: rounded(AppRadius.xl - AppSpacing.xs),
        extendedTextStyle: buttonText,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSizes.minTouch, AppSizes.minTouch),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: WidgetStatePropertyAll(text.labelMedium),
          side: WidgetStatePropertyAll(BorderSide(color: p.borderStrong)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : p.field,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : p.onSurface,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : p.muted,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: p.borderStrong.withValues(alpha: 0.6)),
        backgroundColor: p.field,
        selectedColor: AppColors.lime,
        checkmarkColor: AppColors.obsidian,
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(
          color: AppColors.obsidian,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      cardTheme: CardThemeData(
        elevation: isLight ? 1.5 : 0,
        shadowColor: AppColors.obsidian.withValues(alpha: 0.16),
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: rounded(
          AppRadius.lg,
          isLight ? BorderSide.none : BorderSide(color: p.border),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.onSurface,
        minVerticalPadding: AppSpacing.md,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        titleTextStyle: AppTypography.figures(
          text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitleTextStyle: text.bodyMedium?.copyWith(color: p.muted),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: p.onSurface,
        collapsedIconColor: p.muted,
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: rounded(AppRadius.xl),
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        contentTextStyle: text.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        dragHandleSize: const Size(40, 4),
        modalBarrierColor: AppColors.obsidian.withValues(alpha: 0.45),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: rounded(AppRadius.xl),
        headerBackgroundColor: isLight
            ? AppColors.obsidian
            : AppColors.darkSurfaceHighest,
        headerForegroundColor: isLight ? AppColors.ivory : p.onSurface,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.surfaceHigh,
        shape: rounded(AppRadius.xl),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.focus,
        linearTrackColor: semantic.mint,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 6,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : p.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.primary : p.field,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: rounded(6),
        side: BorderSide(color: p.borderStrong, width: 1.6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight
            ? AppColors.obsidian
            : AppColors.darkSurfaceHighest,
        actionTextColor: AppColors.lime,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: isLight ? AppColors.ivory : AppColors.darkTextPrimary,
        ),
        elevation: 4,
        shape: rounded(AppRadius.md),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isLight ? AppColors.obsidian : AppColors.darkSurfaceHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: text.bodySmall?.copyWith(
          color: isLight ? AppColors.ivory : AppColors.darkTextPrimary,
        ),
      ),
      iconTheme: IconThemeData(color: p.muted),
    );
  }
}

/// Push/pop transition for Android and desktop: the new page fades in while
/// rising slightly; the page underneath recedes a little.
class RiderPageTransitionsBuilder extends PageTransitionsBuilder {
  const RiderPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 320);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: AppCurves.enter,
      reverseCurve: Curves.easeInCubic,
    );
    final recede = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppCurves.standard,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(recede),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.97).animate(recede),
        child: FadeTransition(
          opacity: enter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(enter),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Colours one theme is built from: the app's light and dark themes and one
/// per surface tone.
@immutable
class _Palette {
  const _Palette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.field,
    required this.onSurface,
    required this.muted,
    required this.border,
    required this.borderStrong,
    required this.primary,
    required this.onPrimary,
    required this.focus,
    required this.link,
    required this.error,
    required this.semantic,
  });

  /// Palette of a coloured card. Pastel and lime tones carry Obsidian content;
  /// the Obsidian tone (and dark mode's sage/teal/mist) carry light content.
  /// Muted text, money and error colours are picked for ≥ 4.5:1 on each tone.
  factory _Palette.tone(Brightness brightness, AppTone tone) {
    final isLight = brightness == Brightness.light;
    return switch ((tone, isLight)) {
      (AppTone.lime, _) => _Palette._onPastel(
        brightness,
        AppColors.lime,
        const Color(0xFF3A4A1F),
      ),
      (AppTone.sage, true) => _Palette._onPastel(
        brightness,
        AppColors.sage,
        const Color(0xFF23332B),
      ),
      (AppTone.teal, true) => _Palette._onPastel(
        brightness,
        AppColors.teal,
        const Color(0xFF1C2B25),
      ),
      (AppTone.mist, true) => _Palette._onPastel(
        brightness,
        AppColors.mist,
        const Color(0xFF3E4A43),
      ),
      (AppTone.obsidian, true) => _Palette._onDark(
        brightness,
        AppColors.obsidian,
        AppColors.lime,
      ),
      (AppTone.sage, false) => _Palette._onDark(
        brightness,
        const Color(0xFF1D2D26),
        AppColors.sage,
      ),
      (AppTone.teal, false) => _Palette._onDark(
        brightness,
        const Color(0xFF172B26),
        AppColors.teal,
      ),
      (AppTone.mist, false) => _Palette._onDark(
        brightness,
        AppColors.darkSurfaceElevated,
        AppColors.lime,
      ),
      (AppTone.obsidian, false) => _Palette._onDark(
        brightness,
        AppColors.darkSurfaceElevated,
        AppColors.lime,
      ),
      (AppTone.paper, true) => light,
      (AppTone.paper, false) => dark,
    };
  }

  factory _Palette._onPastel(Brightness brightness, Color tone, Color muted) {
    const ink = AppColors.obsidian;
    final soft = Color.alphaBlend(Colors.white.withValues(alpha: 0.42), tone);
    final line = Color.alphaBlend(ink.withValues(alpha: 0.12), tone);
    return _Palette(
      brightness: Brightness.light,
      background: tone,
      surface: tone,
      surfaceHigh: soft,
      field: soft,
      onSurface: ink,
      muted: muted,
      border: line,
      borderStrong: muted,
      primary: ink,
      onPrimary: AppColors.lime,
      focus: ink,
      link: ink,
      error: const Color(0xFF7A1410),
      semantic: AppSemanticColors.light.copyWith(
        success: const Color(0xFF183D06),
        mint: soft,
        border: line,
        textSecondary: muted,
        accent: tone == AppColors.lime ? ink : AppColors.lime,
        onAccent: tone == AppColors.lime ? AppColors.lime : ink,
      ),
    );
  }

  factory _Palette._onDark(Brightness brightness, Color tone, Color accent) {
    const ink = AppColors.darkTextPrimary;
    const muted = Color(0xFFB2BCB4);
    final soft = Color.alphaBlend(Colors.white.withValues(alpha: 0.07), tone);
    final line = Color.alphaBlend(Colors.white.withValues(alpha: 0.12), tone);
    return _Palette(
      brightness: Brightness.dark,
      background: tone,
      surface: tone,
      surfaceHigh: soft,
      field: soft,
      onSurface: ink,
      muted: muted,
      border: line,
      borderStrong: AppColors.darkBorderStrong,
      primary: accent,
      onPrimary: AppColors.obsidian,
      focus: accent,
      link: accent,
      error: AppColors.darkError,
      semantic: AppSemanticColors.dark.copyWith(
        success: AppColors.lime,
        mint: soft,
        border: line,
        textSecondary: muted,
        hero: soft,
      ),
    );
  }

  static const light = _Palette(
    brightness: Brightness.light,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceHigh: AppColors.surface,
    field: AppColors.surface,
    onSurface: AppColors.textPrimary,
    muted: AppColors.textSecondary,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    primary: AppColors.obsidian,
    onPrimary: AppColors.lime,
    focus: AppColors.obsidian,
    link: AppColors.tealInk,
    error: AppColors.error,
    semantic: AppSemanticColors.light,
  );

  static const dark = _Palette(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceHigh: AppColors.darkSurfaceElevated,
    field: AppColors.darkSurfaceElevated,
    onSurface: AppColors.darkTextPrimary,
    muted: AppColors.darkTextSecondary,
    border: AppColors.darkBorder,
    borderStrong: AppColors.darkBorderStrong,
    primary: AppColors.lime,
    onPrimary: AppColors.obsidian,
    focus: AppColors.lime,
    link: AppColors.lime,
    error: AppColors.darkError,
    semantic: AppSemanticColors.dark,
  );

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color field;
  final Color onSurface;
  final Color muted;
  final Color border;
  final Color borderStrong;
  final Color primary;
  final Color onPrimary;
  final Color focus;
  final Color link;
  final Color error;
  final AppSemanticColors semantic;

  ColorScheme get scheme {
    final isLight = brightness == Brightness.light;
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: semantic.accent,
      onPrimaryContainer: semantic.onAccent,
      secondary: isLight ? AppColors.tealInk : AppColors.sage,
      onSecondary: isLight ? Colors.white : AppColors.obsidian,
      secondaryContainer: semantic.mint,
      onSecondaryContainer: onSurface,
      tertiary: isLight ? AppColors.tealInk : AppColors.teal,
      onTertiary: isLight ? Colors.white : AppColors.obsidian,
      tertiaryContainer: semantic.mint,
      onTertiaryContainer: onSurface,
      error: error,
      onError: isLight ? Colors.white : AppColors.obsidian,
      errorContainer: isLight
          ? AppColors.errorSurface
          : AppColors.darkErrorSurface,
      onErrorContainer: isLight ? AppColors.error : AppColors.darkError,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: muted,
      surfaceDim: background,
      surfaceBright: surfaceHigh,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: semantic.mint,
      outline: borderStrong,
      outlineVariant: border,
      inverseSurface: isLight ? AppColors.obsidian : AppColors.ivory,
      onInverseSurface: isLight ? AppColors.ivory : AppColors.obsidian,
      inversePrimary: isLight ? AppColors.lime : AppColors.obsidian,
      shadow: AppColors.obsidian,
      scrim: Colors.black,
      surfaceTint: Colors.transparent,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => identityHashCode(this);

  @override
  String toString() => describeIdentity(this);
}
