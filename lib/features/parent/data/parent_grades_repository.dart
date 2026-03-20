import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/grade_item.dart';

abstract class ParentGradesRepository {
  Future<List<GradeItem>> recent({required String schoolId});
}

class StubParentGradesRepository implements ParentGradesRepository {
  @override
  Future<List<GradeItem>> recent({required String schoolId}) async {
    return const [
      GradeItem(
        courseLabel: 'Mathematics',
        assignmentLabel: 'Unit 4 quiz',
        scoreLabel: '92%',
      ),
      GradeItem(
        courseLabel: 'English',
        assignmentLabel: 'Essay draft',
        scoreLabel: 'B+',
      ),
    ];
  }
}

final parentGradesRepositoryProvider = Provider<ParentGradesRepository>(
  (ref) => StubParentGradesRepository(),
);
