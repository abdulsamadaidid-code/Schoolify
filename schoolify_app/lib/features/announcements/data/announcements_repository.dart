import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/announcement.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:schoolify_app/core/config/env.dart';

/// Contract: Supabase read for tenant-scoped announcements.
abstract class AnnouncementsRepository {
  Future<List<Announcement>> list({required String schoolId});

  Future<void> postAnnouncement({
    required String schoolId,
    required String title,
    required String body,
  });

  Future<void> deleteAnnouncement({
    required String announcementId,
    required String schoolId,
  });

  Future<void> editAnnouncement({
    required String announcementId,
    required String schoolId,
    required String title,
    required String body,
  });
}

class StubAnnouncementsRepository implements AnnouncementsRepository {
  final List<Announcement> _rows = [
    Announcement(
      id: '1',
      title: 'Spring break schedule',
      body: 'School closes Apr 14–18. After-care ends at noon on Apr 14.',
      postedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Announcement(
      id: '2',
      title: 'PTA meeting',
      body: 'Join us Thursday at 6:30 PM in the library.',
      postedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Future<List<Announcement>> list({required String schoolId}) async {
    return List<Announcement>.from(_rows);
  }

  @override
  Future<void> postAnnouncement({
    required String schoolId,
    required String title,
    required String body,
  }) async {
    _rows.insert(
      0,
      Announcement(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        title: title.trim(),
        body: body.trim(),
        postedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteAnnouncement({
    required String announcementId,
    required String schoolId,
  }) async {
    _rows.removeWhere((row) => row.id == announcementId);
  }

  @override
  Future<void> editAnnouncement({
    required String announcementId,
    required String schoolId,
    required String title,
    required String body,
  }) async {
    final index = _rows.indexWhere((row) => row.id == announcementId);
    if (index < 0) return;
    final existing = _rows[index];
    _rows[index] = Announcement(
      id: existing.id,
      title: title.trim(),
      body: body.trim(),
      postedAt: existing.postedAt,
    );
  }
}

class SupabaseAnnouncementsRepository implements AnnouncementsRepository {
  SupabaseAnnouncementsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<Announcement>> list({required String schoolId}) async {
    final rows = await _client
        .from('announcements')
        .select('id, title, body, posted_at')
        .eq('school_id', schoolId)
        .order('posted_at', ascending: false);

    final list = rows as List<dynamic>;
    return list.map((raw) => _fromRow(raw as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> postAnnouncement({
    required String schoolId,
    required String title,
    required String body,
  }) async {
    await _client.rpc<void>(
      'post_announcement',
      params: <String, dynamic>{
        'school_id': schoolId,
        'title': title.trim(),
        'body': body.trim(),
      },
    );
  }

  @override
  Future<void> deleteAnnouncement({
    required String announcementId,
    required String schoolId,
  }) async {
    await _client
        .from('announcements')
        .delete()
        .eq('id', announcementId)
        .eq('school_id', schoolId);
  }

  @override
  Future<void> editAnnouncement({
    required String announcementId,
    required String schoolId,
    required String title,
    required String body,
  }) async {
    await _client
        .from('announcements')
        .update({
          'title': title.trim(),
          'body': body.trim(),
        })
        .eq('id', announcementId)
        .eq('school_id', schoolId);
  }

  Announcement _fromRow(Map<String, dynamic> map) {
    final postedRaw = map['posted_at'];
    DateTime postedAt;
    if (postedRaw is String) {
      postedAt = DateTime.tryParse(postedRaw)?.toUtc() ?? DateTime.now().toUtc();
    } else if (postedRaw is DateTime) {
      postedAt = postedRaw.toUtc();
    } else {
      postedAt = DateTime.now().toUtc();
    }
    return Announcement(
      id: map['id'] as String,
      title: ((map['title'] as String?)?.trim().isNotEmpty ?? false)
          ? (map['title'] as String).trim()
          : 'Announcement',
      body: (map['body'] as String?)?.trim() ?? '',
      postedAt: postedAt,
    );
  }
}

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>(
  (ref) {
    if (!Env.hasSupabaseConfig) {
      return StubAnnouncementsRepository();
    }
    return SupabaseAnnouncementsRepository();
  },
);
