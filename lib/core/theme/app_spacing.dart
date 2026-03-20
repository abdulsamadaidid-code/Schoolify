/// Spacing scale aligned with [docs/branding.md] (16px standard padding).
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Editorial lockup: Headline-MD → Body-LG (~1.4rem).
  static const double headlineBodyGap = 22.4;

  /// Bottom padding to clear mobile nav / thumb zone (Stitch: ~8.5rem).
  static const double pageBottomInset = 136;
}
