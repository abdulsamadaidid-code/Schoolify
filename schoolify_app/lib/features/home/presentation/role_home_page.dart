import 'package:flutter/material.dart';

import 'package:schoolify_app/core/auth/domain/user_role.dart';

/// Placeholder home per role — feature dashboards replace these routes later.
class RoleHomePage extends StatelessWidget {
  const RoleHomePage({required this.role, super.key});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      UserRole.admin => 'Admin',
      UserRole.teacher => 'Teacher',
      UserRole.parent => 'Parent',
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label home',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Placeholder — dashboard feature lands in Wave 2.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
