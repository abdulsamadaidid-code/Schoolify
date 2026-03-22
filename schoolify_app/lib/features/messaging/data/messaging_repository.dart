import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/features/messaging/domain/thread_message.dart';
import 'package:schoolify_app/features/messaging/domain/thread_summary.dart';

abstract class MessagingRepository {
  Future<List<ThreadSummary>> listThreads({required String schoolId});

  Stream<List<ThreadMessage>> watchMessages({required String threadId});

  Future<void> sendMessage({required String threadId, required String body});

  Future<String> createThread({
    required String schoolId,
    required String subject,
    required List<String> participantIds,
  });
}

class StubMessagingRepository implements MessagingRepository {
  final List<ThreadSummary> _threads = [
    ThreadSummary(
      id: 't1',
      subject: 'Homework follow-up',
      lastMessageBody: 'Thanks, I will review Chapter 4 tonight.',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 45)),
      unreadCount: 1,
    ),
    ThreadSummary(
      id: 't2',
      subject: 'Absence note',
      lastMessageBody: 'Received. We marked the attendance note.',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 0,
    ),
  ];

  final Map<String, List<ThreadMessage>> _messagesByThread = {
    't1': [
      ThreadMessage(
        id: 'm1',
        threadId: 't1',
        senderId: 'teacher-1',
        senderName: 'Taylor Teacher',
        body: 'Please review Chapter 4 before Friday.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ThreadMessage(
        id: 'm2',
        threadId: 't1',
        senderId: 'parent-1',
        senderName: 'Parker Parent',
        body: 'Thanks, I will review Chapter 4 tonight.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
    ],
    't2': [
      ThreadMessage(
        id: 'm3',
        threadId: 't2',
        senderId: 'parent-1',
        senderName: 'Parker Parent',
        body: 'Jordan will be absent tomorrow for a medical appointment.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ThreadMessage(
        id: 'm4',
        threadId: 't2',
        senderId: 'admin-1',
        senderName: 'Avery Admin',
        body: 'Received. We marked the attendance note.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
  };

  @override
  Future<List<ThreadSummary>> listThreads({required String schoolId}) async {
    final rows = List<ThreadSummary>.from(_threads);
    rows.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return rows;
  }

  @override
  Stream<List<ThreadMessage>> watchMessages({required String threadId}) {
    final rows = List<ThreadMessage>.from(_messagesByThread[threadId] ?? const []);
    rows.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Stream.value(rows);
  }

  @override
  Future<void> sendMessage({required String threadId, required String body}) async {
    final normalized = body.trim();
    if (normalized.isEmpty) return;
    final next = ThreadMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      threadId: threadId,
      senderId: 'me',
      senderName: 'You',
      body: normalized,
      createdAt: DateTime.now(),
    );
    _messagesByThread.putIfAbsent(threadId, () => <ThreadMessage>[]).add(next);
    final index = _threads.indexWhere((t) => t.id == threadId);
    if (index >= 0) {
      final current = _threads[index];
      _threads[index] = ThreadSummary(
        id: current.id,
        subject: current.subject,
        lastMessageBody: normalized,
        lastMessageAt: next.createdAt,
        unreadCount: 0,
      );
    }
  }

  @override
  Future<String> createThread({
    required String schoolId,
    required String subject,
    required List<String> participantIds,
  }) async {
    final threadId = 'local-thread-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    _threads.insert(
      0,
      ThreadSummary(
        id: threadId,
        subject: subject.trim(),
        lastMessageBody: 'Thread created',
        lastMessageAt: now,
        unreadCount: 0,
      ),
    );
    _messagesByThread[threadId] = [
      ThreadMessage(
        id: 'local-msg-${DateTime.now().millisecondsSinceEpoch}',
        threadId: threadId,
        senderId: 'me',
        senderName: 'You',
        body: 'Thread created',
        createdAt: now,
      ),
    ];
    return threadId;
  }
}

class SupabaseMessagingRepository implements MessagingRepository {
  SupabaseMessagingRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<ThreadSummary>> listThreads({required String schoolId}) async {
    final threadRows = await _client
        .from('message_threads')
        .select('id, subject, created_at')
        .eq('school_id', schoolId)
        .order('created_at', ascending: false);

    final threads = threadRows as List<dynamic>;
    final out = <ThreadSummary>[];
    for (final raw in threads) {
      final map = raw as Map<String, dynamic>;
      final threadId = map['id'] as String;

      final latestRows = await _client
          .from('thread_messages')
          .select('body, created_at')
          .eq('thread_id', threadId)
          .order('created_at', ascending: false)
          .limit(1);
      final latestList = latestRows as List<dynamic>;
      final latest = latestList.isNotEmpty
          ? latestList.first as Map<String, dynamic>
          : <String, dynamic>{};

      final fallbackCreated = _parseDate(map['created_at']);
      final lastAt = latest.isNotEmpty ? _parseDate(latest['created_at']) : fallbackCreated;
      final lastBody = ((latest['body'] as String?) ?? '').trim();
      out.add(
        ThreadSummary(
          id: threadId,
          subject: ((map['subject'] as String?) ?? 'Thread').trim(),
          lastMessageBody: lastBody.isEmpty ? 'No messages yet' : lastBody,
          lastMessageAt: lastAt,
          unreadCount: 0,
        ),
      );
    }
    out.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return out;
  }

  @override
  Stream<List<ThreadMessage>> watchMessages({required String threadId}) {
    return _client
        .from('thread_messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .order('created_at')
        .map((rows) {
          return rows.map((raw) {
            final map = raw;
            final senderId = (map['sender_id'] as String?) ?? '';
            final senderName = ((map['sender_name'] as String?) ??
                    (map['sender_display_name'] as String?) ??
                    senderId)
                .trim();
            return ThreadMessage(
              id: map['id'] as String,
              threadId: (map['thread_id'] as String?) ?? threadId,
              senderId: senderId,
              senderName: senderName.isEmpty ? 'User' : senderName,
              body: ((map['body'] as String?) ?? '').trim(),
              createdAt: _parseDate(map['created_at']),
            );
          }).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });
  }

  @override
  Future<void> sendMessage({required String threadId, required String body}) async {
    await _client.rpc<void>(
      'send_message',
      params: <String, dynamic>{
        'thread_id': threadId,
        'body': body.trim(),
      },
    );
  }

  @override
  Future<String> createThread({
    required String schoolId,
    required String subject,
    required List<String> participantIds,
  }) async {
    final result = await _client.rpc<dynamic>(
      'create_message_thread',
      params: <String, dynamic>{
        'school_id': schoolId,
        'subject': subject.trim(),
        'participant_ids': participantIds,
      },
    );
    if (result is String) {
      return result;
    }
    if (result is Map<String, dynamic>) {
      final id = result['id'] as String?;
      if (id != null && id.isNotEmpty) return id;
    }
    throw StateError('create_message_thread returned unexpected payload');
  }

  static DateTime _parseDate(Object? raw) {
    if (raw is String) {
      return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
    }
    if (raw is DateTime) return raw.toLocal();
    return DateTime.now();
  }
}

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  if (!Env.hasSupabaseConfig) {
    return StubMessagingRepository();
  }
  return SupabaseMessagingRepository();
});
