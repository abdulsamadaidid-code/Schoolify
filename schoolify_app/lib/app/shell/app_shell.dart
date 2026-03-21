import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/app/router/routes.dart';
import 'package:schoolify_app/core/auth/auth_notifier.dart';
import 'package:schoolify_app/core/auth/domain/user_role.dart';
import 'package:schoolify_app/core/auth/providers/auth_providers.dart';
import 'package:schoolify_app/core/config/env.dart';
import 'package:go_router/go_router.dart';

/// Primary chrome for signed-in role areas. Feature agents add tabs / destinations later.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    required this.role,
    required this.child,
    super.key,
  });

  final UserRole role;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.role) {
      UserRole.admin => 'Admin',
      UserRole.teacher => 'Teacher',
      UserRole.parent => 'Parent',
    };

    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: const Icon(Icons.chat_bubble_outline),
        selectedIcon: const Icon(Icons.chat_bubble),
        label: 'Messages',
      ),
    ];

    final body = _index == 0 ? widget.child : _PlaceholderPane(role: widget.role);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        if (wide) {
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: [
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: () async {
                    if (Env.hasSupabaseConfig) {
                      await ref.read(authRepositoryProvider).signOut();
                    } else {
                      ref.read(authProvider.notifier).signOut();
                    }
                    if (context.mounted) {
                      context.go(AppRoutes.splash);
                    }
                  },
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.chat_bubble_outline),
                      selectedIcon: Icon(Icons.chat_bubble),
                      label: Text('Messages'),
                    ),
                  ],
                ),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                onPressed: () async {
                  if (Env.hasSupabaseConfig) {
                    await ref.read(authRepositoryProvider).signOut();
                  } else {
                    ref.read(authProvider.notifier).signOut();
                  }
                  if (context.mounted) {
                    context.go(AppRoutes.splash);
                  }
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: destinations,
          ),
        );
      },
    );
  }
}

class _PlaceholderPane extends StatelessWidget {
  const _PlaceholderPane({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Messages — ${role.name}\n(owned by Messaging feature)',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
