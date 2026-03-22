import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/core/models/grade_item.dart';

abstract class TeacherGradesRepository {
  Future<List<GradeItem>> recent({required String schoolId});

  Future<void> upsertGrade({
    required String schoolId,
    required String studentId,
    required String courseLabel,
    required String assignmentLabel,
    required String scoreLabel,
  });

  Future<void> deleteGrade({
    required String gradeItemId,
    required String schoolId,
  });
}

class StubTeacherGradesRepository implements TeacherGradesRepository {
  final List<GradeItem> _items = [
    const GradeItem(
      id: 'g-demo-1',
      studentId: 'demo-student',
      courseLabel: 'Math 5B',
      assignmentLabel: 'Homework ch.7',
      scoreLabel: 'To grade · 18',
    ),
    const GradeItem(
      id: 'g-demo-2',
      studentId: 'demo-student',
      courseLabel: 'Math 4A',
      assignmentLabel: 'Quiz unit 3',
      scoreLabel: 'Graded · avg 84%',
    ),
  ];

  @override
  Future<List<GradeItem>> recent({required String schoolId}) async {
    return List<GradeItem>.unmodifiable(_items);
  }

  @override
  Future<void> upsertGrade({
    required String schoolId,
    required String studentId,
    required String courseLabel,
    required String assignmentLabel,
    required String scoreLabel,
  }) async {
    final i = _items.indexWhere(
      (g) =>
          g.studentId == studentId &&
          g.courseLabel == courseLabel &&
          g.assignmentLabel == assignmentLabel,
    );
    final updated = GradeItem(
      id: i >= 0 ? _items[i].id : 'g-demo-${DateTime.now().microsecondsSinceEpoch}',
      studentId: studentId,
      courseLabel: courseLabel,
      assignmentLabel: assignmentLabel,
      scoreLabel: scoreLabel,
    );
    if (i >= 0) {
      _items[i] = updated;
    } else {
      _items.insert(0, updated);
    }
  }

  @override
  Future<void> deleteGrade({
    required String gradeItemId,
    required String schoolId,
  }) async {
    _items.removeWhere((g) => g.id == gradeItemId);
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
        .select('id, student_id, course_label, assignment_label, score_label')
        .eq('school_id', schoolId)
        .eq('teacher_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    final list = rows as List<dynamic>;
    return list.map((raw) {
      final map = raw as Map<String, dynamic>;
      return GradeItem(
        id: map['id'] as String?,
        studentId: map['student_id'] as String?,
        courseLabel: (map['course_label'] as String?)?.trim() ?? '—',
        assignmentLabel: (map['assignment_label'] as String?)?.trim() ?? '—',
        scoreLabel: (map['score_label'] as String?)?.trim() ?? '—',
      );
    }).toList();
  }

  @override
  Future<void> upsertGrade({
    required String schoolId,
    required String studentId,
    required String courseLabel,
    required String assignmentLabel,
    required String scoreLabel,
  }) async {
    await _client.rpc(
      'upsert_grade_item',
      params: <String, dynamic>{
        'school_id': schoolId,
        'student_id': studentId,
        'course_label': courseLabel,
        'assignment_label': assignmentLabel,
        'score_label': scoreLabel,
      },
    );
  }

  @override
  Future<void> deleteGrade({
    required String gradeItemId,
    required String schoolId,
  }) async {
    await _client.rpc(
      'delete_grade_item',
      params: <String, dynamic>{
        'grade_item_id': gradeItemId,
        'school_id': schoolId,
      },
    );
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
