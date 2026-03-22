import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:schoolify_app/core/auth/providers/auth_providers.dart';
import 'package:schoolify_app/core/tenancy/parent_student_repository.dart';
import 'package:schoolify_app/core/tenancy/school_context.dart';
import 'package:schoolify_app/core/theme/app_spacing.dart';
import 'package:schoolify_app/core/ui/app_screen_header.dart';
import 'package:schoolify_app/core/ui/async_page_body.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_button.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_card.dart';
import 'package:schoolify_app/core/ui/widgets/schoolify_text_field.dart';
import 'package:schoolify_app/features/admin/data/admin_members_providers.dart';
import 'package:schoolify_app/features/admin/data/admin_members_repository.dart';
import 'package:schoolify_app/features/students/data/students_repository.dart';
import 'package:schoolify_app/features/students/domain/student.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminMembersProvider);
    final currentUserId = ref.watch(
      authStateProvider.select((value) => value.asData?.value.userId),
    );

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fab-add-teacher',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const _AddTeacherSheet(),
              );
            },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add Teacher'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FloatingActionButton.extended(
            heroTag: 'fab-link-parent',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const _LinkParentToStudentSheet(),
              );
            },
            icon: const Icon(Icons.link),
            label: const Text('Link Parent to Student'),
          ),
        ],
      ),
      body: asyncPageBody(
        async: async,
        data: (members) => _MemberListBody(
          members: members,
          currentUserId: currentUserId,
          onChangeRole: (member) => _changeMemberRole(
            context,
            ref,
            member: member,
            currentUserId: currentUserId,
          ),
          onDelete: (member) => _confirmDeleteMember(
            context,
            ref,
            member: member,
            currentUserId: currentUserId,
          ),
        ),
      ),
    );
  }
}

class _MemberListBody extends StatelessWidget {
  const _MemberListBody({
    required this.members,
    required this.currentUserId,
    required this.onChangeRole,
    required this.onDelete,
  });

  final List<SchoolMember> members;
  final String? currentUserId;
  final void Function(SchoolMember member) onChangeRole;
  final void Function(SchoolMember member) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.pageBottomInset + 120,
      ),
      children: [
        const AppScreenHeader(title: 'People'),
        const SizedBox(height: AppSpacing.sm),
        if (members.isEmpty)
          Text(
            'No school members yet.',
            style: theme.textTheme.bodyLarge,
          )
        else
          ...members.map((member) {
            final isSelf = member.userId == currentUserId;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Dismissible(
                key: ValueKey('member-${member.userId}'),
                direction: isSelf
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                confirmDismiss: (_) async {
                  onDelete(member);
                  return false;
                },
                child: SchoolifyCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.displayName,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              member.email,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _RoleBadge(role: member.role),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: isSelf
                            ? 'You cannot change your own role'
                            : 'Change role',
                        onPressed: isSelf ? null : () => onChangeRole(member),
                        icon: const Icon(Icons.manage_accounts_outlined),
                      ),
                      IconButton(
                        tooltip: isSelf
                            ? 'You cannot remove your own membership'
                            : 'Remove',
                        onPressed: isSelf ? null : () => onDelete(member),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = role.trim().isEmpty ? 'member' : role.trim();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Future<void> _changeMemberRole(
  BuildContext context,
  WidgetRef ref, {
  required SchoolMember member,
  required String? currentUserId,
}) async {
  if (member.userId == currentUserId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You cannot change your own role.')),
    );
    return;
  }

  final schoolId = ref.read(schoolIdProvider);
  if (schoolId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Missing school context')),
    );
    return;
  }

  final selectedRole = await showDialog<String>(
    context: context,
    builder: (context) => _ChangeRoleDialog(currentRole: member.role),
  );
  if (selectedRole == null || !context.mounted) return;

  try {
    await ref.read(adminMembersRepositoryProvider).updateMemberRole(
          schoolId: schoolId,
          profileId: member.userId,
          newRole: selectedRole,
        );
    ref.invalidate(adminMembersProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated to $selectedRole.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update role: $e')),
      );
    }
  }
}

Future<void> _confirmDeleteMember(
  BuildContext context,
  WidgetRef ref, {
  required SchoolMember member,
  required String? currentUserId,
}) async {
  if (member.userId == currentUserId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You cannot remove your own membership.')),
    );
    return;
  }

  final schoolId = ref.read(schoolIdProvider);
  if (schoolId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Missing school context')),
    );
    return;
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Remove member?'),
      content: Text('Remove ${member.displayName} from this school?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  try {
    await ref.read(adminMembersRepositoryProvider).removeMember(
          schoolId: schoolId,
          profileId: member.userId,
        );
    ref.invalidate(adminMembersProvider);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove member: $e')),
      );
    }
  }
}

