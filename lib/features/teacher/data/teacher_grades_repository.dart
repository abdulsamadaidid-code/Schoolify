import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/core/models/grade_item.dart';

abstract class TeacherGradesRepository {
  Future<List<GradeItem>> recent({required String schoolId});
}

class StubTeacherGradesRepository implements TeacherGradesRepository {
  @override
  Future<List<GradeItem>> recent({required String schoolId}) async {
    return const [
      GradeItem(
        courseLabel: 'Math 5B',
        assignmentLabel: 'Homework ch.7',
        scoreLabel: 'To grade · 18',
      ),
      GradeItem(
        courseLabel: 'Math 4A',
        assignmentLabel: 'Quiz unit 3',
        scoreLabel: 'Graded · avg 84%',
      ),
    ];
  }
}

class SupabaseTeacherGradesRepository implements TeacherGradesRepository {
  SupabaseTeacherGradesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<GradeItem>> recent({required String schoolId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('grade_items')
        .select('course_label, assignment_label, score_label')
        .eq('school_id', schoolId)
        .eq('teacher_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    final list = rows as List<dynamic>;
    return list.map((raw) {
      final map = raw as Map<String, dynamic>;
      return GradeItem(
        courseLabel: (map['course_label'] as String?)?.trim() ?? '—',
        assignmentLabel: (map['assignment_label'] as String?)?.trim() ?? '—',
        scoreLabel: (map['score_label'] as String?)?.trim() ?? '—',
      );
    }).toList();
  }
}

final teacherGradesRepositoryProvider = Provider<TeacherGradesRepository>(
  (ref) {
    if (!Env.hasSupabaseConfig) {
      return StubTeacherGradesRepository();
    }
    return SupabaseTeacherGradesRepository();
  },
);
