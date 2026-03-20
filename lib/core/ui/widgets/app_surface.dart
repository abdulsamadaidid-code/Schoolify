import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Background tiers — prefer tonal shifts over divider lines ([docs/branding.md]).
enum AppSurfaceTier {
  /// App scaffold / base.
  base,

  /// Sections, rails, sidebars.
  low,

  /// Cards / panels (usually wrapped in [SchoolifyCard] instead).
  lowest,
}

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.tier,
    required this.child,
  });

  final AppSurfaceTier tier;
  final Widget child;

  Color _background(Brightness brightness) {
    switch (tier) {
      case AppSurfaceTier.base:
        return brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface;
      case AppSurfaceTier.low:
        return brightness == Brightness.dark
            ? AppColors.darkSurfaceContainerLow
            : AppColors.surfaceContainerLow;
      case AppSurfaceTier.lowest:
        return brightness == Brightness.dark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLowest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _background(Theme.of(context).brightness);
    return ColoredBox(
      color: bg,
      child: child,
    );
  }
}
