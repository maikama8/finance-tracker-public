import 'package:drift/native.dart';
import 'package:finance_tracker/data/drift/app_database.dart';
import 'package:finance_tracker/data/drift/drift_ledger_repository.dart';
import 'package:finance_tracker/data/seed/seed_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Drift stores the seeded book and does not duplicate recurring rows',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final repo = DriftLedgerRepository(database);
      final today = DateTime.utc(2026, 11, 14);
      addTearDown(database.close);
      await repo.ensureSeeded(today);
      await repo.materializeRecurring(today);
      final first = await repo.load();
      expect(first.settings.seeded, isTrue);
      expect(first.accounts, isNotEmpty);
      final salary = first.transactions
          .where((txn) => txn.recurringRuleId == SeedData.ruleSalary)
          .length;
      expect(salary, 5);
      await repo.materializeRecurring(today);
      final second = await repo.load();
      expect(second.transactions, hasLength(first.transactions.length));
      await repo.ensureSeeded(today);
      final third = await repo.load();
      expect(third.transactions, hasLength(first.transactions.length));
    },
  );
}
