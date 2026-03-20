import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/auth/domain/auth_session.dart';
import 'package:schoolify_app/core/auth/domain/user_role.dart';

/// MVP: demo sign-in only. Replace with Supabase session + profile when Auth & tenancy ships.
class AuthNotifier extends Notifier<AuthSession> {
  @override
  AuthSession build() => AuthSession.unauthenticated;

  void signInDemo({required UserRole role}) {
    state = AuthSession(
      userId: 'demo-user',
      role: role,
      schoolId: 'demo-school',
    );
  }

  void signOut() {
    state = AuthSession.unauthenticated;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthSession>(AuthNotifier.new);
