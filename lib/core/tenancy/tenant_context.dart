import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/auth/providers/auth_providers.dart';

/// Resolved tenant scope for data repositories (multi-tenant `school_id`).
///
/// **Dependency:** Auth & tenancy will align with RLS + membership; [AuthSession.schoolId] is the hook.
class TenantContext {
  const TenantContext({this.schoolId});

  final String? schoolId;

  bool get hasSchool => schoolId != null;
}

final tenantContextProvider = Provider<TenantContext>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (session) {
      if (session.isGuest) {
        return const TenantContext();
      }
      return TenantContext(schoolId: session.schoolId);
    },
    loading: () => const TenantContext(),
    error: (_, __) => const TenantContext(),
  );
});
