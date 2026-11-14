import '../../../core/time/iso_date.dart';
import 'ledger_transaction.dart';

enum RecurrenceFrequency { weekly, monthly, yearly }

RecurrenceFrequency parseRecurrenceFrequency(String value) {
  return switch (value) {
    'weekly' => RecurrenceFrequency.weekly,
    'monthly' => RecurrenceFrequency.monthly,
    'yearly' => RecurrenceFrequency.yearly,
    _ => throw ArgumentError.value(value, 'value', 'unknown frequency'),
  };
}

extension RecurrenceFrequencyLabel on RecurrenceFrequency {
  String get storageName => switch (this) {
    RecurrenceFrequency.weekly => 'weekly',
    RecurrenceFrequency.monthly => 'monthly',
    RecurrenceFrequency.yearly => 'yearly',
  };

  String get label => switch (this) {
    RecurrenceFrequency.weekly => 'Weekly',
    RecurrenceFrequency.monthly => 'Monthly',
    RecurrenceFrequency.yearly => 'Yearly',
  };
}

/// A rule that posts a transaction on a schedule.
///
/// [lastMaterializedOn] is the latest date already considered. Later runs do
/// not recreate a deleted occurrence on or before that date.
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.kind,
    required this.frequency,
    required this.interval,
    required this.startOn,
    required this.accountId,
    required this.amountMinor,
    required this.currencyCode,
    required this.note,
    this.endOn,
    this.counterAccountId,
    this.categoryId,
    this.destinationAmountMinor,
    this.lastMaterializedOn,
    this.active = true,
  });

  final String id;
  final TransactionKind kind;
  final RecurrenceFrequency frequency;
  final int interval;
  final DateTime startOn;
  final DateTime? endOn;
  final String accountId;
  final String? counterAccountId;
  final String? categoryId;
  final int amountMinor;
  final int? destinationAmountMinor;
  final String currencyCode;
  final String note;
  final DateTime? lastMaterializedOn;
  final bool active;

  RecurringRule copyWith({
    bool? active,
    DateTime? lastMaterializedOn,
    bool clearLast = false,
    String? note,
    int? amountMinor,
  }) {
    return RecurringRule(
      id: id,
      kind: kind,
      frequency: frequency,
      interval: interval,
      startOn: startOn,
      endOn: endOn,
      accountId: accountId,
      counterAccountId: counterAccountId,
      categoryId: categoryId,
      amountMinor: amountMinor ?? this.amountMinor,
      destinationAmountMinor: destinationAmountMinor,
      currencyCode: currencyCode,
      note: note ?? this.note,
      lastMaterializedOn: clearLast
          ? null
          : lastMaterializedOn ?? this.lastMaterializedOn,
      active: active ?? this.active,
    );
  }
}

/// Dates a rule fires, and the transactions those dates become.
class RecurringSchedule {
  const RecurringSchedule._();

  static String transactionId(String ruleId, DateTime date) {
    final day = dateOnly(date);
    final month = day.month.toString().padLeft(2, '0');
    final dayText = day.day.toString().padLeft(2, '0');
    return 'txn_${ruleId}_${day.year}$month$dayText';
  }

  /// Occurrences whose calendar date is inside `[from, until]`, inclusive.
  ///
  /// Monthly and yearly dates keep the start day and clamp to the last day of
  /// a short month. 31 January steps to 28 or 29 February, then back to 31
  /// March. An [endOn] date is included. [interval] counts weeks, months, or
  /// years and must be at least 1.
  static List<DateTime> occurrences({
    required RecurrenceFrequency frequency,
    required int interval,
    required DateTime startOn,
    DateTime? endOn,
    required DateTime from,
    required DateTime until,
  }) {
    if (interval < 1) {
      throw ArgumentError.value(interval, 'interval', 'must be at least 1');
    }
    final start = dateOnly(startOn);
    final rangeFrom = dateOnly(from);
    final rangeUntil = dateOnly(until);
    final end = endOn == null ? null : dateOnly(endOn);
    if (rangeUntil.isBefore(rangeFrom)) return const <DateTime>[];

    if (frequency == RecurrenceFrequency.weekly) {
      return _weekly(
        start: start,
        interval: interval,
        rangeFrom: rangeFrom,
        rangeUntil: rangeUntil,
        end: end,
      );
    }
    final step = frequency == RecurrenceFrequency.yearly
        ? interval * 12
        : interval;
    return _stepMonths(
      start: start,
      stepMonths: step,
      rangeFrom: rangeFrom,
      rangeUntil: rangeUntil,
      end: end,
    );
  }

