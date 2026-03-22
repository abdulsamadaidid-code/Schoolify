import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/features/admin/data/admin_members_repository.dart';

final adminMembersProvider = FutureProvider.autoDispose<List<SchoolMember>>((
  ref,
) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) {
    throw StateError('Missing school context');
  }
  return ref
      .read(adminMembersRepositoryProvider)
      .listMembers(schoolId: schoolId);
});
