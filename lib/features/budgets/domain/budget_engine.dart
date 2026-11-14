import '../../../core/currency/exchange_rate_service.dart';
import '../../../core/time/iso_date.dart';
import '../../transactions/domain/category.dart';
import '../../transactions/domain/ledger_transaction.dart';
import 'category_budget.dart';

/// How a category budget stands for one calendar month.
class BudgetSnapshot {
  const BudgetSnapshot({
    required this.budgetId,
    required this.categoryId,
    required this.categoryName,
    required this.color,
    required this.iconKey,
    required this.limitMinor,
    required this.spentMinor,
    required this.baseCurrency,
  });

  final String budgetId;
  final String categoryId;
  final String categoryName;
  final int color;
  final String iconKey;

  /// Limit and spend are both in [baseCurrency] minor units.
  final int limitMinor;
  final int spentMinor;
  final String baseCurrency;

  bool get isOver => spentMinor > limitMinor;

  int get remainingMinor => limitMinor - spentMinor;

  /// 0 when nothing is spent. Above 1 when the category is over.
  /// A zero limit with any spend is treated as full.
  double get ratio {
    if (limitMinor <= 0) return spentMinor > 0 ? 1 : 0;
    return spentMinor / limitMinor;
  }
}

/// Monthly category budgets.
///
/// Only expenses count. Income and transfers do not. Foreign amounts are
/// converted with the active [ExchangeRateService] at read time.
class BudgetEngine {
  const BudgetEngine._();

  static int spentMinor({
    required String categoryId,
    required List<LedgerTransaction> transactions,
    required ExchangeRateService rates,
    required String baseCurrency,
    required int year,
    required int month,
  }) {
    var total = 0;
    for (final txn in transactions) {
      if (txn.kind != TransactionKind.expense) continue;
      if (txn.categoryId != categoryId) continue;
      if (!sameMonth(txn.occurredOn, year, month)) continue;
      total += rates.convertMinor(
        amountMinor: txn.amountMinor,
        from: txn.currencyCode,
        to: baseCurrency,
      );
    }
    return total;
  }

  static List<BudgetSnapshot> progress({
    required List<CategoryBudget> budgets,
    required List<Category> categories,
    required List<LedgerTransaction> transactions,
    required ExchangeRateService rates,
    required String baseCurrency,
    required int year,
    required int month,
  }) {
    final byId = <String, Category>{
      for (final category in categories) category.id: category,
    };
    final latest = <String, CategoryBudget>{};
    for (final budget in budgets) {
      latest[budget.categoryId] = budget;
    }
    final snapshots = <BudgetSnapshot>[];
    for (final budget in latest.values) {
      final category = byId[budget.categoryId];
      final spent = spentMinor(
        categoryId: budget.categoryId,
        transactions: transactions,
        rates: rates,
        baseCurrency: baseCurrency,
        year: year,
        month: month,
      );
      snapshots.add(
        BudgetSnapshot(
          budgetId: budget.id,
          categoryId: budget.categoryId,
          categoryName: category?.name ?? 'Category',
          color: category?.color ?? 0xFF5E6A64,
          iconKey: category?.iconKey ?? 'other',
          limitMinor: rates.convertMinor(
            amountMinor: budget.limitMinor,
            from: budget.currencyCode,
            to: baseCurrency,
          ),
          spentMinor: spent,
          baseCurrency: baseCurrency,
        ),
      );
    }
    snapshots.sort((a, b) {
      if (a.isOver != b.isOver) return a.isOver ? -1 : 1;
      final byRatio = b.ratio.compareTo(a.ratio);
      if (byRatio != 0) return byRatio;
      return a.categoryName.compareTo(b.categoryName);
    });
    return snapshots;
  }
}
