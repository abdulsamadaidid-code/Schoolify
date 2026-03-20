import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/student_summary.dart';

abstract class TeacherStudentsRepository {
  Future<List<StudentSummary>> roster({required String schoolId});
}

class StubTeacherStudentsRepository implements TeacherStudentsRepository {
  @override
  Future<List<StudentSummary>> roster({required String schoolId}) async {
    return const [
      StudentSummary(
        id: 's1',
        displayName: 'Jordan Lee',
        homeroomLabel: '5B',
      ),
      StudentSummary(
        id: 's2',
        displayName: 'Sam Rivera',
        homeroomLabel: '5B',
      ),
    ];
  }
}

final teacherStudentsRepositoryProvider = Provider<TeacherStudentsRepository>(
  (ref) => StubTeacherStudentsRepository(),
);
