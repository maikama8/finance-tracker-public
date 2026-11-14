import '../features/accounts/domain/account.dart';
import '../features/budgets/domain/category_budget.dart';
import '../features/import_export/domain/csv_ledger.dart';
import '../features/ledger/domain/ledger_snapshot.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/transactions/domain/category.dart';
import '../features/transactions/domain/ledger_transaction.dart';
import '../features/transactions/domain/recurring_rule.dart';
import 'ledger_repository.dart';
import 'seed/seed_data.dart';

/// In-memory book used by tests and as the reference for the Drift mapping.
class MemoryLedgerRepository implements LedgerRepository {
  AppSettings _settings = const AppSettings();
  final List<Account> _accounts = <Account>[];
  final List<Category> _categories = <Category>[];
  final List<LedgerTransaction> _transactions = <LedgerTransaction>[];
  final List<RecurringRule> _rules = <RecurringRule>[];
  final List<CategoryBudget> _budgets = <CategoryBudget>[];

  @override
  Future<LedgerSnapshot> load() async => _snapshot();

  @override
  Future<void> ensureSeeded(DateTime today) async {
    if (_settings.seeded) return;
    _replace(SeedData.build(today));
  }

  @override
  Future<void> restoreDemo(DateTime today) async {
    _replace(SeedData.build(today));
    await materializeRecurring(today);
  }

  @override
  Future<void> materializeRecurring(DateTime today) async {
    final posting = RecurringSchedule.materialize(
      rules: List<RecurringRule>.of(_rules),
      existingIds: _transactions.map((txn) => txn.id).toSet(),
      until: today,
    );
    if (posting.created.isEmpty &&
        !RecurringSchedule.materializationChanged(_rules, posting.rules)) {
      return;
    }
    _transactions.addAll(posting.created);
    _rules
      ..clear()
      ..addAll(posting.rules);
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> upsertAccount(Account account) async {
    final index = _accounts.indexWhere((item) => item.id == account.id);
    if (index < 0) {
      _accounts.add(account);
    } else {
      _accounts[index] = account;
    }
  }

  @override
  Future<void> upsertCategory(Category category) async {
    final index = _categories.indexWhere((item) => item.id == category.id);
    if (index < 0) {
      _categories.add(category);
    } else {
      _categories[index] = category;
    }
  }

  @override
  Future<void> insertTransaction(LedgerTransaction transaction) async {
    if (_transactions.any((txn) => txn.id == transaction.id)) {
      throw StateError('Transaction ${transaction.id} already exists.');
    }
    _transactions.add(transaction);
  }

  @override
  Future<void> updateTransaction(LedgerTransaction transaction) async {
    final index = _transactions.indexWhere((txn) => txn.id == transaction.id);
    if (index < 0) {
      throw StateError('Transaction ${transaction.id} was not found.');
    }
    _transactions[index] = transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((txn) => txn.id == id);
  }

  @override
  Future<void> upsertRule(RecurringRule rule) async {
    final index = _rules.indexWhere((item) => item.id == rule.id);
    if (index < 0) {
      _rules.add(rule);
    } else {
      _rules[index] = rule;
    }
  }

  @override
  Future<void> deleteRule(String id) async {
    _rules.removeWhere((rule) => rule.id == id);
  }

  @override
  Future<void> upsertBudget(CategoryBudget budget) async {
    _budgets.removeWhere(
      (item) => item.categoryId == budget.categoryId && item.id != budget.id,
    );
    final index = _budgets.indexWhere((item) => item.id == budget.id);
    if (index < 0) {
      _budgets.add(budget);
    } else {
      _budgets[index] = budget;
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((budget) => budget.id == id);
  }

  @override
  Future<CsvImportPlan> importCsv(
    String csv, {
    required DateTime today,
    required String Function(String prefix) newId,
  }) async {
    final plan = CsvLedger.parse(
      csv,
      current: _snapshot(),
      now: today,
      newId: newId,
    );
    for (final account in plan.accounts) {
      await upsertAccount(account);
    }
    for (final category in plan.categories) {
      await upsertCategory(category);
    }
    for (final txn in plan.transactions) {
      await insertTransaction(txn);
    }
    return plan;
  }

  LedgerSnapshot _snapshot() {
    final transactions = List<LedgerTransaction>.of(_transactions)
      ..sort((a, b) {
        final byDate = b.occurredOn.compareTo(a.occurredOn);
        if (byDate != 0) return byDate;
        return b.id.compareTo(a.id);
      });
    final accounts = List<Account>.of(_accounts)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return LedgerSnapshot(
      settings: _settings,
      accounts: List<Account>.unmodifiable(accounts),
      categories: List<Category>.unmodifiable(_categories),
      transactions: List<LedgerTransaction>.unmodifiable(transactions),
      rules: List<RecurringRule>.unmodifiable(_rules),
      budgets: List<CategoryBudget>.unmodifiable(_budgets),
    );
  }

  void _replace(LedgerSnapshot snapshot) {
    _settings = snapshot.settings;
    _accounts
      ..clear()
      ..addAll(snapshot.accounts);
    _categories
      ..clear()
      ..addAll(snapshot.categories);
    _transactions
      ..clear()
      ..addAll(snapshot.transactions);
    _rules
      ..clear()
      ..addAll(snapshot.rules);
    _budgets
      ..clear()
      ..addAll(snapshot.budgets);
  }
}
