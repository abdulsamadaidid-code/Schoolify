import 'package:flutter/material.dart';

/// Raw palette from [docs/branding.md]. Do not use directly in widgets —
/// prefer [Theme.of] / [ColorScheme] / [SchoolifyColors].
abstract final class AppColors {
  // Light
  static const Color primary = Color(0xFF003EA8);
  static const Color primaryContainer = Color(0xFF0053DB);
  static const Color secondaryContainer = Color(0xFFDAE2FD);
  static const Color onSecondaryContainer = Color(0xFF5C647A);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF434655);
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceContainerLow = Color(0xFFF3F3F4);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFFFB786);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color outlineVariant = Color(0xFFC3C6D7);

  // Dark (branding names)
  static const Color darkSurface = Color(0xFF0B1326);
  static const Color darkSurfaceContainerLow = Color(0xFF131B2E);
  static const Color darkSurfaceContainer = Color(0xFF171F33);
  static const Color darkSurfaceContainerHighest = Color(0xFF2D3449);
  static const Color darkOnSurface = Color(0xFFDAE2FD);
  static const Color darkOnSurfaceVariant = Color(0xFFC2C6D6);
  static const Color darkOutlineVariant = Color(0xFF424754);
  static const Color darkPrimary = Color(0xFFA4C9FF);
}
