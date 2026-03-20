import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/auth/providers/auth_providers.dart';

/// Signed in but role not resolved (metadata / membership not loaded).
///
/// **Dependency:** Auth & tenancy replaces this with profile bootstrap or invite flow.
class PendingRolePage extends ConsumerWidget {
  const PendingRolePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: auth.when(
          data: (session) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your account is active, but your role is not set yet.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'For development: set `user_metadata.role` to admin, teacher, or parent, '
                'or wait for the membership/profile pipeline.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (session.isAuthenticated) ...[
                const SizedBox(height: 24),
                Text(
                  'User id: ${session.userId}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
        ),
      ),
    );
  }
}
