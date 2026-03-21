/// Tenant-scoped student row (see `public.students`).
class Student {
  const Student({
    required this.id,
    required this.schoolId,
    required this.displayName,
    required this.homeroomLabel,
    required this.createdAt,
  });

  final String id;
  final String schoolId;
  final String displayName;
  final String homeroomLabel;
  final DateTime createdAt;
}
