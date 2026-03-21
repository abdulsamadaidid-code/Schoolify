import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';

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

/// RLS scopes rows; [schoolId] matches app tenant context.
///
/// Schema has no class schedule or class↔attendance link: "classes today" lists
/// this teacher's classes; attendance pending uses school-wide roll for today.
class SupabaseTeacherDashboardRepository implements TeacherDashboardRepository {
  SupabaseTeacherDashboardRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static String _todayLocalDateString() {
    final n = DateTime.now();
    final y = n.year.toString().padLeft(4, '0');
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime _startOfWeekUtcMonday() {
    final now = DateTime.now().toUtc();
    final day = DateTime.utc(now.year, now.month, now.day);
    final monday = day.subtract(Duration(days: day.weekday - 1));
    return monday;
  }

  @override
  Future<TeacherDashboardSummary> load({required String schoolId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const TeacherDashboardSummary(
        classesTodayLabel: 'Sign in to see your schedule',
        pendingAttendanceLabel: '—',
        newAnnouncementsLabel: '—',
      );
    }

    final classRows = await _client
        .from('classes')
        .select('label')
        .eq('school_id', schoolId)
        .eq('teacher_id', userId)
        .order('label');

    final classList = classRows as List<dynamic>;
    final labels = classList
        .map((raw) => ((raw as Map<String, dynamic>)['label'] as String?)?.trim())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();

    final nClasses = classList.length;
    late final String classesTodayLabel;
    if (nClasses == 0) {
      classesTodayLabel = 'No classes on file';
    } else {
      final preview = labels.take(3).join(', ');
      final more = labels.length > 3 ? '…' : '';
      classesTodayLabel =
          '$nClasses class${nClasses == 1 ? '' : 'es'} · $preview$more';
    }

    final studentsRes = await _client
        .from('students')
        .select('id')
        .eq('school_id', schoolId);

    final studentIds = (studentsRes as List<dynamic>)
        .map((raw) => (raw as Map<String, dynamic>)['id'] as String)
        .toList();
    final totalStudents = studentIds.length;

    final dateStr = _todayLocalDateString();
    final attendanceToday = await _client
        .from('attendance')
        .select('student_id')
        .eq('school_id', schoolId)
        .eq('date', dateStr);

    final marked = <String>{};
    for (final raw in attendanceToday as List<dynamic>) {
      final id = (raw as Map<String, dynamic>)['student_id'] as String?;
      if (id != null) marked.add(id);
    }

    final pendingAttendanceLabel = totalStudents == 0
        ? 'No students on file'
        : marked.length >= totalStudents
            ? 'All students marked for today'
            : '${totalStudents - marked.length} student${totalStudents - marked.length == 1 ? '' : 's'} not marked for today';

    final weekStart = _startOfWeekUtcMonday().toIso8601String();
    final announcements = await _client
        .from('announcements')
        .select('id')
        .eq('school_id', schoolId)
        .gte('posted_at', weekStart);

    final nAnnounce = (announcements as List<dynamic>).length;
    final newAnnouncementsLabel = nAnnounce == 0
        ? 'No school posts this week'
        : '$nAnnounce school post${nAnnounce == 1 ? '' : 's'} this week';

    return TeacherDashboardSummary(
      classesTodayLabel: classesTodayLabel,
      pendingAttendanceLabel: pendingAttendanceLabel,
      newAnnouncementsLabel: newAnnouncementsLabel,
    );
  }
}

final teacherDashboardRepositoryProvider =
    Provider<TeacherDashboardRepository>(
  (ref) {
    if (!Env.hasSupabaseConfig) {
      return StubTeacherDashboardRepository();
    }
    return SupabaseTeacherDashboardRepository();
  },
);
