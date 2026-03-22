import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/auth/domain/auth_session.dart';
import 'package:schoolify_app/core/auth/domain/user_role.dart';
import 'package:schoolify_app/core/auth/providers/auth_providers.dart';
import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/core/tenancy/parent_student_repository.dart';

/// Active `school_id` for repositories (nullable until membership loads).
///
/// Prefer this or [tenantContextProvider]; keep a single tenant read path per [docs/team_task_board.md].
final schoolIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.schoolId;
});

/// Parent UI scope: which child is selected within [schoolIdProvider] tenant.
///
/// Stub mode defaults to `demo-student`. [parentStudentSelectionSyncProvider]
/// sets the first linked student after auth resolves when using Supabase.
final selectedStudentIdProvider = StateProvider<String?>((ref) {
  if (!Env.hasSupabaseConfig) return 'demo-student';
  return null;
});

/// Side-effect provider: keep [selectedStudentIdProvider] aligned with auth + linkage.
///
/// Watch this from app root so it runs after login.
final parentStudentSelectionSyncProvider = Provider<void>((ref) {
  void sync(AsyncValue<AuthSession> authAsync) {
    authAsync.when(
      data: (session) {
        if (!session.isAuthenticated ||
            session.schoolId == null ||
            session.role != UserRole.parent) {
          ref.read(selectedStudentIdProvider.notifier).state = null;
          return;
        }
        final schoolId = session.schoolId!;
        Future(() async {
          final children = await ref
              .read(parentStudentRepositoryProvider)
              .linkedChildren(schoolId: schoolId);
          final current = ref.read(authStateProvider).asData?.value;
          if (current?.schoolId != schoolId ||
              current?.role != UserRole.parent) {
            return;
          }
          ref.read(selectedStudentIdProvider.notifier).state =
              children.isEmpty ? null : children.first.id;
        });
      },
      loading: () {},
      error: (_, __) {
        ref.read(selectedStudentIdProvider.notifier).state = null;
      },
    );
  }

  ref.listen<AsyncValue<AuthSession>>(authStateProvider, (prev, next) {
    sync(next);
  });
  sync(ref.read(authStateProvider));
});