class _ChangeRoleDialog extends StatefulWidget {
  const _ChangeRoleDialog({required this.currentRole});

  final String currentRole;

  @override
  State<_ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends State<_ChangeRoleDialog> {
  static const _roles = ['admin', 'teacher', 'parent'];

  late String _selectedRole = _normalizeRole(widget.currentRole);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change role'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final role in _roles)
            RadioListTile<String>(
              value: role,
              groupValue: _selectedRole,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedRole = value);
              },
              title: Text(_roleLabel(role)),
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedRole),
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  String _normalizeRole(String role) {
    final lower = role.trim().toLowerCase();
    if (_roles.contains(lower)) return lower;
    return 'teacher';
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'teacher':
        return 'Teacher';
      case 'parent':
        return 'Parent';
      default:
        return role;
    }
  }
}

class _AddTeacherSheet extends ConsumerStatefulWidget {
  const _AddTeacherSheet();

  @override
  ConsumerState<_AddTeacherSheet> createState() => _AddTeacherSheetState();
}

class _AddTeacherSheetState extends ConsumerState<_AddTeacherSheet> {
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final schoolId = ref.read(schoolIdProvider);
    if (schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing school context')),
      );
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return;
    }

    setState(() {
      _emailError = null;
      _submitting = true;
    });

    try {
      final profile = await ref
          .read(adminMembersRepositoryProvider)
          .lookupByEmail(email: email);
      if (profile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No account found for that email.')),
          );
        }
        return;
      }

      await ref.read(adminMembersRepositoryProvider).addMember(
            schoolId: schoolId,
            profileId: profile.userId,
            role: 'teacher',
          );
      ref.invalidate(adminMembersProvider);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add teacher: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Teacher',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              SchoolifyTextField(
                label: 'Teacher email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              SchoolifyButton(
                label: _submitting ? 'Adding…' : 'Add Teacher',
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkParentToStudentSheet extends ConsumerStatefulWidget {
  const _LinkParentToStudentSheet();

  @override
  ConsumerState<_LinkParentToStudentSheet> createState() =>
      _LinkParentToStudentSheetState();
}

class _LinkParentToStudentSheetState
    extends ConsumerState<_LinkParentToStudentSheet> {
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _emailError;
  String? _studentError;
  String? _selectedStudentId;
  late final Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadStudents();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<List<Student>> _loadStudents() async {
    final schoolId = ref.read(schoolIdProvider);
    if (schoolId == null) {
      throw StateError('Missing school context');
    }
    return ref.read(studentsRepositoryProvider).listStudents(schoolId: schoolId);
  }

  Future<void> _submit() async {
    final schoolId = ref.read(schoolIdProvider);
    if (schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing school context')),
      );
      return;
    }

    final email = _emailController.text.trim();
    final studentId = _selectedStudentId;
    setState(() {
      _emailError = email.isEmpty ? 'Email is required' : null;
      _studentError = studentId == null ? 'Student is required' : null;
    });
    if (_emailError != null || _studentError != null) return;

    setState(() => _submitting = true);
    try {
      final profile = await ref
          .read(adminMembersRepositoryProvider)
          .lookupByEmail(email: email);
      if (profile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No account found for that email.')),
          );
        }
        return;
      }

      await ref.read(parentStudentRepositoryProvider).addParentLink(
            schoolId: schoolId,
            studentId: studentId!,
            parentUserId: profile.userId,
          );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not link parent: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Link Parent to Student',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              SchoolifyTextField(
                label: 'Parent email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<List<Student>>(
                future: _studentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: LinearProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Could not load students: ${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }
                  final students = snapshot.data ?? const <Student>[];
                  if (students.isEmpty) {
                    return Text(
                      'No students found. Add a student first.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedStudentId,
                    decoration: InputDecoration(
                      labelText: 'Student',
                      errorText: _studentError,
                    ),
                    items: [
                      for (final s in students)
                        DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(s.displayName),
                        ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (value) {
                            setState(() {
                              _selectedStudentId = value;
                              _studentError = null;
                            });
                          },
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              SchoolifyButton(
                label: _submitting ? 'Linking…' : 'Link Parent',
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
