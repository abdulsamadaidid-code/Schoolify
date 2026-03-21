import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/schoolify_theme_extension.dart';

enum SchoolifyButtonVariant { primary, secondary, tertiary, danger }

/// Large, thumb-friendly actions — primary uses branded gradient (Stitch).
class SchoolifyButton extends StatelessWidget {
  const SchoolifyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SchoolifyButtonVariant.primary,
    this.minHeight = 56,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final SchoolifyButtonVariant variant;
  final double minHeight;
  final Widget? leading;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sx = SchoolifyColors.of(context);

    switch (variant) {
      case SchoolifyButtonVariant.primary:
        return _GradientButton(
          minHeight: minHeight,
          enabled: _enabled,
          onPressed: onPressed,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              sx.primaryGradientTop,
              sx.primaryGradientBottom,
            ],
          ),
          child: _labelRow(Colors.white),
        );
      case SchoolifyButtonVariant.secondary:
        return FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: Size(0, minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
          ),
          onPressed: onPressed,
          child: _labelRow(scheme.onSecondaryContainer),
        );
      case SchoolifyButtonVariant.tertiary:
        return TextButton(
          style: TextButton.styleFrom(
            minimumSize: Size(0, minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            foregroundColor: scheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
          ),
          onPressed: onPressed,
          child: _labelRow(scheme.primary),
        );
      case SchoolifyButtonVariant.danger:
        return FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: Size(0, minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
          ),
          onPressed: onPressed,
          child: _labelRow(scheme.onError),
        );
    }
  }

  Widget _labelRow(Color color) {
    final style = TextStyle(color: color, fontWeight: FontWeight.w600);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          IconTheme.merge(
            data: IconThemeData(color: color, size: 20),
            child: leading!,
          ),
          const SizedBox(width: 8),
        ],
        Text(label, style: style),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.minHeight,
    required this.enabled,
    required this.onPressed,
    required this.gradient,
    required this.child,
  });

  final double minHeight;
  final bool enabled;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadii.button);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: borderRadius,
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: borderRadius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
