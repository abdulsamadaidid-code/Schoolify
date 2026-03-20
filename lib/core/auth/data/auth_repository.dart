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
      final user = session.user;
      final role = _roleFromUser(user);
      final schoolId = _schoolIdFromUser(user);
      return AuthSession(userId: user.id, role: role, schoolId: schoolId);
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

  String? _schoolIdFromUser(User user) {
    final raw = user.userMetadata?['school_id'];
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }

  /// Temporary: reads `user_metadata['role']` as `admin` | `teacher` | `parent`.
  /// Replace with DB-backed membership when available.
  UserRole? _roleFromUser(User user) {
    final raw = user.userMetadata?['role'];
    if (raw is! String) return null;
    switch (raw.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'teacher':
        return UserRole.teacher;
      case 'parent':
        return UserRole.parent;
      default:
        debugPrint('Unknown role in user_metadata: $raw');
        return null;
    }
  }
}
