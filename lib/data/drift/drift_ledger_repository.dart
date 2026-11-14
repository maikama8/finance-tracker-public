import 'package:drift/drift.dart';

import '../../core/theme/theme_preference.dart';
import '../../core/time/iso_date.dart';
import '../../features/accounts/domain/account.dart';
import '../../features/budgets/domain/category_budget.dart';
import '../../features/import_export/domain/csv_ledger.dart';
import '../../features/ledger/domain/ledger_snapshot.dart';
import '../../features/settings/domain/app_settings.dart';
import '../../features/transactions/domain/category.dart';
import '../../features/transactions/domain/ledger_transaction.dart';
import '../../features/transactions/domain/recurring_rule.dart';
import '../ledger_repository.dart';
import '../seed/seed_data.dart';
import 'app_database.dart';

/// SQLite ledger. The web build uses the wasm module in `web/`.
class DriftLedgerRepository implements LedgerRepository {
  DriftLedgerRepository(this._db);

  final AppDatabase _db;

  @override
  Future<LedgerSnapshot> load() async {
    final settingsRows = await _db.select(_db.settingsRows).get();
    final accounts = await (_db.select(
      _db.accounts,
    )..orderBy([(row) => OrderingTerm.asc(row.createdAt)])).get();
    final categories = await (_db.select(
      _db.categories,
    )..orderBy([(row) => OrderingTerm.asc(row.name)])).get();
    final transactions =
        await (_db.select(_db.ledgerEntries)..orderBy([
              (row) => OrderingTerm.desc(row.occurredOn),
              (row) => OrderingTerm.desc(row.id),
            ]))
            .get();
    final rules = await _db.select(_db.recurringRules).get();
    final budgets = await _db.select(_db.budgets).get();
    return LedgerSnapshot(
      settings: settingsRows.isEmpty
          ? const AppSettings()
          : _settingsFrom(settingsRows.first),
      accounts: accounts.map(_accountFrom).toList(growable: false),
      categories: categories.map(_categoryFrom).toList(growable: false),
      transactions: transactions.map(_transactionFrom).toList(growable: false),
      rules: rules.map(_ruleFrom).toList(growable: false),
      budgets: budgets.map(_budgetFrom).toList(growable: false),
    );
  }

  @override
  Future<void> ensureSeeded(DateTime today) async {
    final current = await load();
    if (current.settings.seeded) return;
    await _replace(SeedData.build(today));
  }

  @override
  Future<void> restoreDemo(DateTime today) async {
    await _replace(SeedData.build(today));
    await materializeRecurring(today);
  }

  @override
  Future<void> materializeRecurring(DateTime today) async {
    final current = await load();
    final posting = RecurringSchedule.materialize(
      rules: current.rules,
      existingIds: current.transactions.map((txn) => txn.id).toSet(),
      until: today,
    );
    final moved = RecurringSchedule.materializationChanged(
      current.rules,
      posting.rules,
    );
    if (posting.created.isEmpty && !moved) return;
    await _db.transaction(() async {
      for (final txn in posting.created) {
        await _db.into(_db.ledgerEntries).insert(_transactionTo(txn));
      }
      for (final rule in posting.rules) {
        await _db
            .into(_db.recurringRules)
            .insertOnConflictUpdate(_ruleTo(rule));
      }
    });
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _db
        .into(_db.settingsRows)
        .insertOnConflictUpdate(_settingsTo(settings));
  }

  @override
  Future<void> upsertAccount(Account account) async {
    await _db.into(_db.accounts).insertOnConflictUpdate(_accountTo(account));
  }

  @override
  Future<void> upsertCategory(Category category) async {
    await _db
        .into(_db.categories)
        .insertOnConflictUpdate(_categoryTo(category));
  }

  @override
  Future<void> insertTransaction(LedgerTransaction transaction) async {
    await _db.into(_db.ledgerEntries).insert(_transactionTo(transaction));
  }

