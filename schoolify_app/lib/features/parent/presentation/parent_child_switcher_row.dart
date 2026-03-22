import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/features/parent/presentation/parent_context_providers.dart';

/// Choice chips for linked children; hidden when there is only one (or none).
class ParentChildSwitcherRow extends ConsumerWidget {
  const ParentChildSwitcherRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parentLinkedChildrenProvider);
    return async.when(
      data: (children) {
        if (children.length <= 1) return const SizedBox.shrink();
        final selected = ref.watch(selectedStudentIdProvider);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children.map((c) {
              final isSel = selected == c.id;
              return ChoiceChip(
                label: Text(c.displayName),
                selected: isSel,
                onSelected: (_) {
                  ref.read(selectedStudentIdProvider.notifier).state = c.id;
                },
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
