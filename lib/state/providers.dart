import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/currency/exchange_rate_service.dart';
import '../core/currency/http_exchange_rate_service.dart';
import '../core/currency/mock_exchange_rate_service.dart';
import '../core/ids.dart';
import '../core/navigation/browser_location.dart';
import '../core/navigation/launch_location.dart';
import '../core/theme/theme_preference.dart';
import '../core/time/clock.dart';
import '../data/drift/app_database.dart';
import '../data/drift/drift_ledger_repository.dart';
import '../data/ledger_repository.dart';
import '../features/accounts/domain/account.dart';
import '../features/budgets/domain/category_budget.dart';
import '../features/dashboard/domain/ledger_report.dart';
import '../features/import_export/domain/csv_ledger.dart';
import '../features/ledger/domain/ledger_snapshot.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/transactions/domain/category.dart';
import '../features/transactions/domain/ledger_transaction.dart';
import '../features/transactions/domain/recurring_rule.dart';
import '../features/transactions/domain/transaction_query.dart';

/// Clock used for "today". Tests override this with [FixedClock].
final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// Ids for rows the user creates.
final idSourceProvider = Provider<IdSource>((ref) => IdSource());

/// Where the app should open. Native builds stay on Home.
final launchLocationProvider = Provider<LaunchLocation>((ref) {
  return parseLaunchLocation(readBrowserLocation());
});

/// SQLite database. Closed when the provider is disposed.
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

/// The ledger the running app reads and writes.
final repositoryProvider = Provider<LedgerRepository>((ref) {
  return DriftLedgerRepository(ref.watch(databaseProvider));
});

/// Active exchange rates. The session starts on the offline table.
final rateBookProvider = NotifierProvider<RateBook, ExchangeRateService>(
  RateBook.new,
);

/// Holds the rate source for this session.
class RateBook extends Notifier<ExchangeRateService> {
  @override
  ExchangeRateService build() => const MockExchangeRateService();

  /// Fetches live rates. Returns a message and keeps the previous table
  /// when the feed cannot be used.
  Future<String?> useLiveRates() async {
    try {
      state = await HttpExchangeRateService.fetch();
      return null;
    } on ExchangeRateException catch (error) {
      return error.message;
    }
  }

  /// Drops a live table and returns to the offline fixtures.
  void useOffline() {
    state = const MockExchangeRateService();
  }
}

/// The open book. Loads the seed, posts due rules, then serves edits.
final ledgerProvider = AsyncNotifierProvider<LedgerController, LedgerSnapshot>(
  LedgerController.new,
);

/// Loads the ledger and applies the edits the screens request.
class LedgerController extends AsyncNotifier<LedgerSnapshot> {
  @override
  Future<LedgerSnapshot> build() async {
    final repo = ref.watch(repositoryProvider);
    final today = ref.watch(clockProvider).today();
    await repo.ensureSeeded(today);
    await repo.materializeRecurring(today);
    return repo.load();
  }

  Future<void> _reload() async {
    state = AsyncData(await ref.read(repositoryProvider).load());
  }

  LedgerSnapshot? get _current => state.asData?.value;

  Future<void> saveTransaction({
    required LedgerTransaction transaction,
    RecurringRule? newRule,
    required bool isNew,
  }) async {
    final repo = ref.read(repositoryProvider);
    if (isNew) {
      await repo.insertTransaction(transaction);
    } else {
      await repo.updateTransaction(transaction);
    }
    if (newRule != null) {
      await repo.upsertRule(newRule);
    }
    await _reload();
  }

  Future<void> deleteTransaction(String id) async {
    await ref.read(repositoryProvider).deleteTransaction(id);
    await _reload();
  }

  /// Inserts [account], or replaces the row with the same id.
  Future<void> saveAccount(Account account) async {
    await ref.read(repositoryProvider).upsertAccount(account);
    await _reload();
  }

