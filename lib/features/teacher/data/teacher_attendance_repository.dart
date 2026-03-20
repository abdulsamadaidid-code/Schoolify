import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeacherAttendanceClass {
  const TeacherAttendanceClass({
    required this.id,
    required this.label,
    required this.statusLabel,
  });

  final String id;
  final String label;
  final String statusLabel;
}

abstract class TeacherAttendanceRepository {
  Future<List<TeacherAttendanceClass>> today({required String schoolId});
}

class StubTeacherAttendanceRepository implements TeacherAttendanceRepository {
  @override
  Future<List<TeacherAttendanceClass>> today({required String schoolId}) async {
    return const [
      TeacherAttendanceClass(
        id: 'c1',
        label: 'Math 4A',
        statusLabel: 'Marked',
      ),
      TeacherAttendanceClass(
        id: 'c2',
        label: 'Math 5B',
        statusLabel: 'Needs mark',
      ),
    ];
  }
}

final teacherAttendanceRepositoryProvider =
    Provider<TeacherAttendanceRepository>(
  (ref) => StubTeacherAttendanceRepository(),
);
