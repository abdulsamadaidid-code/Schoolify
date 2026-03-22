import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/core/models/attendance_day.dart';

abstract class ParentAttendanceRepository {
  Future<List<AttendanceDay>> recent({
    required String schoolId,
    required String studentId,
  });
}

class StubParentAttendanceRepository implements ParentAttendanceRepository {
  @override
  Future<List<AttendanceDay>> recent({
    required String schoolId,
    required String studentId,
  }) async {
    final now = DateTime.now();
    return List.generate(5, (i) {
      final d = now.subtract(Duration(days: i));
      return AttendanceDay(
        date: d,
        statusLabel: i == 2 ? 'Late' : 'Present',
      );
    });
  }
}

/// Loads recent `attendance` rows for the selected student.
class SupabaseParentAttendanceRepository implements ParentAttendanceRepository {
  SupabaseParentAttendanceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<AttendanceDay>> recent({
    required String schoolId,
    required String studentId,
  }) async {
    final rows = await _client
        .from('attendance')
        .select('date, status, students!inner(school_id)')
        .eq('school_id', schoolId)
        .eq('student_id', studentId)
        .order('date', ascending: false)
        .limit(30);

    final list = rows as List<dynamic>;
    return list.map((raw) {
      final map = raw as Map<String, dynamic>;
      final dateStr = map['date'] as String?;
      final date = dateStr != null
          ? DateTime.tryParse(dateStr) ?? DateTime.now()
          : DateTime.now();
      final status = (map['status'] as String?)?.toLowerCase() ?? '';
      final label = switch (status) {
        'present' => 'Present',
        'absent' => 'Absent',
        'late' => 'Late',
        _ => status.isEmpty ? '—' : status,
      };
      return AttendanceDay(date: date, statusLabel: label);
    }).toList();
  }
}

final parentAttendanceRepositoryProvider =
    Provider<ParentAttendanceRepository>(
  (ref) {
    if (!Env.hasSupabaseConfig) {
      return StubParentAttendanceRepository();
    }
    return SupabaseParentAttendanceRepository();
  },
);
