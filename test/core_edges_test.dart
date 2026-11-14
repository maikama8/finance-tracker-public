import 'package:finance_tracker/core/currency/currency.dart';
import 'package:finance_tracker/core/formatting/money_format.dart';
import 'package:finance_tracker/core/navigation/launch_location.dart';
import 'package:finance_tracker/core/theme/theme_preference.dart';
import 'package:finance_tracker/core/time/iso_date.dart';
import 'package:finance_tracker/features/accounts/domain/account.dart';
import 'package:finance_tracker/features/dashboard/presentation/chart_scale.dart';
import 'package:finance_tracker/features/import_export/domain/csv_ledger.dart';
import 'package:finance_tracker/features/ledger/domain/ledger_snapshot.dart';
import 'package:finance_tracker/features/transactions/domain/category.dart';
import 'package:finance_tracker/features/transactions/domain/ledger_transaction.dart';
import 'package:finance_tracker/features/transactions/domain/recurring_rule.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compact labels, shares, and editable amounts', () {
    expect(formatCompactMinor(160000000, 'NGN'), '₦1.6m');
    expect(formatCompactMinor(1600000000, 'NGN'), '₦16m');
    expect(formatCompactMinor(5000000, 'NGN'), '₦50k');
    expect(formatAxisAmount(0, 'NGN'), '₦0');
    expect(formatShare(105200, 90000), '116.8%');
    expect(formatShare(16000, 12000), '133.3%');
    expect(formatShare(180000, 180000), '100.0%');
    expect(formatShare(10, 0), '100%+');
    expect(groupThousands(1600), '1,600');
    expect(groupThousands(0), '0');
    expect(formatEditableAmount(160050), '1600.50');
    expect(formatEditableAmount(-150), '-1.50');
    expect(formatShortDate(DateTime.utc(2026, 11, 14)), '14 Nov 2026');
    expect(formatMonthYear(2026, 11), 'November 2026');
  });

  test('dates reject impossible days and cross the year', () {
    expect(formatIsoDate(DateTime.utc(2026, 2, 3)), '2026-02-03');
    expect(() => parseIsoDate('2026-02-31'), throwsFormatException);
    expect(() => parseIsoDate('14 Nov 2026'), throwsFormatException);
    expect(trailingMonths(DateTime.utc(2026, 1, 15), 3), <DateTime>[
      DateTime.utc(2025, 11, 1),
      DateTime.utc(2025, 12, 1),
      DateTime.utc(2026, 1, 1),
    ]);
    expect(monthEnd(2024, 2), DateTime.utc(2024, 2, 29));
  });

  test('launch paths and themes round trip', () {
    expect(parseThemePreference('system'), ThemePreference.system);
    expect(() => parseThemePreference('sepia'), throwsArgumentError);

    final budgets = parseLaunchLocation('/budgets?theme=dark');
    expect(budgets.tab, 2);
    expect(budgets.themeOverride, ThemePreference.dark);
    expect(parseLaunchLocation('/transactions').tab, 1);
    expect(parseLaunchLocation('/nope').tab, 0);
    expect(
      parseLaunchLocation('/settings?theme=light').themeOverride,
      ThemePreference.light,
    );
    expect(pathForTab(4), '/settings');
    expect(pathForTab(9), '/dashboard');
  });

  test('activity filters match notes, transfers, and dates', () {
    final accounts = <Account>[
      Account(
        id: 'a',
        name: 'GTBank Salary',
        kind: AccountKind.bank,
        currencyCode: 'NGN',
        openingBalanceMinor: 0,
        color: 1,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      Account(
        id: 'b',
        name: 'OPay Everyday',
        kind: AccountKind.mobileMoney,
        currencyCode: 'NGN',
        openingBalanceMinor: 0,
        color: 1,
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    ];
    const food = Category(
      id: 'food',
      name: 'Food',
      kind: CategoryKind.expense,
      color: 1,
      iconKey: 'food',
    );
    final transactions = <LedgerTransaction>[
      LedgerTransaction(
        id: 'older',
        kind: TransactionKind.expense,
        accountId: 'a',
        categoryId: 'food',
        amountMinor: 450000,
        currencyCode: 'NGN',
        occurredOn: DateTime.utc(2026, 11, 2),
        note: 'Lunch, Ikeja',
      ),
      LedgerTransaction(
        id: 'newer',
        kind: TransactionKind.transfer,
        accountId: 'a',
        counterAccountId: 'b',
        amountMinor: 800000,
        destinationAmountMinor: 800000,
        currencyCode: 'NGN',
        occurredOn: DateTime.utc(2026, 11, 13),
        note: 'Friday cleaner',
      ),
    ];

    final byNote = filterTransactions(
      transactions: transactions,
      accounts: accounts,
      categories: const <Category>[food],
      query: const TransactionQuery(text: 'ikeja'),
    );
    expect(byNote.map((txn) => txn.id), <String>['older']);

    final byDestination = filterTransactions(
      transactions: transactions,
      accounts: accounts,
      categories: const <Category>[food],
      query: const TransactionQuery(accountId: 'b'),
    );
    expect(byDestination.map((txn) => txn.id), <String>['newer']);

    final byDate = filterTransactions(
      transactions: transactions,
      accounts: accounts,
      categories: const <Category>[food],
      query: TransactionQuery(
        from: DateTime.utc(2026, 11, 10),
        to: DateTime.utc(2026, 11, 14),
      ),
    );
    expect(byDate.map((txn) => txn.id), <String>['newer']);
    expect(byDate.first.id, 'newer');

    const faceted = TransactionQuery(accountId: 'a', text: 'lunch');
    expect(faceted.isNarrowed, isTrue);
    expect(faceted.hasFacet, isTrue);
    expect(const TransactionQuery(text: 'lunch').hasFacet, isFalse);
  });

  test('chart scales land on round steps above the data', () {
    final cash = ChartScale.fromZero(1520000);
    expect(cash.min, 0);
    expect(cash.step, 500000);
    expect(cash.max, 2000000);
    expect(cash.max, greaterThan(1520000));

    final exact = ChartScale.fromZero(2000000);
    expect(exact.max, greaterThan(2000000));
    expect(exact.max % exact.step, 0);

    final worth = ChartScale.around(1300000, 4420050);
    expect(worth.step, 1000000);
    expect(worth.min, lessThanOrEqualTo(1300000));
    expect(worth.max, greaterThan(4420050));
    expect(ChartScale.fromZero(0).max, 1);
  });

  test('materialization compares cursors, not list order', () {
    RecurringRule rule(String id, DateTime? cursor) {
      return RecurringRule(
        id: id,
        kind: TransactionKind.expense,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startOn: DateTime.utc(2026, 1, 1),
        accountId: 'a',
        amountMinor: 100,
        currencyCode: Currencies.defaultBase,
        note: '',
        lastMaterializedOn: cursor,
      );
    }

    final first = <RecurringRule>[
      rule('rent', DateTime.utc(2026, 11, 1)),
      rule('salary', DateTime.utc(2026, 10, 28)),
    ];
    final reordered = <RecurringRule>[first[1], first[0]];
    expect(RecurringSchedule.materializationChanged(first, reordered), isFalse);
    expect(
      RecurringSchedule.materializationChanged(first, <RecurringRule>[
        rule('rent', DateTime.utc(2026, 12, 1)),
        first[1],
      ]),
      isTrue,
    );
    expect(
      RecurringSchedule.materializationChanged(first, <RecurringRule>[
        first[0],
      ]),
      isTrue,
    );
  });

  test('csv reports an empty file, a broken quote, and a duplicate id', () {
    final current = LedgerSnapshot(
      settings: LedgerSnapshot.empty().settings,
      accounts: const <Account>[],
      categories: const <Category>[],
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'txn_1',
          kind: TransactionKind.expense,
          accountId: 'missing',
          amountMinor: 100,
          currencyCode: 'NGN',
          occurredOn: DateTime.utc(2026, 11, 1),
          note: '',
        ),
      ],
      rules: const <RecurringRule>[],
      budgets: LedgerSnapshot.empty().budgets,
    );
    String id(String prefix) => '${prefix}_new';

    final empty = CsvLedger.parse(
      '',
      current: current,
      now: DateTime.utc(2026, 11, 14),
      newId: id,
    );
    expect(empty.errors, isNotEmpty);
    expect(empty.imported, 0);

    final broken = CsvLedger.parse(
      '"id',
      current: current,
      now: DateTime.utc(2026, 11, 14),
      newId: id,
    );
    expect(broken.errors.single.line, 1);

    final duplicate = CsvLedger.parse(
      '${CsvLedger.header.join(',')}\n'
      'txn_1,2026-11-02,expense,Cash,NGN,10.00,Food,Again,,\n',
      current: current,
      now: DateTime.utc(2026, 11, 14),
      newId: id,
    );
    expect(duplicate.skipped, 1);
    expect(duplicate.imported, 0);
  });
}
