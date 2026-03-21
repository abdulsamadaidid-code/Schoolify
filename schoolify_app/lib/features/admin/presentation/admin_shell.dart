import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:schoolify_app/app/router/routes.dart';
import 'package:schoolify_app/core/auth/auth_notifier.dart';
import 'package:schoolify_app/core/auth/providers/auth_providers.dart';
import 'package:schoolify_app/core/config/env.dart';

/// Admin area: dashboard, students, messages (placeholder).
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  Future<void> _signOut(BuildContext context) async {
    if (Env.hasSupabaseConfig) {
      await ref.read(authRepositoryProvider).signOut();
    } else {
      ref.read(authProvider.notifier).signOut();
    }
    if (context.mounted) {
      context.go(AppRoutes.splash);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        if (wide) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Admin'),
              actions: [
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: (i) => shell.goBranch(
                    i,
                    initialLocation: i == shell.currentIndex,
                  ),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Students'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.chat_bubble_outline),
                      selectedIcon: Icon(Icons.chat_bubble),
                      label: Text('Messages'),
                    ),
                  ],
                ),
                Expanded(child: shell),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin'),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: shell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) => shell.goBranch(
              i,
              initialLocation: i == shell.currentIndex,
            ),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Students',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Messages',
              ),
            ],
          ),
        );
      },
    );
  }
}
