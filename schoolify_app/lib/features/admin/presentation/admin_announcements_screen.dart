import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/models/announcement.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/theme/app_spacing.dart';
import 'package:schoolify_app/core/theme/app_colors.dart';
import 'package:schoolify_app/core/ui/app_screen_header.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_card.dart';
import 'package:schoolify_app/features/admin/data/admin_announcements_repository.dart';
import 'package:schoolify_app/features/admin/presentation/announcement_editor_sheet.dart';

final adminAnnouncementsProvider = FutureProvider.autoDispose((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) throw StateError('Missing school context');
  return ref.read(adminAnnouncementsRepositoryProvider).list(schoolId: schoolId);
});

class AdminAnnouncementsScreen extends ConsumerWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAnnouncementsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => AnnouncementEditorSheet(
              onPosted: () => ref.invalidate(adminAnnouncementsProvider),
            ),
          );
        },
        child: const Icon(Icons.campaign_outlined),
      ),
      body: asyncPageBody(
        async: async,
        data: (items) => _AdminAnnouncementsList(
          items: items,
          onDelete: (id) => _deleteAnnouncement(context, ref, id),
          onEdit: (announcement) {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => AnnouncementEditorSheet(
                existing: announcement,
                onPosted: () => ref.invalidate(adminAnnouncementsProvider),
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> _deleteAnnouncement(
  BuildContext context,
  WidgetRef ref,
  String announcementId,
) async {
  final schoolId = ref.read(schoolIdProvider);
  if (schoolId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Missing school context')),
    );
    return;
  }
  try {
    await ref.read(adminAnnouncementsRepositoryProvider).deleteAnnouncement(
          announcementId: announcementId,
          schoolId: schoolId,
        );
    ref.invalidate(adminAnnouncementsProvider);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete announcement: $e')),
      );
    }
  }
}

class _AdminAnnouncementsList extends StatelessWidget {
  const _AdminAnnouncementsList({
    required this.items,
    required this.onDelete,
    required this.onEdit,
  });

  final List<Announcement> items;
  final void Function(String id) onDelete;
  final void Function(Announcement announcement) onEdit;

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
        const AppScreenHeader(title: 'Announcements'),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'No announcements yet. Tap + to post one.',
              style: theme.textTheme.bodyLarge,
            ),
          )
        else
          ...items.map((a) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Dismissible(
                key: ValueKey(a.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  color: theme.colorScheme.errorContainer,
                  child: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                onDismissed: (_) => onDelete(a.id),
                child: SchoolifyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              a.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => onEdit(a),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => onDelete(a.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Posted ${_shortDate(a.postedAt)}',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        a.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
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

String _shortDate(DateTime dt) {
  final local = dt.toLocal();
  final yy = local.year.toString().substring(2);
  return '${local.month}/${local.day}/$yy';
}
