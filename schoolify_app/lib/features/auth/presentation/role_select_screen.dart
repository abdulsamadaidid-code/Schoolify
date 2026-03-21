import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/auth/auth_notifier.dart';
import 'package:schoolify_app/core/auth/domain/user_role.dart';
import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/core/theme/app_colors.dart';
import 'package:schoolify_app/core/ui/app_primary_button.dart';
import 'package:schoolify_app/core/ui/app_screen_header.dart';

/// MVP entry: choose role (demo). Replaced by real auth + membership when backend lands.
class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const AppScreenHeader(
              title: 'Schoolify',
              subtitle: 'Sign in to continue (demo: pick a role)',
            ),
            if (!Env.hasSupabaseConfig) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Running without Supabase credentials. Data is sample-only.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            AppPrimaryButton(
              label: 'Continue as Admin',
              onPressed: () {
                ref.read(authProvider.notifier).signInDemo(role: UserRole.admin);
              },
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'Continue as Teacher',
              onPressed: () {
                ref.read(authProvider.notifier).signInDemo(role: UserRole.teacher);
              },
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'Continue as Parent',
              onPressed: () {
                ref.read(authProvider.notifier).signInDemo(role: UserRole.parent);
              },
            ),
          ],
        ),
      ),
    );
  }
}
