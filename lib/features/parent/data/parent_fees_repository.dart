import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/fee_summary.dart';

abstract class ParentFeesRepository {
  Future<FeeSummary> summary({required String schoolId});
}

class StubParentFeesRepository implements ParentFeesRepository {
  @override
  Future<FeeSummary> summary({required String schoolId}) async {
    return const FeeSummary(
      balanceLabel: '\$120.00',
      nextDueLabel: 'Apr 1 · Spring activities',
      lastPaymentLabel: 'Feb 15 · \$200.00',
    );
  }
}

final parentFeesRepositoryProvider = Provider<ParentFeesRepository>(
  (ref) => StubParentFeesRepository(),
);
