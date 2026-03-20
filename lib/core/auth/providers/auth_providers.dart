import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/auth/auth_notifier.dart';
import 'package:schoolify_app/core/auth/data/auth_repository.dart';
import 'package:schoolify_app/core/auth/domain/auth_session.dart';
import 'package:schoolify_app/core/config/env.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Supabase-backed session stream only (always unauthenticated when env is missing).
final authSessionStreamProvider = StreamProvider<AuthSession>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthSession();
});

/// **Single source of truth** for routing and guards: Supabase when configured, else demo [authProvider].
final authStateProvider = Provider<AsyncValue<AuthSession>>((ref) {
  if (Env.hasSupabaseConfig) {
    return ref.watch(authSessionStreamProvider);
  }
  return AsyncValue.data(ref.watch(authProvider));
});
