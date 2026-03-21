import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic colors and tonal surfaces not fully covered by [ColorScheme].
@immutable
class SchoolifyColors extends ThemeExtension<SchoolifyColors> {
  const SchoolifyColors({
    required this.accent,
    required this.success,
    required this.warning,
    required this.surfaceTierLow,
    required this.surfaceTierLowest,
    required this.ghostBorder,
    required this.primaryGradientTop,
    required this.primaryGradientBottom,
  });

  final Color accent;
  final Color success;
  final Color warning;

  /// Section / sidebar tier (light: surfaceContainerLow; dark: secondary layout).
  final Color surfaceTierLow;

  /// Cards / elevated panels.
  final Color surfaceTierLowest;

  /// Ghost border at ~20% of outline variant (see Stitch DESIGN ambient note).
  final Color ghostBorder;

  final Color primaryGradientTop;
  final Color primaryGradientBottom;

  static SchoolifyColors of(BuildContext context) {
    final ext = Theme.of(context).extension<SchoolifyColors>();
    assert(ext != null, 'SchoolifyColors missing on ThemeData.extensions');
    return ext!;
  }

  @override
  SchoolifyColors copyWith({
    Color? accent,
    Color? success,
    Color? warning,
    Color? surfaceTierLow,
    Color? surfaceTierLowest,
    Color? ghostBorder,
    Color? primaryGradientTop,
    Color? primaryGradientBottom,
  }) {
    return SchoolifyColors(
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      surfaceTierLow: surfaceTierLow ?? this.surfaceTierLow,
      surfaceTierLowest: surfaceTierLowest ?? this.surfaceTierLowest,
      ghostBorder: ghostBorder ?? this.ghostBorder,
      primaryGradientTop: primaryGradientTop ?? this.primaryGradientTop,
      primaryGradientBottom: primaryGradientBottom ?? this.primaryGradientBottom,
    );
  }

  @override
  ThemeExtension<SchoolifyColors> lerp(
    ThemeExtension<SchoolifyColors>? other,
    double t,
  ) {
    if (other is! SchoolifyColors) return this;
    return SchoolifyColors(
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      surfaceTierLow: Color.lerp(surfaceTierLow, other.surfaceTierLow, t)!,
      surfaceTierLowest:
          Color.lerp(surfaceTierLowest, other.surfaceTierLowest, t)!,
      ghostBorder: Color.lerp(ghostBorder, other.ghostBorder, t)!,
      primaryGradientTop:
          Color.lerp(primaryGradientTop, other.primaryGradientTop, t)!,
      primaryGradientBottom:
          Color.lerp(primaryGradientBottom, other.primaryGradientBottom, t)!,
    );
  }

  static const SchoolifyColors light = SchoolifyColors(
    accent: AppColors.accent,
    success: AppColors.success,
    warning: AppColors.warning,
    surfaceTierLow: AppColors.surfaceContainerLow,
    surfaceTierLowest: AppColors.surfaceContainerLowest,
    ghostBorder: Color(0x33C3C6D7),
    primaryGradientTop: AppColors.primaryContainer,
    primaryGradientBottom: AppColors.primary,
  );

  static const SchoolifyColors dark = SchoolifyColors(
    accent: AppColors.accent,
    success: AppColors.success,
    warning: AppColors.warning,
    surfaceTierLow: AppColors.darkSurfaceContainerLow,
    surfaceTierLowest: AppColors.darkSurfaceContainer,
    ghostBorder: Color(0x33424754),
    primaryGradientTop: AppColors.primaryContainer,
    primaryGradientBottom: AppColors.primary,
  );
}
