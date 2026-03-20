import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParentDashboardSummary {
  const ParentDashboardSummary({
    required this.childName,
    required this.attendanceStreakLabel,
    required this.upcomingLabel,
  });

  final String childName;
  final String attendanceStreakLabel;
  final String upcomingLabel;
}

abstract class ParentDashboardRepository {
  Future<ParentDashboardSummary> load({required String schoolId});
}

class StubParentDashboardRepository implements ParentDashboardRepository {
  @override
  Future<ParentDashboardSummary> load({required String schoolId}) async {
    return const ParentDashboardSummary(
      childName: 'Alex Johnson',
      attendanceStreakLabel: '12 school days present',
      upcomingLabel: 'Science fair — Mar 28',
    );
  }
}

final parentDashboardRepositoryProvider = Provider<ParentDashboardRepository>(
  (ref) => StubParentDashboardRepository(),
);
