import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/grade_item.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/ui/app_card.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/sign_out_button.dart';
import 'package:schoolify_app/features/parent/data/parent_grades_repository.dart';
import 'package:schoolify_app/features/parent/presentation/parent_context_providers.dart';

final parentGradesProvider = FutureProvider.autoDispose((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) throw StateError('Missing school context');
  final studentId = await ref.watch(parentContextStudentIdProvider.future);
  if (studentId == null) return <GradeItem>[];
  return ref.read(parentGradesRepositoryProvider).recent(
        schoolId: schoolId,
        studentId: studentId,
      );
});

class ParentGradesScreen extends ConsumerWidget {
  const ParentGradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parentGradesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grades'),
        actions: const [SignOutButton()],
      ),
      body: asyncPageBody(
        async: async,
        data: (items) => _GradesList(items: items),
      ),
    );
  }
}

class _GradesList extends StatelessWidget {
  const _GradesList({required this.items});

  final List<GradeItem> items;

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
              Text(
                g.courseLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
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
