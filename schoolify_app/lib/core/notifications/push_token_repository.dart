import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';

abstract class PushTokenRepository {
  Future<void> registerOrRefreshToken({
    required String schoolId,
    required String platform,
    required String token,
    String? deviceLabel,
    String? appVersion,
  });

  Future<void> unregisterToken({required String token});
}

class StubPushTokenRepository implements PushTokenRepository {
  @override
  Future<void> registerOrRefreshToken({
    required String schoolId,
    required String platform,
    required String token,
    String? deviceLabel,
    String? appVersion,
  }) async {}

  @override
  Future<void> unregisterToken({required String token}) async {}
}

class SupabasePushTokenRepository implements PushTokenRepository {
  SupabasePushTokenRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<void> registerOrRefreshToken({
    required String schoolId,
    required String platform,
    required String token,
    String? deviceLabel,
    String? appVersion,
  }) async {
    await _client.rpc<dynamic>(
      'upsert_device_token',
      params: <String, dynamic>{
        'p_school_id': schoolId,
        'p_platform': platform,
        'p_token': token,
        'p_device_label': deviceLabel,
        'p_app_version': appVersion,
      },
    );
  }

  @override
  Future<void> unregisterToken({required String token}) async {
    await _client.from('device_tokens').delete().eq('token', token);
  }
}

final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  if (!Env.hasSupabaseConfig) {
    return StubPushTokenRepository();
  }
  return SupabasePushTokenRepository();
});
