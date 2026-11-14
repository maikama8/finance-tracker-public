import 'package:finance_tracker/features/transactions/domain/ledger_transaction.dart';
import 'package:finance_tracker/features/transactions/domain/recurring_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<DateTime> dates({
    required RecurrenceFrequency frequency,
    int interval = 1,
    required DateTime start,
    DateTime? end,
    DateTime? from,
    required DateTime until,
  }) {
    return RecurringSchedule.occurrences(
      frequency: frequency,
      interval: interval,
      startOn: start,
      endOn: end,
      from: from ?? start,
      until: until,
    );
  }

  test('weekly interval and an inclusive end date', () {
    final everyWeek = dates(
      frequency: RecurrenceFrequency.weekly,
      start: DateTime.utc(2026, 1, 1),
      until: DateTime.utc(2026, 1, 22),
    );
    expect(everyWeek, <DateTime>[
      DateTime.utc(2026, 1, 1),
      DateTime.utc(2026, 1, 8),
      DateTime.utc(2026, 1, 15),
      DateTime.utc(2026, 1, 22),
    ]);
    final everyTwo = dates(
      frequency: RecurrenceFrequency.weekly,
      interval: 2,
      start: DateTime.utc(2026, 1, 1),
      until: DateTime.utc(2026, 1, 29),
    );
    expect(everyTwo, <DateTime>[
      DateTime.utc(2026, 1, 1),
      DateTime.utc(2026, 1, 15),
      DateTime.utc(2026, 1, 29),
    ]);
    final ended = dates(
      frequency: RecurrenceFrequency.weekly,
      start: DateTime.utc(2026, 1, 1),
      end: DateTime.utc(2026, 1, 8),
      until: DateTime.utc(2026, 3, 1),
    );
    expect(ended, <DateTime>[
      DateTime.utc(2026, 1, 1),
      DateTime.utc(2026, 1, 8),
    ]);
  });

  test('monthly dates clamp in February and return to the anchor day', () {
    expect(
      dates(
        frequency: RecurrenceFrequency.monthly,
        start: DateTime.utc(2023, 1, 31),
        until: DateTime.utc(2023, 4, 30),
      ),
      <DateTime>[
        DateTime.utc(2023, 1, 31),
        DateTime.utc(2023, 2, 28),
        DateTime.utc(2023, 3, 31),
        DateTime.utc(2023, 4, 30),
      ],
    );
    expect(
      dates(
        frequency: RecurrenceFrequency.monthly,
        start: DateTime.utc(2024, 1, 31),
        until: DateTime.utc(2024, 3, 31),
      ),
      <DateTime>[
        DateTime.utc(2024, 1, 31),
        DateTime.utc(2024, 2, 29),
        DateTime.utc(2024, 3, 31),
      ],
    );
    expect(
      dates(
        frequency: RecurrenceFrequency.monthly,
        interval: 2,
        start: DateTime.utc(2026, 1, 15),
        until: DateTime.utc(2026, 7, 1),
      ),
      <DateTime>[
        DateTime.utc(2026, 1, 15),
        DateTime.utc(2026, 3, 15),
        DateTime.utc(2026, 5, 15),
      ],
    );
  });

  test('yearly 29 February clamps, then lands on the leap day again', () {
    expect(
      dates(
        frequency: RecurrenceFrequency.yearly,
        start: DateTime.utc(2024, 2, 29),
        until: DateTime.utc(2028, 3, 1),
      ),
      <DateTime>[
        DateTime.utc(2024, 2, 29),
        DateTime.utc(2025, 2, 28),
        DateTime.utc(2026, 2, 28),
        DateTime.utc(2027, 2, 28),
        DateTime.utc(2028, 2, 29),
      ],
    );
  });

  test('a window and a bad interval', () {
    final window = dates(
      frequency: RecurrenceFrequency.monthly,
      start: DateTime.utc(2026, 1, 1),
      from: DateTime.utc(2026, 3, 1),
      until: DateTime.utc(2026, 4, 1),
    );
    expect(window, <DateTime>[
      DateTime.utc(2026, 3, 1),
      DateTime.utc(2026, 4, 1),
    ]);
    expect(
      () => dates(
        frequency: RecurrenceFrequency.weekly,
        interval: 0,
        start: DateTime.utc(2026, 1, 1),
        until: DateTime.utc(2026, 1, 8),
      ),
      throwsArgumentError,
    );
  });

  test('materialize is idempotent and does not revive a deleted posting', () {
    final rule = RecurringRule(
      id: 'rule_salary',
      kind: TransactionKind.income,
      frequency: RecurrenceFrequency.monthly,
      interval: 1,
      startOn: DateTime.utc(2026, 6, 28),
      accountId: 'bank',
      categoryId: 'salary',
      amountMinor: 85000000,
      currencyCode: 'NGN',
      note: 'Salary',
    );
    final first = RecurringSchedule.materialize(
      rules: <RecurringRule>[rule],
      existingIds: <String>{},
      until: DateTime.utc(2026, 11, 14),
    );
    expect(first.created.map((txn) => txn.occurredOn.month), <int>[
      6,
      7,
      8,
      9,
      10,
    ]);
    expect(first.created.any((txn) => txn.occurredOn.month == 11), isFalse);
    expect(
      RecurringSchedule.nextAfter(rule, DateTime.utc(2026, 11, 14)),
      DateTime.utc(2026, 11, 28),
    );
    final again = RecurringSchedule.materialize(
      rules: first.rules,
      existingIds: first.created.map((txn) => txn.id).toSet(),
      until: DateTime.utc(2026, 11, 14),
    );
    expect(again.created, isEmpty);

    final withoutOctober = first.created
        .where((txn) => txn.occurredOn.month != 10)
        .map((txn) => txn.id)
        .toSet();
    final revived = RecurringSchedule.materialize(
      rules: first.rules,
      existingIds: withoutOctober,
      until: DateTime.utc(2026, 11, 14),
    );
    expect(revived.created, isEmpty);
  });
}