  /// The next occurrence strictly after [today], or null if the rule has ended.
  static DateTime? nextAfter(RecurringRule rule, DateTime today) {
    if (!rule.active) return null;
    final from = dateOnly(today).add(const Duration(days: 1));
    final horizon = DateTime.utc(from.year + 8, from.month, from.day);
    final dates = occurrences(
      frequency: rule.frequency,
      interval: rule.interval,
      startOn: rule.startOn,
      endOn: rule.endOn,
      from: from,
      until: horizon,
    );
    if (dates.isEmpty) return null;
    return dates.first;
  }

  static ScheduledPosting materialize({
    required List<RecurringRule> rules,
    required Set<String> existingIds,
    required DateTime until,
  }) {
    final seen = Set<String>.of(existingIds);
    final created = <LedgerTransaction>[];
    final updated = <RecurringRule>[];
    for (final rule in rules) {
      if (!rule.active) {
        updated.add(rule);
        continue;
      }
      final from = rule.lastMaterializedOn == null
          ? rule.startOn
          : dateOnly(rule.lastMaterializedOn!).add(const Duration(days: 1));
      final dates = occurrences(
        frequency: rule.frequency,
        interval: rule.interval,
        startOn: rule.startOn,
        endOn: rule.endOn,
        from: from,
        until: until,
      );
      var last = rule.lastMaterializedOn == null
          ? null
          : dateOnly(rule.lastMaterializedOn!);
      for (final date in dates) {
        final id = transactionId(rule.id, date);
        if (seen.add(id)) {
          created.add(_post(rule, date, id));
        }
        if (last == null || date.isAfter(last)) last = date;
      }
      updated.add(rule.copyWith(lastMaterializedOn: last));
    }
    return ScheduledPosting(created: created, rules: updated);
  }

  static LedgerTransaction _post(RecurringRule rule, DateTime date, String id) {
    return LedgerTransaction(
      id: id,
      kind: rule.kind,
      accountId: rule.accountId,
      counterAccountId: rule.counterAccountId,
      categoryId: rule.categoryId,
      amountMinor: rule.amountMinor,
      destinationAmountMinor: rule.destinationAmountMinor,
      currencyCode: rule.currencyCode,
      occurredOn: date,
      note: rule.note,
      recurringRuleId: rule.id,
    );
  }

  static List<DateTime> _weekly({
    required DateTime start,
    required int interval,
    required DateTime rangeFrom,
    required DateTime rangeUntil,
    required DateTime? end,
  }) {
    final results = <DateTime>[];
    var date = start;
    while (date.year < 10000) {
      if (end != null && date.isAfter(end)) break;
      if (date.isAfter(rangeUntil)) break;
      if (!date.isBefore(rangeFrom)) results.add(date);
      date = DateTime.utc(date.year, date.month, date.day + 7 * interval);
    }
    return results;
  }

  static List<DateTime> _stepMonths({
    required DateTime start,
    required int stepMonths,
    required DateTime rangeFrom,
    required DateTime rangeUntil,
    required DateTime? end,
  }) {
    final results = <DateTime>[];
    final anchorDay = start.day;
    var year = start.year;
    var month = start.month;
    while (year < 10000) {
      final date = _clamped(year, month, anchorDay);
      if (end != null && date.isAfter(end)) break;
      if (!date.isBefore(start) && date.isAfter(rangeUntil)) break;
      if (!date.isBefore(start) &&
          !date.isBefore(rangeFrom) &&
          !date.isAfter(rangeUntil)) {
        results.add(date);
      }
      final absolute = year * 12 + (month - 1) + stepMonths;
      year = absolute ~/ 12;
      month = absolute % 12 + 1;
    }
    return results;
  }

  static DateTime _clamped(int year, int month, int anchorDay) {
    final lastDay = DateTime.utc(year, month + 1, 0).day;
    final day = anchorDay > lastDay ? lastDay : anchorDay;
    return DateTime.utc(year, month, day);
  }
}

class ScheduledPosting {
  const ScheduledPosting({required this.created, required this.rules});

  final List<LedgerTransaction> created;
  final List<RecurringRule> rules;
}
