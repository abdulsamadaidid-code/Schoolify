import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'package:schoolify_app/core/auth/domain/auth_session.dart';
import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/core/notifications/push_token_repository.dart';

/// Android: OneSignal active. iOS: initialize only; no permission / registration (Wave 5 stub).
class PushNotificationService {
  PushNotificationService(this._repository);

  final PushTokenRepository _repository;

  bool _initialized = false;
  String? _lastRegisteredToken;
  String? _activeSchoolId;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> syncWithSession(AuthSession session) async {
    if (!Env.hasSupabaseConfig || Env.onesignalAppId.isEmpty) return;
    if (kIsWeb) return;
    if (!_isAndroid && !_isIos) return;

    if (!session.isAuthenticated || session.schoolId == null) {
      _activeSchoolId = null;
      await unregisterCurrentToken();
      return;
    }

    _activeSchoolId = session.schoolId;

    await _ensureOneSignalInitialized();

    if (_isIos) {
      // Wave 5: iOS push disabled — keep OneSignal init for future APNs without registering tokens.
      return;
    }

    await OneSignal.Notifications.requestPermission(true);
    await _registerFromCurrentSubscription();
  }

  Future<void> _ensureOneSignalInitialized() async {
    if (_initialized) return;
    OneSignal.initialize(Env.onesignalAppId);
    OneSignal.User.pushSubscription.addObserver((dynamic state) {
      Future<void>.microtask(_registerFromCurrentSubscription);
    });
    _initialized = true;
  }

  Future<void> _registerFromCurrentSubscription() async {
    if (!_isAndroid) return;
    final schoolId = _activeSchoolId;
    if (schoolId == null) return;

    final id = OneSignal.User.pushSubscription.id;
    if (id == null || id.isEmpty) return;
    if (id == _lastRegisteredToken) return;

    try {
      await _repository.registerOrRefreshToken(
        schoolId: schoolId,
        platform: 'android',
        token: id,
        deviceLabel: null,
        appVersion: null,
      );
      _lastRegisteredToken = id;
    } catch (e, st) {
      debugPrint('push register failed: $e\n$st');
    }
  }

  Future<void> unregisterCurrentToken() async {
    final token = _lastRegisteredToken;
    _lastRegisteredToken = null;
    _activeSchoolId = null;
    if (token == null) return;
    try {
      await _repository.unregisterToken(token: token);
    } catch (e, st) {
      debugPrint('push unregister failed: $e\n$st');
    }
  }
}
