import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/ui/app_card.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/sign_out_button.dart';
import 'package:schoolify_app/features/parent/data/parent_dashboard_repository.dart';
import 'package:schoolify_app/features/parent/presentation/parent_child_switcher_row.dart';
import 'package:schoolify_app/features/parent/presentation/parent_context_providers.dart';

final parentDashboardProvider =
    FutureProvider.autoDispose<ParentDashboardSummary>((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) {
    throw StateError('Missing school context');
  }
  final studentId = await ref.watch(parentContextStudentIdProvider.future);
  if (studentId == null) {
    return const ParentDashboardSummary(
      childName: 'No students linked',
      attendanceStreakLabel: '—',
      upcomingLabel: '—',
    );
  }
  return ref.read(parentDashboardRepositoryProvider).load(
        schoolId: schoolId,
        studentId: studentId,
      );
});

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parentDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: const [SignOutButton()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ParentChildSwitcherRow(),
          Expanded(
            child: asyncPageBody(
              async: async,
              data: (summary) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            summary.childName,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            summary.attendanceStreakLabel,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upcoming',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            summary.upcomingLabel,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
