import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';

class SchoolMember {
  const SchoolMember({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
  });

  final String userId;
  final String displayName;
  final String email;
  final String role;
}

abstract class AdminMembersRepository {
  Future<List<SchoolMember>> listMembers({required String schoolId});

  Future<void> addMember({
    required String schoolId,
    required String profileId,
    required String role,
  });

  Future<void> removeMember({
    required String schoolId,
    required String profileId,
  });

  Future<void> updateMemberRole({
    required String schoolId,
    required String profileId,
    required String newRole,
  });

  Future<SchoolMember?> lookupByEmail({required String email});
}

class StubAdminMembersRepository implements AdminMembersRepository {
  final List<SchoolMember> _members = [
    SchoolMember(
      userId: 'stub-admin-1',
      displayName: 'Avery Admin',
      email: 'admin@demo.school',
      role: 'admin',
    ),
    SchoolMember(
      userId: 'stub-teacher-1',
      displayName: 'Taylor Teacher',
      email: 'teacher@demo.school',
      role: 'teacher',
    ),
  ];

  @override
  Future<List<SchoolMember>> listMembers({required String schoolId}) async {
    return List<SchoolMember>.from(_members);
  }

  @override
  Future<void> addMember({
    required String schoolId,
    required String profileId,
    required String role,
  }) async {}

  @override
  Future<void> removeMember({
    required String schoolId,
    required String profileId,
  }) async {}

  @override
  Future<void> updateMemberRole({
    required String schoolId,
    required String profileId,
    required String newRole,
  }) async {
    final index = _members.indexWhere((e) => e.userId == profileId);
    if (index < 0) return;
    final member = _members[index];
    _members[index] = SchoolMember(
      userId: member.userId,
      displayName: member.displayName,
      email: member.email,
      role: newRole,
    );
  }

  @override
  Future<SchoolMember?> lookupByEmail({required String email}) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return SchoolMember(
      userId: 'stub-profile-lookup',
      displayName: 'Lookup User',
      email: normalized,
      role: 'teacher',
    );
  }
}

class SupabaseAdminMembersRepository implements AdminMembersRepository {
  SupabaseAdminMembersRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<SchoolMember>> listMembers({required String schoolId}) async {
    final rows = await _client.rpc<dynamic>(
      'list_school_members',
      params: <String, dynamic>{'school_id': schoolId},
    );
    if (rows is! List<dynamic>) {
      throw StateError('list_school_members returned unexpected payload');
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .map(_fromListRow)
        .toList(growable: false);
  }

  @override
  Future<void> addMember({
    required String schoolId,
    required String profileId,
    required String role,
  }) async {
    await _client.rpc<dynamic>(
      'add_school_member',
      params: <String, dynamic>{
        'school_id': schoolId,
        'profile_id': profileId,
        'role': role,
      },
    );
  }

  @override
  Future<void> removeMember({
    required String schoolId,
    required String profileId,
  }) async {
    await _client.rpc<dynamic>(
      'remove_school_member',
      params: <String, dynamic>{
        'school_id': schoolId,
        'profile_id': profileId,
      },
    );
  }

  @override
  Future<void> updateMemberRole({
    required String schoolId,
    required String profileId,
    required String newRole,
  }) async {
    await _client.rpc<dynamic>(
      'update_member_role',
      params: <String, dynamic>{
        'school_id': schoolId,
        'profile_id': profileId,
        'new_role': newRole,
      },
    );
  }

  @override
  Future<SchoolMember?> lookupByEmail({required String email}) async {
    final payload = await _client.rpc<dynamic>(
      'lookup_profile_by_email',
      params: <String, dynamic>{'email': email},
    );

    if (payload is List<dynamic>) {
      if (payload.isEmpty) return null;
      final first = payload.first;
      if (first is! Map<String, dynamic>) return null;
      return _fromLookupRow(first, email);
    }
    if (payload is Map<String, dynamic>) {
      return _fromLookupRow(payload, email);
    }
    return null;
  }

  SchoolMember _fromListRow(Map<String, dynamic> map) {
    final nameRaw = (map['display_name'] as String?)?.trim();
    final emailRaw = (map['email'] as String?)?.trim();
    final roleRaw = (map['role'] as String?)?.trim();
    return SchoolMember(
      userId: map['user_id'] as String,
      displayName: (nameRaw != null && nameRaw.isNotEmpty) ? nameRaw : 'User',
      email: (emailRaw != null && emailRaw.isNotEmpty) ? emailRaw : 'No email',
      role: (roleRaw != null && roleRaw.isNotEmpty) ? roleRaw : 'member',
    );
  }

  SchoolMember _fromLookupRow(Map<String, dynamic> map, String email) {
    final nameRaw = (map['display_name'] as String?)?.trim();
    final normalizedEmail = email.trim().toLowerCase();
    return SchoolMember(
      userId: map['id'] as String,
      displayName:
          (nameRaw != null && nameRaw.isNotEmpty) ? nameRaw : normalizedEmail,
      email: normalizedEmail,
      role: 'profile',
    );
  }
}

final adminMembersRepositoryProvider = Provider<AdminMembersRepository>((ref) {
  if (!Env.hasSupabaseConfig) {
    return StubAdminMembersRepository();
  }
  return SupabaseAdminMembersRepository();
});
