import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/auth/domain/auth_session.dart';
import 'package:schoolify_app/core/auth/providers/auth_providers.dart';
import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/core/notifications/push_notification_service.dart';
import 'package:schoolify_app/core/notifications/push_token_repository.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final repo = ref.watch(pushTokenRepositoryProvider);
  return PushNotificationService(repo);
});

/// Side-effect provider: register/unregister OneSignal subscription with `upsert_device_token` after auth + school.
final pushNotificationLifecycleProvider = Provider<void>((ref) {
  void bind(AsyncValue<AuthSession> next) {
    if (!Env.hasSupabaseConfig) return;
    next.when(
      data: (session) {
        Future<void>(() async {
          await ref.read(pushNotificationServiceProvider).syncWithSession(session);
        });
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  ref.listen<AsyncValue<AuthSession>>(authStateProvider, (prev, next) {
    bind(next);
  });
  bind(ref.read(authStateProvider));
});
