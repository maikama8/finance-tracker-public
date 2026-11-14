/// Calendar date as UTC midnight, using the year, month, and day fields.
///
/// The ledger stores dates this way so a transaction does not shift when the
/// device timezone changes.
DateTime dateOnly(DateTime value) {
  return DateTime.utc(value.year, value.month, value.day);
}

/// `YYYY-MM-DD` for the calendar date of [value].
String formatIsoDate(DateTime value) {
  final date = dateOnly(value);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Parses `YYYY-MM-DD`. Rejects dates the calendar does not have.
DateTime parseIsoDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    throw FormatException('Expected a date YYYY-MM-DD.', value);
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    throw FormatException('Not a real calendar date.', value);
  }
  return date;
}

/// UTC timestamp stored on rows that need a creation time.
String formatIsoTimestamp(DateTime value) => value.toUtc().toIso8601String();

/// Inverse of [formatIsoTimestamp].
DateTime parseIsoTimestamp(String value) => DateTime.parse(value).toUtc();

/// True when [a] and [b] fall on the same calendar day.
bool sameDay(DateTime a, DateTime b) {
  final left = dateOnly(a);
  final right = dateOnly(b);
  return left == right;
}

/// True when [a] is in [year] and [month].
bool sameMonth(DateTime a, int year, int month) {
  return a.year == year && a.month == month;
}

/// UTC midnight on the first day of [month].
DateTime monthStart(int year, int month) => DateTime.utc(year, month, 1);

/// UTC midnight on the last day of [month].
DateTime monthEnd(int year, int month) => DateTime.utc(year, month + 1, 0);

/// The [count] calendar months ending at [today], oldest first.
List<DateTime> trailingMonths(DateTime today, int count) {
  final endIndex = today.year * 12 + (today.month - 1);
  final startIndex = endIndex - (count - 1);
  return <DateTime>[
    for (var i = 0; i < count; i++)
      DateTime.utc((startIndex + i) ~/ 12, (startIndex + i) % 12 + 1, 1),
  ];
}
