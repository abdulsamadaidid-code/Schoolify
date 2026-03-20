import 'package:schoolify_app/core/auth/domain/user_role.dart';

/// Client auth snapshot for routing (not a full profile model).
///
/// **Dependency:** Resolve [role] and [schoolId] from Auth & tenancy
/// (`profiles` / `school_members`) when schema + RLS are wired.
class AuthSession {
  const AuthSession({
    required this.userId,
    this.role,
    this.schoolId,
  });

  final String userId;
  final UserRole? role;

  /// Tenant scope for repositories (RLS + app logic). Null until membership loads.
  final String? schoolId;

  bool get isGuest => userId.isEmpty;
  bool get isAuthenticated => !isGuest;
  bool get hasResolvedRole => role != null;

  static const AuthSession unauthenticated = AuthSession._guest();

  const AuthSession._guest() : userId = '', role = null, schoolId = null;
}
