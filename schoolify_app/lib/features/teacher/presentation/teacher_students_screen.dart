import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/student_summary.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/ui/app_card.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/sign_out_button.dart';
import 'package:schoolify_app/features/teacher/data/teacher_students_repository.dart';

String _studentInitial(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  return t[0].toUpperCase();
}

final teacherStudentsProvider = FutureProvider.autoDispose((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) throw StateError('Missing school context');
  return ref.read(teacherStudentsRepositoryProvider).roster(schoolId: schoolId);
});

class TeacherStudentsScreen extends ConsumerWidget {
  const TeacherStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherStudentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: const [SignOutButton()],
      ),
      body: asyncPageBody(
        async: async,
        data: (students) => _StudentList(students: students),
      ),
    );
  }
}

class _StudentList extends StatelessWidget {
  const _StudentList({required this.students});

  final List<StudentSummary> students;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final s = students[i];
        return AppCard(
          child: Row(
            children: [
              CircleAvatar(
                child: Text(_studentInitial(s.displayName)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.displayName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.homeroomLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
