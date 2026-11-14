import '../../accounts/domain/account.dart';
import '../../budgets/domain/category_budget.dart';
import '../../settings/domain/app_settings.dart';
import '../../transactions/domain/category.dart';
import '../../transactions/domain/ledger_transaction.dart';
import '../../transactions/domain/recurring_rule.dart';

/// The whole book, as the screens and the pure reports see it.
class LedgerSnapshot {
  const LedgerSnapshot({
    required this.settings,
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.rules,
    required this.budgets,
  });

  factory LedgerSnapshot.empty() {
    return const LedgerSnapshot(
      settings: AppSettings(),
      accounts: <Account>[],
      categories: <Category>[],
      transactions: <LedgerTransaction>[],
      rules: <RecurringRule>[],
      budgets: <CategoryBudget>[],
    );
  }

  final AppSettings settings;
  final List<Account> accounts;
  final List<Category> categories;
  final List<LedgerTransaction> transactions;
  final List<RecurringRule> rules;
  final List<CategoryBudget> budgets;

  Account? accountById(String id) {
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  Category? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Account? accountByName(String name) {
    for (final account in accounts) {
      if (account.name == name) return account;
    }
    return null;
  }

  Category? categoryByName(String name) {
    for (final category in categories) {
      if (category.name == name) return category;
    }
    return null;
  }
}
