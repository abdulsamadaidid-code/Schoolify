import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/theme/app_spacing.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_button.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_card.dart';
import 'package:schoolify_app/features/messaging/data/message_participants_repository.dart';
import 'package:schoolify_app/features/messaging/data/messaging_repository.dart';

class NewMessageSheet extends ConsumerStatefulWidget {
  const NewMessageSheet({
    super.key,
    required this.onCreated,
  });

  final void Function(String threadId, String subject) onCreated;

  @override
  ConsumerState<NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends ConsumerState<NewMessageSheet> {
  final _subjectController = TextEditingController();
  final Set<String> _selectedParticipantIds = <String>{};
  bool _submitting = false;
  String? _subjectError;
  String? _participantsError;

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final subject = _subjectController.text.trim();
    final schoolId = ref.read(schoolIdProvider);
    setState(() {
      _subjectError = subject.isEmpty ? 'Subject is required' : null;
      _participantsError = _selectedParticipantIds.isEmpty
          ? 'Select at least one participant'
          : null;
    });
    if (_subjectError != null || _participantsError != null) return;
    if (schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing school context')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final threadId = await ref.read(messagingRepositoryProvider).createThread(
            schoolId: schoolId,
            subject: subject,
            participantIds: _selectedParticipantIds.toList(growable: false),
          );
      widget.onCreated(threadId, subject);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create thread: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final membersAsync = ref.watch(_messageParticipantsProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New message',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _subjectController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  hintText: 'Subject',
                  errorText: _subjectError,
                ),
                onChanged: (_) {
                  if (_subjectError != null) {
                    setState(() => _subjectError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Participants',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              membersAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return const Text('No school members found.');
                  }
                  return SchoolifyCard(
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: members.map((m) {
                        final selected = _selectedParticipantIds.contains(m.userId);
                        return FilterChip(
                          label: Text('${m.displayName} (${m.role})'),
                          selected: selected,
                          onSelected: (next) {
                            setState(() {
                              if (next) {
                                _selectedParticipantIds.add(m.userId);
                              } else {
                                _selectedParticipantIds.remove(m.userId);
                              }
                              if (_participantsError != null &&
                                  _selectedParticipantIds.isNotEmpty) {
                                _participantsError = null;
                              }
                            });
                          },
                        );
                      }).toList(growable: false),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text('Could not load members: $error'),
              ),
              if (_participantsError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _participantsError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SchoolifyButton(
                label: _submitting ? 'Creating…' : 'Create',
                onPressed: _submitting ? null : _create,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _messageParticipantsProvider =
    FutureProvider.autoDispose<List<MessageParticipant>>((ref) async {
  final schoolId = ref.watch(schoolIdProvider);
  if (schoolId == null) {
    throw StateError('Missing school context');
  }
  return ref
      .read(messageParticipantsRepositoryProvider)
      .listParticipants(schoolId: schoolId);
});
