import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/config/env.dart';
import 'package:schoolify_app/core/models/fee_summary.dart';

abstract class ParentFeesRepository {
  Future<FeeSummary> summary({required String schoolId});
}

const _feesPlaceholder = FeeSummary(
  balanceLabel: '—',
  nextDueLabel: 'No fee information yet',
  lastPaymentLabel: '—',
);

/// Demo / no Supabase — placeholder until fee tables exist.
class StubParentFeesRepository implements ParentFeesRepository {
  @override
  Future<FeeSummary> summary({required String schoolId}) async {
    return _feesPlaceholder;
  }
}

/// Supabase builds: same placeholder until `fee_*` tables are migrated.
class SupabaseParentFeesRepository implements ParentFeesRepository {
  @override
  Future<FeeSummary> summary({required String schoolId}) async {
    return _feesPlaceholder;
  }
}

final parentFeesRepositoryProvider = Provider<ParentFeesRepository>(
  (ref) {
    if (!Env.hasSupabaseConfig) {
      return StubParentFeesRepository();
    }
    return SupabaseParentFeesRepository();
  },
);
