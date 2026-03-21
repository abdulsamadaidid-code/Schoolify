import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/theme/app_spacing.dart';
import 'package:schoolify_app/core/ui/app_screen_header.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_card.dart';
import 'package:schoolify_app/features/students/data/students_repository.dart';
import 'package:schoolify_app/features/students/domain/student.dart';
import 'package:schoolify_app/features/students/presentation/add_student_sheet.dart';
import 'package:schoolify_app/features/students/presentation/students_providers.dart';

class StudentsListScreen extends ConsumerWidget {
  const StudentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminStudentsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) => const AddStudentSheet(),
          );
        },
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: asyncPageBody(
        async: async,
        data: (students) => _StudentListBody(
          students: students,
          onDelete: (id) => _confirmDelete(context, ref, id),
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Remove student?'),
      content: const Text(
        'This removes the student record for your school.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref.read(studentsRepositoryProvider).deleteStudent(id: id);
    ref.invalidate(adminStudentsProvider);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove: $e')),
      );
    }
  }
}

class _StudentListBody extends StatelessWidget {
  const _StudentListBody({
    required this.students,
    required this.onDelete,
  });

  final List<Student> students;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.pageBottomInset + 72,
      ),
      children: [
        AppScreenHeader(title: 'Students'),
        const SizedBox(height: AppSpacing.sm),
        if (students.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'No students yet. Tap + to add one.',
              style: theme.textTheme.bodyLarge,
            ),
          )
        else
          ...students.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SchoolifyCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.displayName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            s.homeroomLabel,
                            style: theme.textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onDelete(s.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