  @override
  Future<void> updateTransaction(LedgerTransaction transaction) async {
    await _db
        .into(_db.ledgerEntries)
        .insertOnConflictUpdate(_transactionTo(transaction));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await (_db.delete(
      _db.ledgerEntries,
    )..where((row) => row.id.equals(id))).go();
  }

  @override
  Future<void> upsertRule(RecurringRule rule) async {
    await _db.into(_db.recurringRules).insertOnConflictUpdate(_ruleTo(rule));
  }

  @override
  Future<void> deleteRule(String id) async {
    await (_db.delete(
      _db.recurringRules,
    )..where((row) => row.id.equals(id))).go();
  }

  @override
  Future<void> upsertBudget(CategoryBudget budget) async {
    await (_db.delete(_db.budgets)..where(
          (row) =>
              row.categoryId.equals(budget.categoryId) &
              row.id.equals(budget.id).not(),
        ))
        .go();
    await _db.into(_db.budgets).insertOnConflictUpdate(_budgetTo(budget));
  }

  @override
  Future<void> deleteBudget(String id) async {
    await (_db.delete(_db.budgets)..where((row) => row.id.equals(id))).go();
  }

  @override
  Future<CsvImportPlan> importCsv(
    String csv, {
    required DateTime today,
    required String Function(String prefix) newId,
  }) async {
    final plan = CsvLedger.parse(
      csv,
      current: await load(),
      now: today,
      newId: newId,
    );
    await _db.transaction(() async {
      for (final account in plan.accounts) {
        await _db
            .into(_db.accounts)
            .insertOnConflictUpdate(_accountTo(account));
      }
      for (final category in plan.categories) {
        await _db
            .into(_db.categories)
            .insertOnConflictUpdate(_categoryTo(category));
      }
      for (final txn in plan.transactions) {
        await _db.into(_db.ledgerEntries).insert(_transactionTo(txn));
      }
    });
    return plan;
  }

  Future<void> _replace(LedgerSnapshot snapshot) {
    return _db.transaction(() async {
      await _db.delete(_db.ledgerEntries).go();
      await _db.delete(_db.recurringRules).go();
      await _db.delete(_db.budgets).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.settingsRows).go();
      for (final account in snapshot.accounts) {
        await _db.into(_db.accounts).insert(_accountTo(account));
      }
      for (final category in snapshot.categories) {
        await _db.into(_db.categories).insert(_categoryTo(category));
      }
      for (final txn in snapshot.transactions) {
        await _db.into(_db.ledgerEntries).insert(_transactionTo(txn));
      }
      for (final rule in snapshot.rules) {
        await _db.into(_db.recurringRules).insert(_ruleTo(rule));
      }
      for (final budget in snapshot.budgets) {
        await _db.into(_db.budgets).insert(_budgetTo(budget));
      }
      await _db.into(_db.settingsRows).insert(_settingsTo(snapshot.settings));
    });
  }
}

AccountsCompanion _accountTo(Account account) {
  return AccountsCompanion.insert(
    id: account.id,
    name: account.name,
    kind: account.kind.storageName,
    currencyCode: account.currencyCode,
    openingBalanceMinor: account.openingBalanceMinor,
    institution: Value(account.institution),
    color: account.color,
    archived: Value(account.archived),
    createdAt: formatIsoTimestamp(account.createdAt),
  );
}

Account _accountFrom(AccountRow row) {
  return Account(
    id: row.id,
    name: row.name,
    kind: parseAccountKind(row.kind),
    currencyCode: row.currencyCode,
    openingBalanceMinor: row.openingBalanceMinor,
    institution: row.institution,
    color: row.color,
    archived: row.archived,
    createdAt: parseIsoTimestamp(row.createdAt),
  );
}

CategoriesCompanion _categoryTo(Category category) {
  return CategoriesCompanion.insert(
    id: category.id,
    name: category.name,
    kind: category.kind.storageName,
    color: category.color,
    iconKey: category.iconKey,
  );
}

Category _categoryFrom(CategoryRow row) {
  return Category(
    id: row.id,
    name: row.name,
    kind: parseCategoryKind(row.kind),
    color: row.color,
    iconKey: row.iconKey,
  );
}

