import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/auth/auth_notifier.dart';
import 'package:schoolify_app/core/auth/providers/auth_providers.dart';
import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/core/notifications/push_notification_providers.dart';

/// Unregisters push token while still authenticated, then signs out (Supabase).
Future<void> performSchoolifySignOut(WidgetRef ref) async {
  if (Env.hasSupabaseConfig) {
    await ref.read(pushNotificationServiceProvider).unregisterCurrentToken();
    await ref.read(authRepositoryProvider).signOut();
  } else {
    ref.read(authProvider.notifier).signOut();
  }
}
