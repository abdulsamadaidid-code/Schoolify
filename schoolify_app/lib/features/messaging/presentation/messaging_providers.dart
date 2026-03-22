import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/features/messaging/data/messaging_repository.dart';
import 'package:schoolify_app/features/messaging/domain/thread_message.dart';
import 'package:schoolify_app/features/messaging/domain/thread_summary.dart';

final threadListProvider = FutureProvider.autoDispose<List<ThreadSummary>>((
  ref,
) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) {
    throw StateError('Missing school context');
  }
  return ref.read(messagingRepositoryProvider).listThreads(schoolId: schoolId);
});

final threadMessagesProvider =
    StreamProvider.autoDispose.family<List<ThreadMessage>, String>((
  ref,
  threadId,
) {
  return ref
      .read(messagingRepositoryProvider)
      .watchMessages(threadId: threadId);
});
