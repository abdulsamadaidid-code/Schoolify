import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/auth/domain/auth_session.dart';
import 'package:schoolify_app/core/auth/domain/user_role.dart';
import 'package:schoolify_app/core/config/env.dart';

/// Data layer for Supabase Auth only. UI → Provider → **Repository** → Supabase.
///
/// **Dependency:** Auth & tenancy will add profile fetch + tenant context; keep calls here.
class AuthRepository {
  AuthRepository();

  /// Emits session snapshots whenever Supabase auth state changes.
  Stream<AuthSession> watchAuthSession() {
    if (!Env.hasSupabaseConfig) {
      return Stream.value(AuthSession.unauthenticated);
    }

    final client = Supabase.instance.client;
    return client.auth.onAuthStateChange.asyncMap((event) async {
      final session = event.session;
      if (session == null) {
        return AuthSession.unauthenticated;
      }
      return _authSessionFromBackend(session.user);
    });
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (!Env.hasSupabaseConfig) {
      throw StateError('Supabase is not configured. Use --dart-define for URL and anon key.');
    }
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    if (!Env.hasSupabaseConfig) return;
    await Supabase.instance.client.auth.signOut();
  }

  /// Ensures a profile row, then loads tenant role + school from RPC + `school_members`.
  ///
  /// If [get_my_school_id] is null (no membership), [AuthSession.role] and
  /// [AuthSession.schoolId] are both null — [PendingRolePage] handles that.
  Future<AuthSession> _authSessionFromBackend(User user) async {
    final client = Supabase.instance.client;
    await client.from('profiles').upsert({
      'id': user.id,
      'display_name': user.email ?? '',
      'email': user.email,
    });

    final schoolIdRaw = await client.rpc<dynamic>('get_my_school_id');
    final schoolId = _uuidStringOrNull(schoolIdRaw);
    if (schoolId == null) {
      return AuthSession(userId: user.id, role: null, schoolId: null);
    }

    final row = await client
        .from('school_members')
        .select('role')
        .eq('user_id', user.id)
        .eq('school_id', schoolId)
        .maybeSingle();

    final roleRaw = row?['role'];
    final role = roleRaw is String ? _roleFromDbString(roleRaw) : null;

    return AuthSession(
      userId: user.id,
      role: role,
      schoolId: schoolId,
    );
  }

  String? _uuidStringOrNull(dynamic value) {
    if (value == null) return null;
    final s = value is String ? value : value.toString();
    if (s.isEmpty) return null;
    return s;
  }

  UserRole? _roleFromDbString(String raw) {
    switch (raw.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'teacher':
        return UserRole.teacher;
      case 'parent':
        return UserRole.parent;
      default:
        debugPrint('Unknown role in school_members: $raw');
        return null;
    }
  }
}
