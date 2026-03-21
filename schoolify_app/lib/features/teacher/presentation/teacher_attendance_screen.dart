import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/theme/app_radii.dart';
import 'package:schoolify_app/core/theme/app_colors.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/sign_out_button.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_card.dart';
import 'package:schoolify_app/features/teacher/data/teacher_attendance_repository.dart';

final teacherAttendanceProvider = FutureProvider.autoDispose((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) throw StateError('Missing school context');
  return ref.read(teacherAttendanceRepositoryProvider).today(schoolId: schoolId);
});

class TeacherAttendanceScreen extends ConsumerWidget {
  const TeacherAttendanceScreen({super.key});

  void _openMark(
    BuildContext context,
    WidgetRef ref,
    TeacherAttendanceClass c,
  ) {
    final path =
        '/teacher/attendance/mark/${Uri.encodeComponent(c.id)}?label=${Uri.encodeQueryComponent(c.label)}';
    context.push(path).then((_) {
      ref.invalidate(teacherAttendanceProvider);
    });
  }

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
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  onTap: () => _openMark(context, ref, c),
                  child: SchoolifyCard(
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
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
