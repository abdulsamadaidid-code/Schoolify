import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';
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

class SupabaseTeacherStudentsRepository implements TeacherStudentsRepository {
  SupabaseTeacherStudentsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<StudentSummary>> roster({required String schoolId}) async {
    final rows = await _client
        .from('students')
        .select('id, display_name, homeroom_label')
        .eq('school_id', schoolId)
        .order('display_name', ascending: true);

    final list = rows as List<dynamic>;
    return list.map((raw) {
      final map = raw as Map<String, dynamic>;
      final nameRaw = (map['display_name'] as String?)?.trim();
      final name = (nameRaw != null && nameRaw.isNotEmpty)
          ? nameRaw
          : 'Student';
      final hr = (map['homeroom_label'] as String?)?.trim();
      return StudentSummary(
        id: map['id'] as String,
        displayName: name,
        homeroomLabel: (hr != null && hr.isNotEmpty) ? hr : '—',
      );
    }).toList();
  }
}

final teacherStudentsRepositoryProvider = Provider<TeacherStudentsRepository>(
  (ref) {
    if (!Env.hasSupabaseConfig) {
      return StubTeacherStudentsRepository();
    }
    return SupabaseTeacherStudentsRepository();
  },
);
