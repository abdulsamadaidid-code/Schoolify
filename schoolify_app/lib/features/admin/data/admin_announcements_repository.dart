import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/features/announcements/data/announcements_repository.dart';

/// Admin write/read path uses the shared announcements repository.
final adminAnnouncementsRepositoryProvider = Provider<AnnouncementsRepository>(
  (ref) => ref.read(announcementsRepositoryProvider),
);
