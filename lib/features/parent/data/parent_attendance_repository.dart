import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/attendance_day.dart';

abstract class ParentAttendanceRepository {
  Future<List<AttendanceDay>> recent({required String schoolId});
}

class StubParentAttendanceRepository implements ParentAttendanceRepository {
  @override
  Future<List<AttendanceDay>> recent({required String schoolId}) async {
    final now = DateTime.now();
    return List.generate(5, (i) {
      final d = now.subtract(Duration(days: i));
      return AttendanceDay(
        date: d,
        statusLabel: i == 2 ? 'Excused' : 'Present',
      );
    });
  }
}

final parentAttendanceRepositoryProvider =
    Provider<ParentAttendanceRepository>(
  (ref) => StubParentAttendanceRepository(),
);
