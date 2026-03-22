import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/announcement.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/theme/app_colors.dart';
import 'package:schoolify_app/core/ui/app_card.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/sign_out_button.dart';
import 'package:schoolify_app/features/announcements/data/announcements_repository.dart';

final teacherAnnouncementsProvider = FutureProvider.autoDispose((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) throw StateError('Missing school context');
  return ref.read(announcementsRepositoryProvider).list(schoolId: schoolId);
});

class TeacherAnnouncementsScreen extends ConsumerWidget {
  const TeacherAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherAnnouncementsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: const [SignOutButton()],
      ),
      body: asyncPageBody(
        async: async,
        data: (items) => _AnnouncementList(items: items),
      ),
    );
  }
}

class _AnnouncementList extends StatelessWidget {
  const _AnnouncementList({required this.items});

  final List<Announcement> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final a = items[i];
        final posted = _shortDate(a.postedAt);
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showAnnouncementDialog(context, a),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Posted $posted',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  a.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _showAnnouncementDialog(BuildContext context, Announcement a) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: Text(a.title),
        content: SingleChildScrollView(
          child: Text(
            a.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

String _shortDate(DateTime dt) {
  final local = dt.toLocal();
  final yy = local.year.toString().substring(2);
  return '${local.month}/${local.day}/$yy';
}
