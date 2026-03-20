import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/schoolify_theme_extension.dart';

/// Tonal card — no elevation; optional ghost border for outdoor / glare contexts.
class SchoolifyCard extends StatelessWidget {
  const SchoolifyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.showGhostBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showGhostBorder;

  @override
  Widget build(BuildContext context) {
    final sx = SchoolifyColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: sx.surfaceTierLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: showGhostBorder
            ? Border.all(color: sx.ghostBorder, width: 1)
            : null,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
