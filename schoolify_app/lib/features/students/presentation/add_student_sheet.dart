import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/theme/app_spacing.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_button.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_text_field.dart';
import 'package:schoolify_app/features/students/data/students_repository.dart';
import 'package:schoolify_app/features/students/presentation/students_providers.dart';

/// Bottom sheet: name + homeroom, submits via [studentsRepositoryProvider].
class AddStudentSheet extends ConsumerStatefulWidget {
  const AddStudentSheet({super.key});

  @override
  ConsumerState<AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends ConsumerState<AddStudentSheet> {
  final _nameController = TextEditingController();
  final _homeroomController = TextEditingController();
  String? _nameError;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _homeroomController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      return;
    }
    setState(() {
      _nameError = null;
      _submitting = true;
    });

    final schoolId = ref.read(schoolIdProvider);
    if (schoolId == null) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing school context')),
        );
      }
      return;
    }

    try {
      await ref.read(studentsRepositoryProvider).addStudent(
            schoolId: schoolId,
            displayName: name,
            homeroomLabel: _homeroomController.text.trim().isEmpty
                ? null
                : _homeroomController.text.trim(),
          );
      ref.invalidate(adminStudentsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add student: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
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
                'Add student',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              SchoolifyTextField(
                label: 'Display name',
                controller: _nameController,
                textInputAction: TextInputAction.next,
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SchoolifyTextField(
                label: 'Homeroom',
                controller: _homeroomController,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.lg),
              SchoolifyButton(
                label: _submitting ? 'Saving…' : 'Add student',
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
