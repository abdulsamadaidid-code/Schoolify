import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schoolify_app/core/models/student_summary.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/sign_out_button.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_button.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_card.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_chip.dart';
import 'package:schoolify_app/features/teacher/data/teacher_attendance_repository.dart';
import 'package:schoolify_app/features/teacher/presentation/teacher_students_screen.dart';

/// Mark P/A/E for today's roster (school-wide until enrollments exist).
class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({
    super.key,
    required this.classId,
    required this.classLabel,
  });

  final String classId;
  final String classLabel;

  @override
  ConsumerState<MarkAttendanceScreen> createState() =>
      _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  final Map<String, String> _statusByStudentId = {};
  bool _saving = false;

  String _statusFor(String studentId) =>
      _statusByStudentId[studentId] ?? 'present';

  void _setStatus(String studentId, String status) {
    setState(() => _statusByStudentId[studentId] = status);
  }

  Future<void> _save(List<StudentSummary> students) async {
    final schoolId = ref.read(schoolIdProvider);
    if (schoolId == null) return;

    setState(() => _saving = true);
    final repo = ref.read(teacherAttendanceRepositoryProvider);
    final today = DateTime.now();
    try {
      await Future.wait(
        students.map(
          (s) => repo.upsertMark(
            schoolId: schoolId,
            studentId: s.id,
            date: today,
            status: _statusFor(s.id),
          ),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teacherStudentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classLabel),
        actions: const [SignOutButton()],
      ),
      body: asyncPageBody(
        async: async,
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('No students on file'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  key: ValueKey<String>(widget.classId),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final s = students[i];
                    final st = _statusFor(s.id);
                    return SchoolifyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            s.homeroomLabel,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SchoolifyChip(
                                label: 'P',
                                selected: st == 'present',
                                onSelected: (_) =>
                                    _setStatus(s.id, 'present'),
                              ),
                              SchoolifyChip(
                                label: 'A',
                                selected: st == 'absent',
                                onSelected: (_) =>
                                    _setStatus(s.id, 'absent'),
                              ),
                              SchoolifyChip(
                                label: 'E',
                                selected: st == 'excused',
                                onSelected: (_) =>
                                    _setStatus(s.id, 'excused'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: SchoolifyButton(
                  label: _saving ? 'Saving…' : 'Save',
                  onPressed: _saving ? null : () => _save(students),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
