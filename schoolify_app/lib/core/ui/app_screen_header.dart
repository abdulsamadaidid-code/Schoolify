import 'package:flutter/material.dart';
import 'package:schoolify_app/core/theme/app_colors.dart';

/// Editorial lockup: headline + body spacing ~1.4rem.
class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
