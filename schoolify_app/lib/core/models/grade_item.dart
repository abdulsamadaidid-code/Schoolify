class GradeItem {
  const GradeItem({
    this.id,
    this.studentId,
    required this.courseLabel,
    required this.assignmentLabel,
    required this.scoreLabel,
  });

  final String? id;
  final String? studentId;
  final String courseLabel;
  final String assignmentLabel;
  final String scoreLabel;
}
