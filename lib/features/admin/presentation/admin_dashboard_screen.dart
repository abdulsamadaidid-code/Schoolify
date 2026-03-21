import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/theme/app_spacing.dart';
import 'package:schoolify_app/core/ui/app_screen_header.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminSchoolNameProvider = FutureProvider.autoDispose<String>((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) {
    throw StateError('Missing school context');
  }
  if (!Env.hasSupabaseConfig) {
    return 'Demo School';
  }
  final row = await Supabase.instance.client
      .from('schools')
      .select('name')
      .eq('id', schoolId)
      .single();
  return row['name'] as String;
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminSchoolNameProvider);
    final theme = Theme.of(context);

    return asyncPageBody(
      async: async,
      data: (schoolName) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.pageBottomInset),
          children: [
            AppScreenHeader(title: schoolName),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  SchoolifyCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Students',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '--',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SchoolifyCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teachers',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '--',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SchoolifyCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Classes',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '--',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
