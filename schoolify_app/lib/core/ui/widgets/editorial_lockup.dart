import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Headline-MD + Body-LG with editorial spacing ([docs/branding.md]).
class EditorialLockup extends StatelessWidget {
  const EditorialLockup({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        SizedBox(height: AppSpacing.headlineBodyGap),
        Text(body, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
