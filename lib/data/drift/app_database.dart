import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: <Type>[
    Accounts,
    Categories,
    LedgerEntries,
    RecurringRules,
    Budgets,
    SettingsRows,
  ],
)
/// SQLite database for one ledger. Schema version 1.
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openKoboDatabase());

  @override
  int get schemaVersion => 1;
}

/// Opens the on-device database named `kobo`.
///
/// Web loads `sqlite3.wasm` and `drift_worker.js` from the app origin. Those
/// files are the Drift web runtime for the pinned `drift` and `sqlite3`
/// packages, so they ship with the app rather than being build output.
QueryExecutor openKoboDatabase() {
  return driftDatabase(
    name: 'kobo',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
      onResult: (_) {},
    ),
  );
}
