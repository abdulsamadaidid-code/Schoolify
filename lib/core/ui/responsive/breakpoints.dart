import 'package:flutter/material.dart';

/// Layout buckets for web + mobile. Use for switching columns, rail vs bar, etc.
abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 900;
  static const double expanded = 1200;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) =>
      widthOf(context) < compact;

  static bool isMedium(BuildContext context) {
    final w = widthOf(context);
    return w >= compact && w < expanded;
  }

  static bool isExpanded(BuildContext context) =>
      widthOf(context) >= expanded;

  /// Max content width on large canvases (editorial spacing, readable line length).
  static double contentMaxWidth(BuildContext context) {
    final w = widthOf(context);
    if (w >= expanded) return 1200;
    if (w >= medium) return 960;
    return w;
  }
}
