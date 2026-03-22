/// Consecutive calendar days with `present`, ending at the most recent present day.
int presentStreakDaysFromRows(List<dynamic> rows) {
  final byDay = <DateTime>{};
  for (final raw in rows) {
    final map = raw as Map<String, dynamic>;
    final status = (map['status'] as String?)?.toLowerCase();
    if (status != 'present') continue;
    final dateStr = map['date'] as String?;
    if (dateStr == null) continue;
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) continue;
    byDay.add(DateTime.utc(parsed.year, parsed.month, parsed.day));
  }
  final presentDates = byDay.toList()..sort((a, b) => b.compareTo(a));
  if (presentDates.isEmpty) return 0;

  var streak = 1;
  for (var i = 1; i < presentDates.length; i++) {
    final prev = presentDates[i - 1];
    final curr = presentDates[i];
    if (prev.difference(curr).inDays == 1) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}
