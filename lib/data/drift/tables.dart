import 'package:drift/drift.dart';

@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get kind => text()();

  TextColumn get currencyCode => text()();

  IntColumn get openingBalanceMinor => integer()();

  TextColumn get institution => text().nullable()();

  IntColumn get color => integer()();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  TextColumn get createdAt => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get kind => text()();

  IntColumn get color => integer()();

  TextColumn get iconKey => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('LedgerEntryRow')
class LedgerEntries extends Table {
  TextColumn get id => text()();

  TextColumn get kind => text()();

  TextColumn get accountId => text()();

  TextColumn get counterAccountId => text().nullable()();

  TextColumn get categoryId => text().nullable()();

  IntColumn get amountMinor => integer()();

  IntColumn get destinationAmountMinor => integer().nullable()();

  TextColumn get currencyCode => text()();

  TextColumn get occurredOn => text()();

  TextColumn get note => text()();

  TextColumn get recurringRuleId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('RecurringRuleRow')
class RecurringRules extends Table {
  TextColumn get id => text()();

  TextColumn get kind => text()();

  TextColumn get frequency => text()();

  IntColumn get interval => integer()();

  TextColumn get startOn => text()();

  TextColumn get endOn => text().nullable()();

  TextColumn get accountId => text()();

  TextColumn get counterAccountId => text().nullable()();

  TextColumn get categoryId => text().nullable()();

  IntColumn get amountMinor => integer()();

  IntColumn get destinationAmountMinor => integer().nullable()();

  TextColumn get currencyCode => text()();

  TextColumn get note => text()();

  TextColumn get lastMaterializedOn => text().nullable()();

  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('BudgetRow')
class Budgets extends Table {
  TextColumn get id => text()();

  TextColumn get categoryId => text()();

  IntColumn get limitMinor => integer()();

  TextColumn get currencyCode => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('SettingsRow')
class SettingsRows extends Table {
  @override
  String get tableName => 'settings';

  IntColumn get id => integer()();

  TextColumn get baseCurrencyCode => text()();

  TextColumn get theme => text()();

  BoolColumn get seeded => boolean()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
