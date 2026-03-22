import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/core/models/parent_linked_child.dart';

/// Reads parent–student linkage for the active tenant ([schoolId]).
abstract class ParentStudentRepository {
  Future<List<String>> listLinkedStudentIds({required String schoolId});

  Future<List<ParentLinkedChild>> linkedChildren({required String schoolId});
}

/// Demo / offline — no Supabase client.
class StubParentStudentRepository implements ParentStudentRepository {
  static const _stubChildren = [
    ParentLinkedChild(id: 'demo-student', displayName: 'Alex Johnson'),
    ParentLinkedChild(id: 'demo-student-2', displayName: 'Sam Lee'),
  ];

  @override
  Future<List<String>> listLinkedStudentIds({required String schoolId}) async {
    return _stubChildren.map((e) => e.id).toList();
  }

  @override
  Future<List<ParentLinkedChild>> linkedChildren({required String schoolId}) async {
    return List.from(_stubChildren);
  }
}

class SupabaseParentStudentRepository implements ParentStudentRepository {
  SupabaseParentStudentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<String>> listLinkedStudentIds({required String schoolId}) async {
    final children = await linkedChildren(schoolId: schoolId);
    return children.map((e) => e.id).toList();
  }

  @override
  Future<List<ParentLinkedChild>> linkedChildren({required String schoolId}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return [];
    }

    final rows = await _client
        .from('student_parents')
        .select('student_id, students(id, display_name)')
        .eq('school_id', schoolId)
        .eq('parent_user_id', user.id);

    final list = rows as List<dynamic>;
    final out = <ParentLinkedChild>[];
    for (final raw in list) {
      final map = raw as Map<String, dynamic>;
      final nested = map['students'];
      if (nested is! Map<String, dynamic>) continue;
      final id = nested['id'] as String?;
      if (id == null) continue;
      final nameRaw = (nested['display_name'] as String?)?.trim();
      final name =
          (nameRaw != null && nameRaw.isNotEmpty) ? nameRaw : 'Student';
      out.add(ParentLinkedChild(id: id, displayName: name));
    }
    out.sort((a, b) => a.displayName.compareTo(b.displayName));
    return out;
  }
}

final parentStudentRepositoryProvider = Provider<ParentStudentRepository>(
  (ref) {
    if (!Env.hasSupabaseConfig) {
      return StubParentStudentRepository();
    }
    return SupabaseParentStudentRepository();
  },
);
