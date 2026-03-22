import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/core/models/grade_item.dart';

abstract class ParentGradesRepository {
  Future<List<GradeItem>> recent({
    required String schoolId,
    required String studentId,
  });
}

class StubParentGradesRepository implements ParentGradesRepository {
  @override
  Future<List<GradeItem>> recent({
    required String schoolId,
    required String studentId,
  }) async {
    return const [
      GradeItem(
        courseLabel: 'Mathematics',
        assignmentLabel: 'Unit 4 quiz',
        scoreLabel: '92%',
      ),
      GradeItem(
        courseLabel: 'English',
        assignmentLabel: 'Essay draft',
        scoreLabel: 'B+',
      ),
    ];
  }
}

class SupabaseParentGradesRepository implements ParentGradesRepository {
  SupabaseParentGradesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<GradeItem>> recent({
    required String schoolId,
    required String studentId,
  }) async {
    final rows = await _client
        .from('grade_items')
        .select('course_label, assignment_label, score_label')
        .eq('school_id', schoolId)
        .eq('student_id', studentId)
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

final parentGradesRepositoryProvider = Provider<ParentGradesRepository>(
  (ref) {
    if (!Env.hasSupabaseConfig) {
      return StubParentGradesRepository();
    }
    return SupabaseParentGradesRepository();
  },
);
