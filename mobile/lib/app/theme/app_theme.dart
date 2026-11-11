import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Material 3 light and dark "Rider Green" themes built from the tokens.
///
/// Contrast note (§2.3 asks to check text on green): white text on Primary
/// Action `#00A884` is only ≈3.0:1, below the 4.5:1 needed for 16 sp button
/// labels. Filled buttons therefore use Brand `#00796B` (≈5.4:1) in light mode
/// and Brand-dark `#55C7A5` with dark text (≈8.5:1) in dark mode; Primary Action
/// stays for non-text accents (progress indicators, the hero card accent).
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ColorScheme _scheme(Brightness brightness) =>
      brightness == Brightness.light
      ? const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.brand,
          onPrimary: Colors.white,
          primaryContainer: AppColors.mint,
          onPrimaryContainer: AppColors.forest,
          secondary: AppColors.brand,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.mint,
          onSecondaryContainer: AppColors.forest,
          tertiary: AppColors.forest,
          onTertiary: Colors.white,
          tertiaryContainer: AppColors.mint,
          onTertiaryContainer: AppColors.forest,
          error: AppColors.error,
          onError: Colors.white,
          errorContainer: AppColors.errorSurface,
          onErrorContainer: AppColors.error,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          surfaceDim: AppColors.background,
          surfaceBright: AppColors.surface,
          surfaceContainerLowest: AppColors.surface,
          surfaceContainerLow: AppColors.surface,
          surfaceContainer: AppColors.surface,
          surfaceContainerHigh: AppColors.surface,
          surfaceContainerHighest: AppColors.border,
          outline: AppColors.borderStrong,
          outlineVariant: AppColors.border,
          inverseSurface: AppColors.forest,
          onInverseSurface: Colors.white,
          inversePrimary: AppColors.darkBrand,
          shadow: AppColors.forest,
          scrim: Colors.black,
          surfaceTint: Colors.transparent,
        )
      : const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.darkBrand,
          onPrimary: AppColors.darkBackground,
          primaryContainer: AppColors.darkMint,
          onPrimaryContainer: AppColors.darkTextPrimary,
          secondary: AppColors.darkBrand,
          onSecondary: AppColors.darkBackground,
          secondaryContainer: AppColors.darkMint,
          onSecondaryContainer: AppColors.darkTextPrimary,
          tertiary: AppColors.darkBrand,
          onTertiary: AppColors.darkBackground,
          tertiaryContainer: AppColors.darkMint,
          onTertiaryContainer: AppColors.darkTextPrimary,
          error: AppColors.darkError,
          onError: AppColors.darkBackground,
          errorContainer: AppColors.darkErrorSurface,
          onErrorContainer: AppColors.darkError,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          surfaceDim: AppColors.darkBackground,
          surfaceBright: AppColors.darkSurfaceElevated,
          surfaceContainerLowest: AppColors.darkBackground,
          surfaceContainerLow: AppColors.darkSurface,
          surfaceContainer: AppColors.darkSurface,
          surfaceContainerHigh: AppColors.darkSurfaceElevated,
          surfaceContainerHighest: AppColors.darkBorder,
          outline: AppColors.darkBorderStrong,
          outlineVariant: AppColors.darkBorder,
          inverseSurface: AppColors.darkTextPrimary,
          onInverseSurface: AppColors.darkBackground,
          inversePrimary: AppColors.brand,
          shadow: Colors.black,
          scrim: Colors.black,
          surfaceTint: Colors.transparent,
        );

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = _scheme(brightness);
    final semantic = isLight ? AppSemanticColors.light : AppSemanticColors.dark;
    final text = AppTypography.textTheme(
      scheme.onSurface,
      scheme.onSurfaceVariant,
    );
    final background = isLight
        ? AppColors.background
        : AppColors.darkBackground;

    // Light: Rider Green app bar with white content. Dark: surface app bar.
    final appBarBackground = isLight ? AppColors.brand : AppColors.darkSurface;
    final appBarForeground = isLight ? Colors.white : scheme.onSurface;

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

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: semantic.border,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [semantic],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge?.copyWith(color: appBarForeground),
        iconTheme: IconThemeData(color: appBarForeground),
        actionsIconTheme: IconThemeData(color: appBarForeground),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.light.copyWith(
                systemNavigationBarColor: AppColors.darkSurface,
              ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: appBarForeground,
        unselectedLabelColor: isLight
            ? Colors.white.withValues(alpha: 0.78)
            : scheme.onSurfaceVariant,
        indicatorColor: isLight ? Colors.white : scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: semantic.mint,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + AppSpacing.xxs,
        ),
        border: inputBorder(scheme.outline),
        enabledBorder: inputBorder(scheme.outline),
        disabledBorder: inputBorder(semantic.border),
        focusedBorder: inputBorder(scheme.primary, 2),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 2),
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: rounded(AppRadius.button),
          textStyle: buttonText,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: semantic.border,
          disabledForegroundColor: scheme.onSurfaceVariant,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: rounded(AppRadius.button),
          textStyle: buttonText,
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
          shape: rounded(AppRadius.button),
          foregroundColor: scheme.primary,
          textStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        shape: rounded(AppRadius.lg),
        extendedTextStyle: buttonText,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSizes.minTouch, AppSizes.minTouch),
          ),
          textStyle: WidgetStatePropertyAll(text.labelMedium),
          side: WidgetStatePropertyAll(BorderSide(color: semantic.border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? semantic.mint
                : scheme.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isLight ? 1 : 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.08),
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: rounded(AppRadius.lg, BorderSide(color: semantic.border)),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        minVerticalPadding: AppSpacing.md,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        titleTextStyle: AppTypography.figures(
          text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: semantic.border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: rounded(AppRadius.xl),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: rounded(AppRadius.xl),
        headerBackgroundColor: isLight ? AppColors.brand : AppColors.darkMint,
        headerForegroundColor: isLight ? Colors.white : scheme.onSurface,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: rounded(AppRadius.xl),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isLight ? AppColors.primaryAction : AppColors.darkBrand,
        linearTrackColor: semantic.mint,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: rounded(AppRadius.md),
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    );
  }
}
