import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// External label + 56px-tall field ([docs/branding.md]). Not placeholder-only.
class SchoolifyTextField extends StatelessWidget {
  const SchoolifyTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.errorText,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      fontSize: AppTypography.labelMd,
      letterSpacing: 0.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          autofocus: autofocus,
          focusNode: focusNode,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
