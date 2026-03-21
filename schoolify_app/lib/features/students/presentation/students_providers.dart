import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/features/students/data/students_repository.dart';
import 'package:schoolify_app/features/students/domain/student.dart';

final adminStudentsProvider =
    FutureProvider.autoDispose<List<Student>>((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) {
    throw StateError('Missing school context');
  }
  return ref.read(studentsRepositoryProvider).listStudents(schoolId: schoolId);
});
