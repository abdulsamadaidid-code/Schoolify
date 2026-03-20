import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'schoolify_theme_extension.dart';

/// Builds light/dark [ThemeData] strictly from [docs/branding.md].
abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.secondaryContainer,
      onSecondary: AppColors.onSecondaryContainer,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.accent,
      onTertiary: AppColors.onSurface,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outlineVariant,
      outlineVariant: AppColors.outlineVariant,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainerLow,
      surfaceContainerHigh: AppColors.surfaceContainerLow,
      surfaceContainerHighest: AppColors.surfaceContainerLowest,
    );

    final textTheme = AppTypography.textThemeLight(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: const [SchoolifyColors.light],
      splashFactory: InkSplash.splashFactory,
      cardTheme: CardThemeData(
        color: SchoolifyColors.light.surfaceTierLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        shadowColor: const Color(0x140F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: SchoolifyColors.light.surfaceTierLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: const BoxConstraints(minHeight: 56),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle: textTheme.labelMedium,
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surface,
        indicatorColor: AppColors.primaryContainer.withOpacity(0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelMedium?.copyWith(
            fontSize: 11,
            letterSpacing: 0.6,
          );
          if (states.contains(WidgetState.selected)) {
            return base?.copyWith(color: AppColors.primary);
          }
          return base?.copyWith(color: AppColors.onSurfaceVariant);
        }),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkSurface,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.darkSurfaceContainer,
      onSecondary: AppColors.darkOnSurface,
      secondaryContainer: AppColors.darkSurfaceContainerLow,
      onSecondaryContainer: AppColors.darkOnSurface,
      tertiary: AppColors.accent,
      onTertiary: AppColors.darkSurface,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline: AppColors.darkOutlineVariant,
      outlineVariant: AppColors.darkOutlineVariant,
      surfaceContainerLowest: AppColors.darkSurfaceContainer,
      surfaceContainerLow: AppColors.darkSurfaceContainerLow,
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: AppColors.darkSurfaceContainerHighest,
      surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
    );

    final textTheme = AppTypography.textThemeDark(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: const [SchoolifyColors.dark],
      splashFactory: InkSplash.splashFactory,
      cardTheme: CardThemeData(
        color: SchoolifyColors.dark.surfaceTierLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        shadowColor: const Color(0x140F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: SchoolifyColors.dark.surfaceTierLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: const BoxConstraints(minHeight: 56),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle: textTheme.labelMedium,
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.darkOnSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surface,
        indicatorColor: AppColors.primary.withOpacity(0.35),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelMedium?.copyWith(
            fontSize: 11,
            letterSpacing: 0.6,
          );
          if (states.contains(WidgetState.selected)) {
            return base?.copyWith(color: AppColors.darkPrimary);
          }
          return base?.copyWith(color: AppColors.darkOnSurfaceVariant);
        }),
      ),
    );
  }
}
