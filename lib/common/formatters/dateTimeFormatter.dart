
String twoDigits(int n) => n.toString().padLeft(2, '0');

String fmtTime(DateTime dt) => '${twoDigits(dt.hour)}:${twoDigits(dt.minute)}';

String durationLabel(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m';
  final s = d.inSeconds.remainder(60);
  return '${s}s';
}

String dayLabel(DateTime dt, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';

  const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const mo = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // weekday is 1..7
  return '${wd[dt.weekday - 1]}, ${mo[dt.month - 1]} ${dt.day}';
}
