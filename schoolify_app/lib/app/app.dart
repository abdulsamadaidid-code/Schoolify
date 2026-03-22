import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/app/router.dart';
import 'package:schoolify_app/core/notifications/push_notification_providers.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/theme/app_theme.dart';

class SchoolifyApp extends ConsumerWidget {
  const SchoolifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(parentStudentSelectionSyncProvider);
    ref.watch(pushNotificationLifecycleProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Schoolify',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
