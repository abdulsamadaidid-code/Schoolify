import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/models/announcement.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/theme/app_spacing.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_button.dart';
import 'package:schoolify_app/features/admin/data/admin_announcements_repository.dart';

class AnnouncementEditorSheet extends ConsumerStatefulWidget {
  const AnnouncementEditorSheet({
    super.key,
    required this.onPosted,
    this.existing,
  });

  final VoidCallback onPosted;
  final Announcement? existing;

  @override
  ConsumerState<AnnouncementEditorSheet> createState() =>
      _AnnouncementEditorSheetState();
}

class _AnnouncementEditorSheetState extends ConsumerState<AnnouncementEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _bodyController.text = existing.body;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_submitting) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    final schoolId = ref.read(schoolIdProvider);
    if (schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing school context')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      if (_isEdit) {
        await ref.read(adminAnnouncementsRepositoryProvider).editAnnouncement(
              announcementId: widget.existing!.id,
              schoolId: schoolId,
              title: _titleController.text.trim(),
              body: _bodyController.text.trim(),
            );
      } else {
        await ref.read(adminAnnouncementsRepositoryProvider).postAnnouncement(
              schoolId: schoolId,
              title: _titleController.text.trim(),
              body: _bodyController.text.trim(),
            );
      }
      widget.onPosted();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Could not edit announcement: $e'
                  : 'Could not post announcement: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEdit ? 'Edit announcement' : 'New announcement',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Title',
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Title is required';
                    if (v.length > 120) return 'Title is too long';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _bodyController,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 5,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Body',
                    hintText: 'Body',
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Body is required';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                SchoolifyButton(
                  label: _submitting ? 'Saving…' : 'Save',
                  onPressed: _submitting ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
