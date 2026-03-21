import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/ui/app_card.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/sign_out_button.dart';
import 'package:schoolify_app/features/teacher/data/teacher_dashboard_repository.dart';

final teacherDashboardProvider = FutureProvider.autoDispose((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) throw StateError('Missing school context');
  return ref.read(teacherDashboardRepositoryProvider).load(schoolId: schoolId);
});

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: const [SignOutButton()],
      ),
      body: asyncPageBody(
        async: async,
        data: (summary) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                'Today',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Classes',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary.classesTodayLabel,
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
                      summary.pendingAttendanceLabel,
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
                      'Announcements',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary.newAnnouncementsLabel,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
