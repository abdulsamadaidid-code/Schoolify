import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/announcement.dart';

/// Contract: Supabase read for tenant-scoped announcements.
abstract class AnnouncementsRepository {
  Future<List<Announcement>> list({required String schoolId});
}

class StubAnnouncementsRepository implements AnnouncementsRepository {
  @override
  Future<List<Announcement>> list({required String schoolId}) async {
    return [
      Announcement(
        id: '1',
        title: 'Spring break schedule',
        body:
            'School closes Apr 14–18. After-care ends at noon on Apr 14.',
        postedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Announcement(
        id: '2',
        title: 'PTA meeting',
        body: 'Join us Thursday at 6:30 PM in the library.',
        postedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }
}

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>(
  (ref) => StubAnnouncementsRepository(),
);
