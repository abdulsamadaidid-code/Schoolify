import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Centers content and caps width on tablet/desktop per [AppBreakpoints].
class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppBreakpoints.contentMaxWidth(context),
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
