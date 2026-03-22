import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/grade_item.dart';
import 'package:schoolify_app/core/models/student_summary.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_button.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_card.dart';
import 'package:schoolify_app/features/teacher/data/teacher_grades_repository.dart';
import 'package:schoolify_app/features/teacher/data/teacher_students_repository.dart';

class GradeEditorSheet extends ConsumerStatefulWidget {
  const GradeEditorSheet({
    super.key,
    this.existing,
  });

  final GradeItem? existing;

  @override
  ConsumerState<GradeEditorSheet> createState() => _GradeEditorSheetState();
}

class _GradeEditorSheetState extends ConsumerState<GradeEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _courseController;
  late final TextEditingController _assignmentController;
  late final TextEditingController _scoreController;
  List<StudentSummary> _students = const [];
  String? _selectedStudentId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _courseController = TextEditingController(text: widget.existing?.courseLabel ?? '');
    _assignmentController =
        TextEditingController(text: widget.existing?.assignmentLabel ?? '');
    _scoreController = TextEditingController(text: widget.existing?.scoreLabel ?? '');
    _selectedStudentId = widget.existing?.studentId;
    if (widget.existing == null) {
      _loadStudentsForCreate();
    }
  }

  @override
  void dispose() {
    _courseController.dispose();
    _assignmentController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Future<void> _loadStudentsForCreate() async {
    final schoolId = ref.read(schoolIdProvider);
    if (schoolId == null) return;
    final students =
        await ref.read(teacherStudentsRepositoryProvider).roster(schoolId: schoolId);
    if (!mounted) return;
    setState(() {
      _students = students;
    });
  }

  String? _requiredStudent(String? value) {
    if (widget.existing != null) return null;
    if (value == null || value.isEmpty) {
      return 'Please choose a student';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final schoolId = ref.read(schoolIdProvider);
    if (schoolId == null) return;
    final studentId = _selectedStudentId ?? widget.existing?.studentId;
    if (studentId == null || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a student')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(teacherGradesRepositoryProvider).upsertGrade(
            schoolId: schoolId,
            studentId: studentId,
            courseLabel: _courseController.text.trim(),
            assignmentLabel: _assignmentController.text.trim(),
            scoreLabel: _scoreController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grade saved')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save grade: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + insets),
        child: SchoolifyCard(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit grade' : 'Add grade',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (!isEdit) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedStudentId,
                    decoration: const InputDecoration(labelText: 'Student'),
                    items: _students
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s.id,
                            child: Text(s.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _selectedStudentId = value),
                    validator: _requiredStudent,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _courseController,
                  decoration: const InputDecoration(labelText: 'Course label'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _assignmentController,
                  decoration: const InputDecoration(labelText: 'Assignment label'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _scoreController,
                  decoration: const InputDecoration(labelText: 'Score label'),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                SchoolifyButton(
                  label: _saving ? 'Saving...' : 'Save',
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
