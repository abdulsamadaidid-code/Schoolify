import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/attendance_day.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/theme/app_colors.dart';
import 'package:schoolify_app/core/ui/app_card.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/sign_out_button.dart';
import 'package:schoolify_app/features/parent/data/parent_attendance_repository.dart';
import 'package:schoolify_app/features/parent/presentation/parent_context_providers.dart';

final parentAttendanceProvider = FutureProvider.autoDispose((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) throw StateError('Missing school context');
  final studentId = await ref.watch(parentContextStudentIdProvider.future);
  if (studentId == null) return <AttendanceDay>[];
  return ref.read(parentAttendanceRepositoryProvider).recent(
        schoolId: schoolId,
        studentId: studentId,
      );
});

class ParentAttendanceScreen extends ConsumerWidget {
  const ParentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parentAttendanceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: const [SignOutButton()],
      ),
      body: asyncPageBody(
        async: async,
        data: (days) => _AttendanceList(days: days),
      ),
    );
  }
}

class _AttendanceList extends StatelessWidget {
  const _AttendanceList({required this.days});

  final List<AttendanceDay> days;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final d = days[i];
        final dateLabel =
            '${d.date.month}/${d.date.day}/${d.date.year.toString().substring(2)}';
        return AppCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Text(
                d.statusLabel,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
