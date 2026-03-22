import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:schoolify_app/core/auth/domain/user_role.dart';
import 'package:schoolify_app/core/auth/providers/auth_providers.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/theme/app_spacing.dart';
import 'package:schoolify_app/core/theme/app_colors.dart';
import 'package:schoolify_app/core/ui/app_screen_header.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_card.dart';
import 'package:schoolify_app/features/messaging/data/messaging_repository.dart';
import 'package:schoolify_app/features/messaging/domain/thread_summary.dart';
import 'package:schoolify_app/features/messaging/presentation/new_message_sheet.dart';

final messagesThreadsProvider = FutureProvider.autoDispose<List<ThreadSummary>>((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) throw StateError('Missing school context');
  return ref.read(messagingRepositoryProvider).listThreads(schoolId: schoolId);
});

class MessagesListScreen extends ConsumerWidget {
  const MessagesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(messagesThreadsProvider);
    final role = ref.watch(authStateProvider.select((value) => value.asData?.value.role));
    final canCreate = role == UserRole.admin || role == UserRole.teacher;
    final basePath = _messagesBasePath(context);

    return Scaffold(
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => NewMessageSheet(
                    onCreated: (threadId, subject) {
                      ref.invalidate(messagesThreadsProvider);
                      final encoded = Uri.encodeComponent(subject);
                      context.push('$basePath/$threadId?subject=$encoded');
                    },
                  ),
                );
              },
              child: const Icon(Icons.edit_outlined),
            )
          : null,
      body: asyncPageBody(
        async: async,
        data: (threads) => _MessagesListBody(
          threads: threads,
          onTapThread: (thread) {
            final encoded = Uri.encodeComponent(thread.subject);
            context.push('$basePath/${thread.id}?subject=$encoded');
          },
        ),
      ),
    );
  }
}

class _MessagesListBody extends StatelessWidget {
  const _MessagesListBody({
    required this.threads,
    required this.onTapThread,
  });

  final List<ThreadSummary> threads;
  final void Function(ThreadSummary thread) onTapThread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.pageBottomInset + 72,
      ),
      children: [
        const AppScreenHeader(title: 'Messages'),
        const SizedBox(height: AppSpacing.sm),
        if (threads.isEmpty)
          Text(
            'No message threads yet.',
            style: theme.textTheme.bodyLarge,
          )
        else
          ...threads.map((thread) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTapThread(thread),
                child: SchoolifyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.subject,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            _shortTimestamp(thread.lastMessageAt),
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        thread.lastMessageBody,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (thread.unreadCount > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${thread.unreadCount} unread',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

String _messagesBasePath(BuildContext context) {
  final state = GoRouterState.of(context);
  final segments = state.uri.pathSegments;
  if (segments.isEmpty) return '/admin/messages';
  return '/${segments.first}/messages';
}

String _shortTimestamp(DateTime dateTime) {
  final local = dateTime.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  if (day == today) {
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
  return '${local.month}/${local.day}';
}
