import '../currency/currency.dart';

/// Formats minor units as a grouped amount with a currency symbol.
///
/// `160000` NGN becomes `₦1,600.00`. A negative value keeps the sign in
/// front of the symbol.
String formatMinor(int minor, String currencyCode) {
  final symbol = Currencies.symbolFor(currencyCode);
  final negative = minor < 0;
  final absolute = minor.abs();
  final major = absolute ~/ 100;
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  final grouped = groupThousands(major);
  return '${negative ? '-' : ''}$symbol$grouped.$fraction';
}

/// Like [formatMinor], with a leading plus when [minor] is positive.
String formatSignedMinor(int minor, String currencyCode) {
  if (minor > 0) return '+${formatMinor(minor, currencyCode)}';
  return formatMinor(minor, currencyCode);
}

/// Compact axis label. `160000000` NGN becomes `₦1.6m`.
String formatCompactMinor(int minor, String currencyCode) {
  final symbol = Currencies.symbolFor(currencyCode);
  final negative = minor < 0;
  final major = minor.abs() / 100;
  final sign = negative ? '-' : '';
  if (major >= 1000000) {
    final millions = major / 1000000;
    final digits = millions >= 10
        ? millions.toStringAsFixed(0)
        : millions.toStringAsFixed(1);
    return '$sign$symbol${_trimZero(digits)}m';
  }
  if (major >= 1000) {
    final thousands = major / 1000;
    final digits = thousands >= 10
        ? thousands.toStringAsFixed(0)
        : thousands.toStringAsFixed(1);
    return '$sign$symbol${_trimZero(digits)}k';
  }
  return formatMinor(minor, currencyCode);
}

/// Axis label. Zero stays `₦0`, so a scale does not spend width on `.00`.
String formatAxisAmount(int minor, String currencyCode) {
  if (minor == 0) return '${Currencies.symbolFor(currencyCode)}0';
  return formatCompactMinor(minor, currencyCode);
}

String _trimZero(String digits) {
  if (digits.endsWith('.0')) return digits.substring(0, digits.length - 2);
  return digits;
}

/// `part / whole` as a percent with one decimal place, truncated toward zero.
String formatShare(int part, int whole) {
  if (whole <= 0) return part > 0 ? '100%+' : '0%';
  final tenths = (part.abs() * 1000) ~/ whole.abs();
  final wholePart = tenths ~/ 10;
  final decimal = tenths % 10;
  final sign = part < 0 ? '-' : '';
  return '$sign$wholePart.$decimal%';
}

/// Parses a user-entered major amount into minor units.
///
/// Accepts `48600`, `48,600.50`, and `12.5`. Returns null when the text is
/// empty, signed, or has more than two decimal places. Zero is rejected
/// unless [allowZero] is set.
int? parseMoneyInput(String input, {bool allowZero = false}) {
  final cleaned = input.trim().replaceAll(',', '');
  if (cleaned.isEmpty) return null;
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final major = int.parse(match.group(1)!);
  final fractionDigits = match.group(2) ?? '';
  final fraction = int.parse(fractionDigits.padRight(2, '0'));
  final minor = major * 100 + fraction;
  if (minor < 0 || (minor == 0 && !allowZero)) return null;
  return minor;
}

/// Major-unit text for an amount field. Whole amounts omit the decimals.
///
/// `160000` is `1600`. `160050` is `1600.50`. A negative value keeps the sign.
String formatEditableAmount(int minor) {
  final negative = minor < 0;
  final absolute = minor.abs();
  final major = absolute ~/ 100;
  final fraction = absolute % 100;
  final digits = fraction == 0
      ? '$major'
      : '$major.${fraction.toString().padLeft(2, '0')}';
  return negative ? '-$digits' : digits;
}

const List<String> _shortMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _longMonths = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// `14 Nov 2026`.
String formatShortDate(DateTime date) {
  return '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';
}

/// `November 2026`.
String formatMonthYear(int year, int month) {
  return '${_longMonths[month - 1]} $year';
}

/// `Nov` for month 11.
String formatShortMonth(int month) => _shortMonths[month - 1];

/// Groups a non-negative integer with thousands separators.
String groupThousands(int major) {
  final digits = major.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
