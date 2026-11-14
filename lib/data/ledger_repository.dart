import '../features/accounts/domain/account.dart';
import '../features/budgets/domain/category_budget.dart';
import '../features/import_export/domain/csv_ledger.dart';
import '../features/ledger/domain/ledger_snapshot.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/transactions/domain/category.dart';
import '../features/transactions/domain/ledger_transaction.dart';
import '../features/transactions/domain/recurring_rule.dart';

/// Persistence for one ledger.
///
/// The Drift implementation is what the app opens. Tests use the in-memory
/// implementation. Both apply the same seed and the same recurring schedule.
abstract class LedgerRepository {
  Future<LedgerSnapshot> load();

  Future<void> ensureSeeded(DateTime today);

  Future<void> materializeRecurring(DateTime today);

  Future<void> restoreDemo(DateTime today);

  Future<void> saveSettings(AppSettings settings);

  Future<void> upsertAccount(Account account);

  Future<void> upsertCategory(Category category);

  Future<void> insertTransaction(LedgerTransaction transaction);

  Future<void> updateTransaction(LedgerTransaction transaction);

  Future<void> deleteTransaction(String id);

  Future<void> upsertRule(RecurringRule rule);

  Future<void> deleteRule(String id);

  Future<void> upsertBudget(CategoryBudget budget);

  Future<void> deleteBudget(String id);

  Future<CsvImportPlan> importCsv(
    String csv, {
    required DateTime today,
    required String Function(String prefix) newId,
  });
}
