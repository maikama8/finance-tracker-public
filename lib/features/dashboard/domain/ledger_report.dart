import '../../../core/currency/exchange_rate_service.dart';
import '../../../core/time/iso_date.dart';
import '../../accounts/domain/account.dart';
import '../../budgets/domain/budget_engine.dart';
import '../../budgets/domain/category_budget.dart';
import '../../transactions/domain/category.dart';
import '../../transactions/domain/ledger_transaction.dart';

class MonthCashFlow {
  const MonthCashFlow({
    required this.month,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final DateTime month;
  final int incomeMinor;
  final int expenseMinor;

  int get netMinor => incomeMinor - expenseMinor;
}

class CategorySpend {
  const CategorySpend({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.iconKey,
    required this.spentMinor,
  });

  final String categoryId;
  final String name;
  final int color;
  final String iconKey;
  final int spentMinor;
}

class NetWorthPoint {
  const NetWorthPoint({required this.month, required this.minor});

  /// The first day of the month this point closes.
  final DateTime month;

  /// Net worth in the base currency at the end of [month], or today when
  /// the month is still open.
  final int minor;
}

/// Pure balance, cash-flow, and net-worth math.
///
/// Account balances stay in the account currency. A base-currency total
/// converts those balances with the active rate table. Transfers move money
/// between accounts and are not income or spending.
class LedgerReport {
  const LedgerReport._();

  static int balanceMinor(
    Account account,
    Iterable<LedgerTransaction> transactions, {
    DateTime? asOf,
  }) {
    final cutoff = asOf == null ? null : dateOnly(asOf);
    var total = account.openingBalanceMinor;
    for (final txn in transactions) {
      if (cutoff != null && dateOnly(txn.occurredOn).isAfter(cutoff)) continue;
      if (txn.accountId == account.id) {
        switch (txn.kind) {
          case TransactionKind.income:
            total += txn.amountMinor;
          case TransactionKind.expense:
          case TransactionKind.transfer:
            total -= txn.amountMinor;
        }
      }
      if (txn.kind == TransactionKind.transfer &&
          txn.counterAccountId == account.id) {
        total += txn.destinationAmountMinor ?? txn.amountMinor;
      }
    }
    return total;
  }

  static int netWorthMinor({
    required List<Account> accounts,
    required List<LedgerTransaction> transactions,
    required ExchangeRateService rates,
    required String baseCurrency,
    DateTime? asOf,
  }) {
    var total = 0;
    for (final account in accounts) {
      final native = balanceMinor(account, transactions, asOf: asOf);
      total += rates.convertMinor(
        amountMinor: native,
        from: account.currencyCode,
        to: baseCurrency,
      );
    }
    return total;
  }

  static MonthCashFlow cashFlow({
    required List<LedgerTransaction> transactions,
    required ExchangeRateService rates,
    required String baseCurrency,
    required int year,
    required int month,
  }) {
    var income = 0;
    var expense = 0;
    for (final txn in transactions) {
      if (!sameMonth(txn.occurredOn, year, month)) continue;
      final converted = rates.convertMinor(
        amountMinor: txn.amountMinor,
        from: txn.currencyCode,
        to: baseCurrency,
      );
      switch (txn.kind) {
        case TransactionKind.income:
          income += converted;
        case TransactionKind.expense:
          expense += converted;
        case TransactionKind.transfer:
          break;
      }
    }
    return MonthCashFlow(
      month: monthStart(year, month),
      incomeMinor: income,
      expenseMinor: expense,
    );
  }

  static List<CategorySpend> spendingByCategory({
    required List<Category> categories,
    required List<LedgerTransaction> transactions,
    required ExchangeRateService rates,
    required String baseCurrency,
    required int year,
    required int month,
  }) {
    final spends = <CategorySpend>[];
    for (final category in categories) {
      if (category.kind != CategoryKind.expense) continue;
      final spent = BudgetEngine.spentMinor(
        categoryId: category.id,
        transactions: transactions,
        rates: rates,
        baseCurrency: baseCurrency,
        year: year,
        month: month,
      );
      if (spent == 0) continue;
      spends.add(
        CategorySpend(
          categoryId: category.id,
          name: category.name,
          color: category.color,
          iconKey: category.iconKey,
          spentMinor: spent,
        ),
      );
    }
    spends.sort((a, b) => b.spentMinor.compareTo(a.spentMinor));
    return spends;
  }

  static List<MonthCashFlow> trend({
    required List<LedgerTransaction> transactions,
    required ExchangeRateService rates,
    required String baseCurrency,
    required DateTime today,
    int months = 6,
  }) {
    return <MonthCashFlow>[
      for (final month in trailingMonths(today, months))
        cashFlow(
          transactions: transactions,
          rates: rates,
          baseCurrency: baseCurrency,
          year: month.year,
          month: month.month,
        ),
    ];
  }

  static List<NetWorthPoint> netWorthSeries({
    required List<Account> accounts,
    required List<LedgerTransaction> transactions,
    required ExchangeRateService rates,
    required String baseCurrency,
    required DateTime today,
    int months = 6,
  }) {
    final current = dateOnly(today);
    return <NetWorthPoint>[
      for (final month in trailingMonths(current, months))
        NetWorthPoint(
          month: month,
          minor: netWorthMinor(
            accounts: accounts,
            transactions: transactions,
            rates: rates,
            baseCurrency: baseCurrency,
            asOf: _closeOf(month, current),
          ),
        ),
    ];
  }

  static DateTime _closeOf(DateTime month, DateTime today) {
    final last = monthEnd(month.year, month.month);
    if (last.isAfter(today)) return today;
    return last;
  }
}

class DashboardFigures {
  const DashboardFigures({
    required this.baseCurrency,
    required this.today,
    required this.netWorthMinor,
    required this.month,
    required this.spending,
    required this.trend,
    required this.netWorth,
    required this.budgets,
  });

  final String baseCurrency;
  final DateTime today;
  final int netWorthMinor;
  final MonthCashFlow month;
  final List<CategorySpend> spending;
  final List<MonthCashFlow> trend;
  final List<NetWorthPoint> netWorth;
  final List<BudgetSnapshot> budgets;

  List<BudgetSnapshot> get alerts =>
      budgets.where((budget) => budget.isOver).toList(growable: false);

  static DashboardFigures compose({
    required List<Account> accounts,
    required List<Category> categories,
    required List<LedgerTransaction> transactions,
    required List<CategoryBudget> budgets,
    required ExchangeRateService rates,
    required String baseCurrency,
    required DateTime today,
  }) {
    final day = dateOnly(today);
    return DashboardFigures(
      baseCurrency: baseCurrency,
      today: day,
      netWorthMinor: LedgerReport.netWorthMinor(
        accounts: accounts,
        transactions: transactions,
        rates: rates,
        baseCurrency: baseCurrency,
        asOf: day,
      ),
      month: LedgerReport.cashFlow(
        transactions: transactions,
        rates: rates,
        baseCurrency: baseCurrency,
        year: day.year,
        month: day.month,
      ),
      spending: LedgerReport.spendingByCategory(
        categories: categories,
        transactions: transactions,
        rates: rates,
        baseCurrency: baseCurrency,
        year: day.year,
        month: day.month,
      ),
      trend: LedgerReport.trend(
        transactions: transactions,
        rates: rates,
        baseCurrency: baseCurrency,
        today: day,
      ),
      netWorth: LedgerReport.netWorthSeries(
        accounts: accounts,
        transactions: transactions,
        rates: rates,
        baseCurrency: baseCurrency,
        today: day,
      ),
      budgets: BudgetEngine.progress(
        budgets: budgets,
        categories: categories,
        transactions: transactions,
        rates: rates,
        baseCurrency: baseCurrency,
        year: day.year,
        month: day.month,
      ),
    );
  }
}
