/// Date/time helpers for the Slink UI.
class SlinkDateUtils {
  static String formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Parse backend date strings — handles ISO-8601 and "yyyy-MM-dd HH:mm:ss".
  static DateTime parseDate(String? raw) {
    if (raw == null) return DateTime.now();
    try {
      if (raw.contains('T')) return DateTime.parse(raw);
      if (raw.contains(' ')) {
        final parts = raw.split(' ');
        final dp = parts[0].split('-');
        final tp = parts[1].split(':');
        return DateTime(
          int.parse(dp[0]), int.parse(dp[1]), int.parse(dp[2]),
          int.parse(tp[0]), int.parse(tp[1]), int.parse(tp[2]),
        );
      }
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.now();
    }
  }
}