  Future<void> setAccountArchived(String id, {required bool archived}) async {
    final account = _current?.accountById(id);
    if (account == null) return;
    await ref
        .read(repositoryProvider)
        .upsertAccount(account.copyWith(archived: archived));
    await _reload();
  }

  Future<void> saveCategory(Category category) async {
    await ref.read(repositoryProvider).upsertCategory(category);
    await _reload();
  }

  Future<void> saveBudget(CategoryBudget budget) async {
    await ref.read(repositoryProvider).upsertBudget(budget);
    await _reload();
  }

  Future<void> deleteBudget(String id) async {
    await ref.read(repositoryProvider).deleteBudget(id);
    await _reload();
  }

  Future<void> setRuleActive(String id, {required bool active}) async {
    final rules = _current?.rules ?? const <RecurringRule>[];
    for (final rule in rules) {
      if (rule.id != id) continue;
      await ref
          .read(repositoryProvider)
          .upsertRule(rule.copyWith(active: active));
    }
    await _reload();
  }

  Future<void> deleteRule(String id) async {
    await ref.read(repositoryProvider).deleteRule(id);
    await _reload();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await ref.read(repositoryProvider).saveSettings(settings);
    await _reload();
  }

  Future<CsvImportPlan> importCsv(String csv) async {
    final plan = await ref
        .read(repositoryProvider)
        .importCsv(
          csv,
          today: ref.read(clockProvider).today(),
          newId: ref.read(idSourceProvider).next,
        );
    await _reload();
    return plan;
  }

  Future<void> restoreDemo() async {
    await ref
        .read(repositoryProvider)
        .restoreDemo(ref.read(clockProvider).today());
    await _reload();
  }
}

/// Light, dark, or system. A theme in the launch URL wins over the saved one.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final overrideTheme = ref.watch(launchLocationProvider).themeOverride;
  if (overrideTheme == ThemePreference.dark) return ThemeMode.dark;
  if (overrideTheme == ThemePreference.light) return ThemeMode.light;
  final settings = ref.watch(ledgerProvider).asData?.value.settings;
  return switch (settings?.theme) {
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light || null => ThemeMode.light,
  };
});

/// Dashboard figures for the open ledger, or null while it is loading.
final dashboardProvider = Provider<DashboardFigures?>((ref) {
  final ledger = ref.watch(ledgerProvider).asData?.value;
  if (ledger == null) return null;
  return DashboardFigures.compose(
    accounts: ledger.accounts,
    categories: ledger.categories,
    transactions: ledger.transactions,
    budgets: ledger.budgets,
    rates: ref.watch(rateBookProvider),
    baseCurrency: ledger.settings.baseCurrencyCode,
    today: ref.watch(clockProvider).today(),
  );
});

/// Selected shell tab. Changing it writes the web hash.
final shellProvider = NotifierProvider<ShellController, int>(
  ShellController.new,
);

/// The selected tab, and the hash that should match it.
class ShellController extends Notifier<int> {
  @override
  int build() => ref.read(launchLocationProvider).tab;

  void select(int index) {
    state = index;
    writeBrowserLocation(pathForTab(index));
  }
}

/// Search and filters for the activity list.
final transactionQueryProvider =
    NotifierProvider<TransactionQueryController, TransactionQuery>(
      TransactionQueryController.new,
    );

/// The activity search box and its facets.
class TransactionQueryController extends Notifier<TransactionQuery> {
  @override
  TransactionQuery build() => const TransactionQuery();

  void update(TransactionQuery query) => state = query;
}

/// The month shown on the budgets screen. Starts at the current month.
final budgetMonthProvider = NotifierProvider<BudgetMonthController, DateTime>(
  BudgetMonthController.new,
);

/// Moves the budgets screen by calendar months.
class BudgetMonthController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final today = ref.read(clockProvider).today();
    return DateTime.utc(today.year, today.month, 1);
  }

  void shift(int delta) {
    final current = state;
    state = DateTime.utc(current.year, current.month + delta, 1);
  }
}
