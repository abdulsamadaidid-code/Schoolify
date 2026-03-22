import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/grade_item.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/ui/app_card.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/sign_out_button.dart';
import 'package:schoolify_app/features/teacher/data/teacher_grades_repository.dart';
import 'package:schoolify_app/features/teacher/presentation/grade_editor_sheet.dart';

final teacherGradesProvider = FutureProvider.autoDispose((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) throw StateError('Missing school context');
  return ref.read(teacherGradesRepositoryProvider).recent(schoolId: schoolId);
});

class TeacherGradesScreen extends ConsumerWidget {
  const TeacherGradesScreen({super.key});

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    GradeItem? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GradeEditorSheet(existing: existing),
    );
    if (saved == true) {
      ref.invalidate(teacherGradesProvider);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    GradeItem item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete grade?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final gradeItemId = item.id;
    if (gradeItemId == null || gradeItemId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete this grade item')),
      );
      return;
    }

    final schoolId = ref.read(schoolIdProvider);
    if (schoolId == null) return;

    try {
      await ref.read(teacherGradesRepositoryProvider).deleteGrade(
            gradeItemId: gradeItemId,
            schoolId: schoolId,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grade deleted')),
      );
      ref.invalidate(teacherGradesProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherGradesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grades'),
        actions: const [SignOutButton()],
      ),
      body: asyncPageBody(
        async: async,
        data: (items) => _GradesList(
          items: items,
          onEdit: (item) => _openEditor(context, ref, existing: item),
          onDelete: (item) => _confirmDelete(context, ref, item),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GradesList extends StatelessWidget {
  const _GradesList({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<GradeItem> items;
  final ValueChanged<GradeItem> onEdit;
  final ValueChanged<GradeItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final g = items[i];
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      g.courseLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => onEdit(g),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => onDelete(g),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                g.assignmentLabel,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                g.scoreLabel,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
