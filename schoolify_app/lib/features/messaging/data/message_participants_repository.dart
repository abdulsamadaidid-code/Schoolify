import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';

class MessageParticipant {
  const MessageParticipant({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  final String userId;
  final String displayName;
  final String role;
}

abstract class MessageParticipantsRepository {
  Future<List<MessageParticipant>> listParticipants({required String schoolId});
}

class StubMessageParticipantsRepository implements MessageParticipantsRepository {
  @override
  Future<List<MessageParticipant>> listParticipants({required String schoolId}) async {
    return const [
      MessageParticipant(
        userId: 'stub-teacher-1',
        displayName: 'Taylor Teacher',
        role: 'teacher',
      ),
      MessageParticipant(
        userId: 'stub-parent-1',
        displayName: 'Parker Parent',
        role: 'parent',
      ),
    ];
  }
}

class SupabaseMessageParticipantsRepository implements MessageParticipantsRepository {
  SupabaseMessageParticipantsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<MessageParticipant>> listParticipants({required String schoolId}) async {
    final rows = await _client.rpc<dynamic>(
      'list_message_participants',
      params: <String, dynamic>{'school_id': schoolId},
    );
    if (rows is! List<dynamic>) {
      throw StateError('list_message_participants returned unexpected payload');
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .map((map) {
          final nameRaw = (map['display_name'] as String?)?.trim();
          final roleRaw = (map['role'] as String?)?.trim();
          return MessageParticipant(
            userId: map['user_id'] as String,
            displayName:
                (nameRaw != null && nameRaw.isNotEmpty) ? nameRaw : 'User',
            role: (roleRaw != null && roleRaw.isNotEmpty) ? roleRaw : 'member',
          );
        })
        .toList(growable: false);
  }
}

final messageParticipantsRepositoryProvider =
    Provider<MessageParticipantsRepository>((ref) {
  if (!Env.hasSupabaseConfig) {
    return StubMessageParticipantsRepository();
  }
  return SupabaseMessageParticipantsRepository();
});
