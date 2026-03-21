import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:schoolify_app/app/router/go_router_refresh.dart';
import 'package:schoolify_app/app/router/routes.dart';
import 'package:schoolify_app/app/shell/app_shell.dart';
import 'package:schoolify_app/core/auth/domain/auth_session.dart';
import 'package:schoolify_app/core/auth/domain/user_role.dart';
import 'package:schoolify_app/core/auth/providers/auth_providers.dart';
import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/features/auth/presentation/login_page.dart';
import 'package:schoolify_app/features/auth/presentation/role_select_screen.dart';
import 'package:schoolify_app/features/home/presentation/pending_role_page.dart';
import 'package:schoolify_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:schoolify_app/features/home/presentation/splash_page.dart';
import 'package:schoolify_app/features/parent/presentation/parent_announcements_screen.dart';
import 'package:schoolify_app/features/parent/presentation/parent_attendance_screen.dart';
import 'package:schoolify_app/features/parent/presentation/parent_dashboard_screen.dart';
import 'package:schoolify_app/features/parent/presentation/parent_fees_screen.dart';
import 'package:schoolify_app/features/parent/presentation/parent_grades_screen.dart';
import 'package:schoolify_app/features/parent/presentation/parent_shell.dart';
import 'package:schoolify_app/features/teacher/presentation/teacher_announcements_screen.dart';
import 'package:schoolify_app/features/teacher/presentation/teacher_attendance_screen.dart';
import 'package:schoolify_app/features/teacher/presentation/teacher_dashboard_screen.dart';
import 'package:schoolify_app/features/teacher/presentation/teacher_grades_screen.dart';
import 'package:schoolify_app/features/teacher/presentation/teacher_shell.dart';
import 'package:schoolify_app/features/teacher/presentation/teacher_students_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Env.hasSupabaseConfig ? AppRoutes.splash : '/',
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) =>
            Env.hasSupabaseConfig ? const SplashPage() : const RoleSelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => Env.hasSupabaseConfig
            ? const LoginPage()
            : const RoleSelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingRole,
        builder: (context, state) => const PendingRolePage(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AppShell(
          role: UserRole.admin,
          child: AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/parent',
        redirect: (context, state) {
          if (state.uri.path == '/parent') {
            return '/parent/dashboard';
          }
          return null;
        },
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return ParentShell(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'dashboard',
                    builder: (context, state) => const ParentDashboardScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'attendance',
                    builder: (context, state) =>
                        const ParentAttendanceScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'grades',
                    builder: (context, state) => const ParentGradesScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'announcements',
                    builder: (context, state) =>
                        const ParentAnnouncementsScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'fees',
                    builder: (context, state) => const ParentFeesScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/teacher',
        redirect: (context, state) {
          if (state.uri.path == '/teacher') {
            return '/teacher/dashboard';
          }
          return null;
        },
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return TeacherShell(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'dashboard',
                    builder: (context, state) =>
                        const TeacherDashboardScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'attendance',
                    builder: (context, state) =>
                        const TeacherAttendanceScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'students',
                    builder: (context, state) =>
                        const TeacherStudentsScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'grades',
                    builder: (context, state) => const TeacherGradesScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'announcements',
                    builder: (context, state) =>
                        const TeacherAnnouncementsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

String? _redirect(Ref ref, GoRouterState state) {
  final authAsync = ref.read(authStateProvider);
  final loc = state.matchedLocation;

  return authAsync.when(
    data: (session) {
      if (Env.hasSupabaseConfig) {
        return _redirectSupabase(session, loc);
      }
      return _redirectDemo(session, loc);
    },
    loading: () {
      if (!Env.hasSupabaseConfig) return null;
      if (loc == AppRoutes.splash || loc == AppRoutes.login) return null;
      return AppRoutes.splash;
    },
    error: (_, __) => Env.hasSupabaseConfig ? AppRoutes.login : '/',
  );
}

String? _redirectDemo(AuthSession session, String loc) {
  if (session.isGuest) {
    if (loc == '/' || loc == AppRoutes.login) return null;
    return '/';
  }

  final role = session.role;
  if (role == UserRole.parent) {
    if (!loc.startsWith('/parent')) {
      return '/parent/dashboard';
    }
    if (loc == '/parent') {
      return '/parent/dashboard';
    }
    return null;
  }
  if (role == UserRole.teacher) {
    if (!loc.startsWith('/teacher')) {
      return '/teacher/dashboard';
    }
    if (loc == '/teacher') {
      return '/teacher/dashboard';
    }
    return null;
  }
  if (role == UserRole.admin) {
    if (loc != AppRoutes.admin) {
      return AppRoutes.admin;
    }
    return null;
  }
  return '/';
}

String? _redirectSupabase(AuthSession session, String loc) {
  if (!session.isAuthenticated) {
    if (loc == AppRoutes.login) return null;
    return AppRoutes.login;
  }
  if (session.role == null) {
    if (loc == AppRoutes.pendingRole) return null;
    return AppRoutes.pendingRole;
  }

  final role = session.role!;
  final home = switch (role) {
    UserRole.admin => AppRoutes.admin,
    UserRole.teacher => '/teacher/dashboard',
    UserRole.parent => '/parent/dashboard',
  };

  if (loc == AppRoutes.login ||
      loc == AppRoutes.splash ||
      loc == AppRoutes.pendingRole) {
    return home;
  }

  if (role == UserRole.parent) {
    if (!loc.startsWith('/parent')) {
      return home;
    }
    if (loc == '/parent') {
      return home;
    }
    return null;
  }
  if (role == UserRole.teacher) {
    if (!loc.startsWith('/teacher')) {
      return home;
    }
    if (loc == '/teacher') {
      return home;
    }
    return null;
  }
  if (role == UserRole.admin && loc != AppRoutes.admin) {
    return AppRoutes.admin;
  }
  return null;
}
