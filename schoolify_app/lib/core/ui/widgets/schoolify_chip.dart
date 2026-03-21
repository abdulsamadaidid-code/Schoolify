import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';

/// Secondary-container chip for filters / meta (branding secondary tier).
class SchoolifyChip extends StatelessWidget {
  const SchoolifyChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      backgroundColor: scheme.secondaryContainer,
      selectedColor: scheme.primary.withOpacity(0.12),
      labelStyle: TextStyle(
        color: scheme.onSecondaryContainer,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
