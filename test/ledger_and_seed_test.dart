import 'package:finance_tracker/core/currency/mock_exchange_rate_service.dart';
import 'package:finance_tracker/core/formatting/money_format.dart';
import 'package:finance_tracker/data/memory_ledger_repository.dart';
import 'package:finance_tracker/features/accounts/domain/account.dart';
import 'package:finance_tracker/features/budgets/domain/budget_engine.dart';
import 'package:finance_tracker/features/dashboard/domain/ledger_report.dart';
import 'package:finance_tracker/features/import_export/domain/csv_ledger.dart';
import 'package:finance_tracker/features/ledger/domain/ledger_snapshot.dart';
import 'package:finance_tracker/features/budgets/domain/category_budget.dart';
import 'package:finance_tracker/features/settings/domain/app_settings.dart';
import 'package:finance_tracker/features/transactions/domain/recurring_rule.dart';
import 'package:finance_tracker/features/transactions/domain/category.dart';
import 'package:finance_tracker/features/transactions/domain/ledger_transaction.dart';
import 'package:finance_tracker/data/seed/seed_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rates = MockExchangeRateService();
  final today = DateTime.utc(2026, 11, 14);

  Future<LedgerSnapshot> book() async {
    final repo = MemoryLedgerRepository();
    await repo.ensureSeeded(today);
    await repo.materializeRecurring(today);
    await repo.materializeRecurring(today);
    return repo.load();
  }

  test('the seeded November book is over only on food and airtime', () async {
    final snapshot = await book();
    final codes = snapshot.accounts
        .map((account) => account.currencyCode)
        .toSet();
    expect(codes, containsAll(<String>['NGN', 'USD', 'GBP', 'GHS', 'KES']));
    expect(
      snapshot.accounts.map((account) => account.name),
      containsAll(<String>[
        'OPay Everyday',
        'Moniepoint Business',
        'GTBank Salary',
      ]),
    );
    expect(
      snapshot.transactions.where(
        (txn) => txn.recurringRuleId == SeedData.ruleSalary,
      ),
      hasLength(5),
    );
    expect(
      snapshot.transactions.where(
        (txn) => txn.recurringRuleId == SeedData.ruleRent,
      ),
      hasLength(6),
    );
    expect(
      snapshot.transactions.where(
        (txn) =>
            txn.recurringRuleId == SeedData.ruleSalary &&
            txn.occurredOn.month == 11,
      ),
      isEmpty,
    );

    final figures = DashboardFigures.compose(
      accounts: snapshot.accounts,
      categories: snapshot.categories,
      transactions: snapshot.transactions,
      budgets: snapshot.budgets,
      rates: rates,
      baseCurrency: 'NGN',
      today: today,
    );
    expect(figures.alerts.map((alert) => alert.categoryId).toSet(), <String>{
      SeedData.food,
      SeedData.airtime,
    });
    final food = figures.budgets.firstWhere(
      (item) => item.categoryId == SeedData.food,
    );
    final airtime = figures.budgets.firstWhere(
      (item) => item.categoryId == SeedData.airtime,
    );
    final rent = figures.budgets.firstWhere(
      (item) => item.categoryId == SeedData.rent,
    );
    expect(food.spentMinor, parseMoneyInput('105200'));
    expect(airtime.spentMinor, parseMoneyInput('16000'));
    expect(rent.remainingMinor, 0);
    expect(rent.isOver, isFalse);
    expect(figures.month.incomeMinor, parseMoneyInput('352000'));
    expect(figures.month.expenseMinor, parseMoneyInput('441050'));
    expect(figures.month.netMinor, -8905000);
    expect(figures.netWorthMinor, parseMoneyInput('4420050'));
    expect(figures.trend, hasLength(6));
    expect(figures.netWorth, hasLength(6));

    for (final point in figures.netWorth) {
      if (point.month.month == 11) continue;
      final monthBudgets = BudgetEngine.progress(
        budgets: snapshot.budgets,
        categories: snapshot.categories,
        transactions: snapshot.transactions,
        rates: rates,
        baseCurrency: 'NGN',
        year: point.month.year,
        month: point.month.month,
      );
      expect(
        monthBudgets.where((item) => item.isOver),
        isEmpty,
        reason: 'month ${point.month.month}',
      );
    }
  });

  test('balances keep transfers and foreign cash in their own currency', () {
    final gtbank = Account(
      id: 'ngn',
      name: 'Bank',
      kind: AccountKind.bank,
      currencyCode: 'NGN',
      openingBalanceMinor: 1000000,
      color: 1,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final usd = Account(
      id: 'usd',
      name: 'USD',
      kind: AccountKind.cash,
      currencyCode: 'USD',
      openingBalanceMinor: 0,
      color: 1,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final txns = <LedgerTransaction>[
      LedgerTransaction(
        id: 'in',
        kind: TransactionKind.income,
        accountId: 'ngn',
        categoryId: 'salary',
        amountMinor: 500000,
        currencyCode: 'NGN',
        occurredOn: DateTime.utc(2026, 11, 1),
        note: '',
      ),
      LedgerTransaction(
        id: 'out',
        kind: TransactionKind.expense,
        accountId: 'ngn',
        categoryId: 'food',
        amountMinor: 200000,
        currencyCode: 'NGN',
        occurredOn: DateTime.utc(2026, 11, 2),
        note: '',
      ),
      LedgerTransaction(
        id: 'move',
        kind: TransactionKind.transfer,
        accountId: 'usd',
        counterAccountId: 'ngn',
        amountMinor: 10000,
        destinationAmountMinor: 16000000,
        currencyCode: 'USD',
        occurredOn: DateTime.utc(2026, 11, 3),
        note: '',
      ),
    ];
    expect(
      LedgerReport.balanceMinor(gtbank, txns),
      1000000 + 500000 - 200000 + 16000000,
    );
    expect(LedgerReport.balanceMinor(usd, txns), -10000);
    final worth = LedgerReport.netWorthMinor(
      accounts: <Account>[gtbank, usd],
      transactions: txns,
      rates: rates,
      baseCurrency: 'NGN',
    );
    // USD balance -10000 cents is -₦160,000, which cancels the posted naira.
    expect(worth, 1000000 + 500000 - 200000);
    final flow = LedgerReport.cashFlow(
      transactions: txns,
      rates: rates,
      baseCurrency: 'NGN',
      year: 2026,
      month: 11,
    );
    expect(flow.incomeMinor, 500000);
    expect(flow.expenseMinor, 200000);
  });

  test(
    'csv round trip keeps a comma in the note and reports a bad row',
    () async {
      final snapshot = LedgerSnapshot(
        settings: const AppSettings(seeded: true),
        accounts: <Account>[
          Account(
            id: 'a',
            name: 'GTBank Salary',
            kind: AccountKind.bank,
            currencyCode: 'NGN',
            openingBalanceMinor: 0,
            color: 1,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        categories: const <Category>[
          Category(
            id: 'food',
            name: 'Food',
            kind: CategoryKind.expense,
            color: 1,
            iconKey: 'food',
          ),
        ],
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'txn_1',
            kind: TransactionKind.expense,
            accountId: 'a',
            categoryId: 'food',
            amountMinor: 2840000,
            currencyCode: 'NGN',
            occurredOn: DateTime.utc(2026, 11, 2),
            note: 'Lunch, Ikeja',
          ),
        ],
        rules: const <RecurringRule>[],
        budgets: const <CategoryBudget>[],
      );
      final csv = CsvLedger.export(snapshot);
      expect(csv, contains('"Lunch, Ikeja"'));
      final repo = MemoryLedgerRepository();
      final plan = await repo.importCsv(
        '$csv\nbogus,not-a-date,expense,Cash,NGN,10,Food,Nope,,\n'
        'txn_new,2026-11-03,expense,Cash wallet,NGN,1500.00,Transport,BRT,,\n',
        today: today,
        newId: (prefix) => '${prefix}_test',
      );
      expect(plan.imported, 2);
      expect(plan.skipped, 0);
      expect(plan.errors, hasLength(1));
      expect(
        plan.accounts.map((account) => account.name),
        contains('Cash wallet'),
      );
      expect(
        plan.categories.map((category) => category.name),
        contains('Transport'),
      );
      final loaded = await repo.load();
      final lunch = loaded.transactions.firstWhere((txn) => txn.id == 'txn_1');
      expect(lunch.note, 'Lunch, Ikeja');
      expect(lunch.amountMinor, 2840000);
    },
  );
}
