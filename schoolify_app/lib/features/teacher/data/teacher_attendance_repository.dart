import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';

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

  /// Idempotent upsert for one student/day. [status]: `present` | `absent` | `late`.
  Future<void> upsertMark({
    required String schoolId,
    required String studentId,
    required DateTime date,
    required String status,
  });
}

class StubTeacherAttendanceRepository implements TeacherAttendanceRepository {
  @override
  Future<void> upsertMark({
    required String schoolId,
    required String studentId,
    required DateTime date,
    required String status,
  }) async {}

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

/// Loads `classes` for the current teacher; status reflects school roll for today
/// (schema has no per-class attendance).
class SupabaseTeacherAttendanceRepository implements TeacherAttendanceRepository {
  SupabaseTeacherAttendanceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static String _pgDate(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _todayLocalDateString() {
    final n = DateTime.now();
    final y = n.year.toString().padLeft(4, '0');
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Future<void> upsertMark({
    required String schoolId,
    required String studentId,
    required DateTime date,
    required String status,
  }) async {
    await _client.rpc(
      'upsert_attendance_mark',
      params: <String, dynamic>{
        'school_id': schoolId,
        'student_id': studentId,
        'p_date': _pgDate(date),
        'p_status': status,
      },
    );
  }

  @override
  Future<List<TeacherAttendanceClass>> today({required String schoolId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final classRows = await _client
        .from('classes')
        .select('id, label')
        .eq('school_id', schoolId)
        .eq('teacher_id', userId)
        .order('label');

    final classes = classRows as List<dynamic>;
    if (classes.isEmpty) return [];

    final studentsRes = await _client
        .from('students')
        .select('id')
        .eq('school_id', schoolId);

    final totalStudents = (studentsRes as List<dynamic>).length;
    if (totalStudents == 0) {
      return classes.map((raw) {
        final map = raw as Map<String, dynamic>;
        return TeacherAttendanceClass(
          id: map['id'] as String,
          label: (map['label'] as String?)?.trim().isNotEmpty == true
              ? (map['label'] as String).trim()
              : 'Class',
          statusLabel: 'No students',
        );
      }).toList();
    }

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

    final complete = marked.length >= totalStudents;
    final statusLabel = complete ? 'Marked' : 'Needs mark';

    return classes.map((raw) {
      final map = raw as Map<String, dynamic>;
      return TeacherAttendanceClass(
        id: map['id'] as String,
        label: (map['label'] as String?)?.trim().isNotEmpty == true
            ? (map['label'] as String).trim()
            : 'Class',
        statusLabel: statusLabel,
      );
    }).toList();
  }
}

final teacherAttendanceRepositoryProvider =
    Provider<TeacherAttendanceRepository>(
  (ref) {
    if (!Env.hasSupabaseConfig) {
      return StubTeacherAttendanceRepository();
    }
    return SupabaseTeacherAttendanceRepository();
  },
);
