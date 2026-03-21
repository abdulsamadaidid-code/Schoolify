import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography per [docs/branding.md] — Manrope (display/headings/numbers),
/// Inter (body / labels).
abstract final class AppTypography {
  static const double displayLg = 56;
  static const double headlineMd = 28;
  static const double titleLg = 22;
  static const double bodyLg = 16;
  static const double labelMd = 12;

  static TextTheme textThemeLight(ColorScheme scheme) {
    return TextTheme(
      displayLarge: GoogleFonts.manrope(
        fontSize: displayLg,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: scheme.onSurface,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: headlineMd,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: scheme.onSurface,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: titleLg,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: scheme.onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: bodyLg,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: scheme.onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: labelMd,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.6,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  static TextTheme textThemeDark(ColorScheme scheme) {
    return TextTheme(
      displayLarge: GoogleFonts.manrope(
        fontSize: displayLg,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: scheme.onSurface,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: headlineMd,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: scheme.onSurface,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: titleLg,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: scheme.onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: bodyLg,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: scheme.onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: labelMd,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.6,
        color: AppColors.darkOnSurfaceVariant,
      ),
    );
  }
}
