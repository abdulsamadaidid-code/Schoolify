import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/theme/app_colors.dart';
import 'package:schoolify_app/core/ui/app_card.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/sign_out_button.dart';
import 'package:schoolify_app/features/teacher/data/teacher_attendance_repository.dart';

final teacherAttendanceProvider = FutureProvider.autoDispose((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) throw StateError('Missing school context');
  return ref.read(teacherAttendanceRepositoryProvider).today(schoolId: schoolId);
});

class TeacherAttendanceScreen extends ConsumerWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherAttendanceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: const [SignOutButton()],
      ),
      body: asyncPageBody(
        async: async,
        data: (classes) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: classes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final c = classes[i];
              return AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.label,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      c.statusLabel,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: c.statusLabel.contains('Needs')
                                ? AppColors.warning
                                : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
