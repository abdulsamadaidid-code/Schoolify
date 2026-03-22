import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/features/parent/data/parent_attendance_streak.dart';

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
  Future<ParentDashboardSummary> load({
    required String schoolId,
    required String studentId,
  });
}

class StubParentDashboardRepository implements ParentDashboardRepository {
  @override
  Future<ParentDashboardSummary> load({
    required String schoolId,
    required String studentId,
  }) async {
    if (studentId == 'demo-student-2') {
      return const ParentDashboardSummary(
        childName: 'Sam Lee',
        attendanceStreakLabel: '5 school days present',
        upcomingLabel: 'Science fair — Mar 28',
      );
    }
    return const ParentDashboardSummary(
      childName: 'Alex Johnson',
      attendanceStreakLabel: '12 school days present',
      upcomingLabel: 'Science fair — Mar 28',
    );
  }
}

/// RLS scopes rows; [schoolId] matches app tenant context.
class SupabaseParentDashboardRepository implements ParentDashboardRepository {
  SupabaseParentDashboardRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<ParentDashboardSummary> load({
    required String schoolId,
    required String studentId,
  }) async {
    final student = await _client
        .from('students')
        .select('id, display_name')
        .eq('school_id', schoolId)
        .eq('id', studentId)
        .maybeSingle();

    if (student == null) {
      return const ParentDashboardSummary(
        childName: 'No student on file',
        attendanceStreakLabel: 'No attendance yet',
        upcomingLabel: 'No upcoming announcements',
      );
    }

    final childName = (student['display_name'] as String?)?.trim();
    final name = (childName != null && childName.isNotEmpty)
        ? childName
        : 'Student';

    final attendanceRows = await _client
        .from('attendance')
        .select('date, status')
        .eq('school_id', schoolId)
        .eq('student_id', studentId)
        .order('date', ascending: false);

    final streak = presentStreakDaysFromRows(attendanceRows as List<dynamic>);

    final streakLabel = streak > 0
        ? '$streak consecutive day${streak == 1 ? '' : 's'} present'
        : 'No attendance yet';

    final nowUtc = DateTime.now().toUtc();
    final upcoming = await _client
        .from('announcements')
        .select('id')
        .eq('school_id', schoolId)
        .gte('posted_at', nowUtc.toIso8601String());

    final n = (upcoming as List<dynamic>).length;
    final upcomingLabel = n == 0
        ? 'No upcoming announcements'
        : '$n upcoming announcement${n == 1 ? '' : 's'}';

    return ParentDashboardSummary(
      childName: name,
      attendanceStreakLabel: streakLabel,
      upcomingLabel: upcomingLabel,
    );
  }
}

final parentDashboardRepositoryProvider = Provider<ParentDashboardRepository>(
  (ref) {
    if (!Env.hasSupabaseConfig) {
      return StubParentDashboardRepository();
    }
    return SupabaseParentDashboardRepository();
  },
);
