import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/grade_item.dart';

abstract class TeacherGradesRepository {
  Future<List<GradeItem>> recent({required String schoolId});
}

class StubTeacherGradesRepository implements TeacherGradesRepository {
  @override
  Future<List<GradeItem>> recent({required String schoolId}) async {
    return const [
      GradeItem(
        courseLabel: 'Math 5B',
        assignmentLabel: 'Homework ch.7',
        scoreLabel: 'To grade · 18',
      ),
      GradeItem(
        courseLabel: 'Math 4A',
        assignmentLabel: 'Quiz unit 3',
        scoreLabel: 'Graded · avg 84%',
      ),
    ];
  }
}

final teacherGradesRepositoryProvider = Provider<TeacherGradesRepository>(
  (ref) => StubTeacherGradesRepository(),
);