LedgerEntriesCompanion _transactionTo(LedgerTransaction txn) {
  return LedgerEntriesCompanion.insert(
    id: txn.id,
    kind: txn.kind.storageName,
    accountId: txn.accountId,
    counterAccountId: Value(txn.counterAccountId),
    categoryId: Value(txn.categoryId),
    amountMinor: txn.amountMinor,
    destinationAmountMinor: Value(txn.destinationAmountMinor),
    currencyCode: txn.currencyCode,
    occurredOn: formatIsoDate(txn.occurredOn),
    note: txn.note,
    recurringRuleId: Value(txn.recurringRuleId),
  );
}

LedgerTransaction _transactionFrom(LedgerEntryRow row) {
  return LedgerTransaction(
    id: row.id,
    kind: parseTransactionKind(row.kind),
    accountId: row.accountId,
    counterAccountId: row.counterAccountId,
    categoryId: row.categoryId,
    amountMinor: row.amountMinor,
    destinationAmountMinor: row.destinationAmountMinor,
    currencyCode: row.currencyCode,
    occurredOn: parseIsoDate(row.occurredOn),
    note: row.note,
    recurringRuleId: row.recurringRuleId,
  );
}

RecurringRulesCompanion _ruleTo(RecurringRule rule) {
  return RecurringRulesCompanion.insert(
    id: rule.id,
    kind: rule.kind.storageName,
    frequency: rule.frequency.storageName,
    interval: rule.interval,
    startOn: formatIsoDate(rule.startOn),
    endOn: Value(rule.endOn == null ? null : formatIsoDate(rule.endOn!)),
    accountId: rule.accountId,
    counterAccountId: Value(rule.counterAccountId),
    categoryId: Value(rule.categoryId),
    amountMinor: rule.amountMinor,
    destinationAmountMinor: Value(rule.destinationAmountMinor),
    currencyCode: rule.currencyCode,
    note: rule.note,
    lastMaterializedOn: Value(
      rule.lastMaterializedOn == null
          ? null
          : formatIsoDate(rule.lastMaterializedOn!),
    ),
    active: Value(rule.active),
  );
}

RecurringRule _ruleFrom(RecurringRuleRow row) {
  return RecurringRule(
    id: row.id,
    kind: parseTransactionKind(row.kind),
    frequency: parseRecurrenceFrequency(row.frequency),
    interval: row.interval,
    startOn: parseIsoDate(row.startOn),
    endOn: row.endOn == null ? null : parseIsoDate(row.endOn!),
    accountId: row.accountId,
    counterAccountId: row.counterAccountId,
    categoryId: row.categoryId,
    amountMinor: row.amountMinor,
    destinationAmountMinor: row.destinationAmountMinor,
    currencyCode: row.currencyCode,
    note: row.note,
    lastMaterializedOn: row.lastMaterializedOn == null
        ? null
        : parseIsoDate(row.lastMaterializedOn!),
    active: row.active,
  );
}

BudgetsCompanion _budgetTo(CategoryBudget budget) {
  return BudgetsCompanion.insert(
    id: budget.id,
    categoryId: budget.categoryId,
    limitMinor: budget.limitMinor,
    currencyCode: budget.currencyCode,
  );
}

CategoryBudget _budgetFrom(BudgetRow row) {
  return CategoryBudget(
    id: row.id,
    categoryId: row.categoryId,
    limitMinor: row.limitMinor,
    currencyCode: row.currencyCode,
  );
}

SettingsRowsCompanion _settingsTo(AppSettings settings) {
  return SettingsRowsCompanion.insert(
    id: const Value(1),
    baseCurrencyCode: settings.baseCurrencyCode,
    theme: settings.theme.name,
    seeded: settings.seeded,
  );
}

AppSettings _settingsFrom(SettingsRow row) {
  return AppSettings(
    baseCurrencyCode: row.baseCurrencyCode,
    theme: parseThemePreference(row.theme),
    seeded: row.seeded,
  );
}
