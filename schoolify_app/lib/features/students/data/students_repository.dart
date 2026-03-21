import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/features/students/domain/student.dart';

abstract class StudentsRepository {
  Future<List<Student>> listStudents({required String schoolId});

  Future<Student> addStudent({
    required String schoolId,
    required String displayName,
    String? homeroomLabel,
  });

  Future<void> deleteStudent({required String id});
}

/// Same mock roster as [StubTeacherStudentsRepository]; kept in memory for demo add/delete.
class StubStudentsRepository implements StudentsRepository {
  final List<Student> _rows = [
    Student(
      id: 's1',
      schoolId: '',
      displayName: 'Jordan Lee',
      homeroomLabel: '5B',
      createdAt: DateTime.utc(2024, 1, 1),
    ),
    Student(
      id: 's2',
      schoolId: '',
      displayName: 'Sam Rivera',
      homeroomLabel: '5B',
      createdAt: DateTime.utc(2024, 1, 1),
    ),
  ];

  @override
  Future<List<Student>> listStudents({required String schoolId}) async {
    return _rows
        .map(
          (s) => Student(
            id: s.id,
            schoolId: schoolId,
            displayName: s.displayName,
            homeroomLabel: s.homeroomLabel,
            createdAt: s.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<Student> addStudent({
    required String schoolId,
    required String displayName,
    String? homeroomLabel,
  }) async {
    final hr = homeroomLabel?.trim();
    final s = Student(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      schoolId: schoolId,
      displayName: displayName.trim(),
      homeroomLabel: (hr != null && hr.isNotEmpty) ? hr : '—',
      createdAt: DateTime.now().toUtc(),
    );
    _rows.add(
      Student(
        id: s.id,
        schoolId: '',
        displayName: s.displayName,
        homeroomLabel: s.homeroomLabel,
        createdAt: s.createdAt,
      ),
    );
    return s;
  }

  @override
  Future<void> deleteStudent({required String id}) async {
    _rows.removeWhere((e) => e.id == id);
  }
}

class SupabaseStudentsRepository implements StudentsRepository {
  SupabaseStudentsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<Student>> listStudents({required String schoolId}) async {
    final rows = await _client
        .from('students')
        .select('id, school_id, display_name, homeroom_label, created_at')
        .eq('school_id', schoolId)
        .order('display_name', ascending: true);

    final list = rows as List<dynamic>;
    return list.map((raw) => _fromRow(raw as Map<String, dynamic>)).toList();
  }

  @override
  Future<Student> addStudent({
    required String schoolId,
    required String displayName,
    String? homeroomLabel,
  }) async {
    final row = await _client.rpc<dynamic>(
      'add_student',
      params: <String, dynamic>{
        'school_id': schoolId,
        'display_name': displayName,
        'homeroom_label': homeroomLabel,
      },
    );
    if (row is! Map<String, dynamic>) {
      throw StateError('add_student returned unexpected payload');
    }
    return _fromRow(row);
  }

  @override
  Future<void> deleteStudent({required String id}) async {
    await _client.from('students').delete().eq('id', id);
  }

  Student _fromRow(Map<String, dynamic> map) {
    final createdRaw = map['created_at'];
    DateTime createdAt;
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw)?.toUtc() ?? DateTime.now().toUtc();
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw.toUtc();
    } else {
      createdAt = DateTime.now().toUtc();
    }
    final nameRaw = (map['display_name'] as String?)?.trim();
    final name = (nameRaw != null && nameRaw.isNotEmpty) ? nameRaw : 'Student';
    final hr = (map['homeroom_label'] as String?)?.trim();
    return Student(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      displayName: name,
      homeroomLabel: (hr != null && hr.isNotEmpty) ? hr : '—',
      createdAt: createdAt,
    );
  }
}

final studentsRepositoryProvider = Provider<StudentsRepository>(
  (ref) {
    if (!Env.hasSupabaseConfig) {
      return StubStudentsRepository();
    }
    return SupabaseStudentsRepository();
  },
);
