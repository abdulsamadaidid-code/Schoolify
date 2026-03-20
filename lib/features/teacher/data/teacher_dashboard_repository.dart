import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeacherDashboardSummary {
  const TeacherDashboardSummary({
    required this.classesTodayLabel,
    required this.pendingAttendanceLabel,
    required this.newAnnouncementsLabel,
  });

  final String classesTodayLabel;
  final String pendingAttendanceLabel;
  final String newAnnouncementsLabel;
}

abstract class TeacherDashboardRepository {
  Future<TeacherDashboardSummary> load({required String schoolId});
}

class StubTeacherDashboardRepository implements TeacherDashboardRepository {
  @override
  Future<TeacherDashboardSummary> load({required String schoolId}) async {
    return const TeacherDashboardSummary(
      classesTodayLabel: '3 classes · Grades 4–6',
      pendingAttendanceLabel: '1 class not marked',
      newAnnouncementsLabel: '2 school posts this week',
    );
  }
}

final teacherDashboardRepositoryProvider =
    Provider<TeacherDashboardRepository>(
  (ref) => StubTeacherDashboardRepository(),
);
