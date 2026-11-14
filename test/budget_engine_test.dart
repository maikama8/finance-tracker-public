import 'package:finance_tracker/core/currency/mock_exchange_rate_service.dart';
import 'package:finance_tracker/features/budgets/domain/budget_engine.dart';
import 'package:finance_tracker/features/budgets/domain/category_budget.dart';
import 'package:finance_tracker/features/transactions/domain/category.dart';
import 'package:finance_tracker/features/transactions/domain/ledger_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rates = MockExchangeRateService();
  const food = Category(
    id: 'food',
    name: 'Food',
    kind: CategoryKind.expense,
    color: 1,
    iconKey: 'food',
  );
  const salary = Category(
    id: 'salary',
    name: 'Salary',
    kind: CategoryKind.income,
    color: 2,
    iconKey: 'salary',
  );

  LedgerTransaction txn({
    required String id,
    required TransactionKind kind,
    required int amount,
    required DateTime date,
    String category = 'food',
    String currency = 'NGN',
  }) {
    return LedgerTransaction(
      id: id,
      kind: kind,
      accountId: 'a',
      categoryId: category,
      amountMinor: amount,
      currencyCode: currency,
      occurredOn: date,
      note: '',
    );
  }

  List<BudgetSnapshot> progress(
    List<LedgerTransaction> transactions, {
    int limit = 9000000,
  }) {
    return BudgetEngine.progress(
      budgets: <CategoryBudget>[
        CategoryBudget(
          id: 'b',
          categoryId: 'food',
          limitMinor: limit,
          currencyCode: 'NGN',
        ),
      ],
      categories: const <Category>[food, salary],
      transactions: transactions,
      rates: rates,
      baseCurrency: 'NGN',
      year: 2026,
      month: 11,
    );
  }

  test('under, exact, and over', () {
    final under = progress(<LedgerTransaction>[
      txn(
        id: '1',
        kind: TransactionKind.expense,
        amount: 1000000,
        date: DateTime.utc(2026, 11, 2),
      ),
    ]).single;
    expect(under.isOver, isFalse);
    expect(under.remainingMinor, 8000000);

    final exact = progress(<LedgerTransaction>[
      txn(
        id: '1',
        kind: TransactionKind.expense,
        amount: 9000000,
        date: DateTime.utc(2026, 11, 2),
      ),
    ]).single;
    expect(exact.isOver, isFalse);
    expect(exact.ratio, 1);

    final over = progress(<LedgerTransaction>[
      txn(
        id: '1',
        kind: TransactionKind.expense,
        amount: 10520000,
        date: DateTime.utc(2026, 11, 2),
      ),
    ]).single;
    expect(over.isOver, isTrue);
    expect(over.remainingMinor, -1520000);
  });

  test('ignores other months, income, and transfers', () {
    final snapshot = progress(<LedgerTransaction>[
      txn(
        id: '1',
        kind: TransactionKind.expense,
        amount: 500000,
        date: DateTime.utc(2026, 10, 2),
      ),
      txn(
        id: '2',
        kind: TransactionKind.income,
        amount: 8000000,
        date: DateTime.utc(2026, 11, 2),
        category: 'salary',
      ),
      LedgerTransaction(
        id: '3',
        kind: TransactionKind.transfer,
        accountId: 'a',
        counterAccountId: 'b',
        categoryId: 'food',
        amountMinor: 9000000,
        destinationAmountMinor: 9000000,
        currencyCode: 'NGN',
        occurredOn: DateTime.utc(2026, 11, 3),
        note: '',
      ),
      txn(
        id: '4',
        kind: TransactionKind.expense,
        amount: 100,
        date: DateTime.utc(2026, 11, 4),
      ),
    ]).single;
    expect(snapshot.spentMinor, 100);
    expect(snapshot.isOver, isFalse);
  });

  test('converts a foreign expense into the naira budget', () {
    final snapshot = progress(<LedgerTransaction>[
      txn(
        id: 'usd',
        kind: TransactionKind.expense,
        amount: 1000,
        date: DateTime.utc(2026, 11, 4),
        currency: 'USD',
      ),
    ]).single;
    expect(snapshot.spentMinor, 1600000);
  });

  test('a zero limit is over only when something was spent', () {
    final quiet = progress(const <LedgerTransaction>[], limit: 0).single;
    expect(quiet.isOver, isFalse);
    expect(quiet.ratio, 0);
    final spent = progress(<LedgerTransaction>[
      txn(
        id: '1',
        kind: TransactionKind.expense,
        amount: 1,
        date: DateTime.utc(2026, 11, 1),
      ),
    ], limit: 0).single;
    expect(spent.isOver, isTrue);
    expect(spent.ratio, 1);
  });
}
