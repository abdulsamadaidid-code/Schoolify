import 'package:schoolify_app/core/auth/domain/auth_session.dart';
import 'package:schoolify_app/core/notifications/push_token_repository.dart';

/// Web / non-IO: OneSignal is not wired (no `onesignal_flutter` import).
class PushNotificationService {
  PushNotificationService(this._repository);

  final PushTokenRepository _repository;

  Future<void> syncWithSession(AuthSession session) async {}

  Future<void> unregisterCurrentToken() async {}
}
