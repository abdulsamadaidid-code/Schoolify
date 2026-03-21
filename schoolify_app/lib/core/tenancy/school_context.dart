import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/auth/providers/auth_providers.dart';

/// Active `school_id` for repositories (nullable until membership loads).
///
/// Prefer this or [tenantContextProvider]; keep a single tenant read path per [docs/team_task_board.md].
final schoolIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.schoolId;
});
