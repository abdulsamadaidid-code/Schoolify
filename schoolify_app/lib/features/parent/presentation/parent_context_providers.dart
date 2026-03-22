import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/core/models/parent_linked_child.dart';
import 'package:schoolify_app/core/tenancy/parent_student_repository.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';

/// Linked children for the parent + active school.
final parentLinkedChildrenProvider =
    FutureProvider.autoDispose<List<ParentLinkedChild>>((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) {
    throw StateError('Missing school context');
  }
  return ref.read(parentStudentRepositoryProvider).linkedChildren(
        schoolId: schoolId,
      );
});

/// Effective student id for parent-scoped queries (respects [selectedStudentIdProvider]).
final parentContextStudentIdProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) {
    throw StateError('Missing school context');
  }
  if (!Env.hasSupabaseConfig) {
    return ref.watch(selectedStudentIdProvider) ?? 'demo-student';
  }
  final children = await ref.watch(parentLinkedChildrenProvider.future);
  if (children.isEmpty) return null;
  final selected = ref.watch(selectedStudentIdProvider);
  if (selected != null && children.any((c) => c.id == selected)) {
    return selected;
  }
  return children.first.id;
});
