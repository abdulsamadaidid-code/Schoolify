import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:schoolify_app/app/router/routes.dart';
import 'package:schoolify_app/core/auth/sign_out_actions.dart';
import 'package:schoolify_app/core/config/env.dart';

class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Sign out',
      onPressed: () async {
        await performSchoolifySignOut(ref);
        if (context.mounted) {
          context.go(
            Env.hasSupabaseConfig ? AppRoutes.login : AppRoutes.splash,
          );
        }
      },
    );
  }
}
