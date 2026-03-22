class ThreadSummary {
  const ThreadSummary({
    required this.id,
    required this.subject,
    required this.lastMessageBody,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final String id;
  final String subject;
  final String lastMessageBody;
  final DateTime lastMessageAt;
  final int unreadCount;
}
