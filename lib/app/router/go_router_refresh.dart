import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/auth/domain/auth_session.dart';
import 'package:schoolify_app/core/auth/providers/auth_providers.dart';

/// Notifies [GoRouter] when [authStateProvider] changes.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this._ref) {
    _sub = _ref.listen<AsyncValue<AuthSession>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<AuthSession>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
