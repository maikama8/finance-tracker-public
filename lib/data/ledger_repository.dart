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
  /// The book as it is stored now.
  Future<LedgerSnapshot> load();

  /// Writes the demo book once. Later calls leave the user's data alone.
  Future<void> ensureSeeded(DateTime today);

  /// Posts recurring rules that are due on or before [today].
  ///
  /// Safe to call again: an occurrence id is stable, and a deleted occurrence
  /// on or before the cursor is not recreated.
  Future<void> materializeRecurring(DateTime today);

  /// Replaces the book with a fresh demo, then posts rules due by [today].
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
