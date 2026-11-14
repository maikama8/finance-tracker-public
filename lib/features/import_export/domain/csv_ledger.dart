import '../../../core/formatting/money_format.dart';
import '../../../core/time/iso_date.dart';
import '../../accounts/domain/account.dart';
import '../../ledger/domain/ledger_snapshot.dart';
import '../../transactions/domain/category.dart';
import '../../transactions/domain/ledger_transaction.dart';

/// One CSV row the importer refused.
class CsvRowError {
  const CsvRowError({required this.line, required this.message});

  /// 1-based line number in the file, including the header.
  final int line;
  final String message;
}

/// What an import would write, plus the rows it skipped or refused.
class CsvImportPlan {
  const CsvImportPlan({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.skipped,
    required this.errors,
  });

  final List<Account> accounts;
  final List<Category> categories;
  final List<LedgerTransaction> transactions;
  final int skipped;
  final List<CsvRowError> errors;

  int get imported => transactions.length;
}

/// CSV round trip for the ledger.
///
/// Columns, in order:
/// `id,date,kind,account,currency,amount,category,note,counter_account,destination_amount`.
/// Amounts are major units with two decimals. A field that contains a comma,
/// quote, or newline is quoted, and quotes inside it are doubled.
class CsvLedger {
  const CsvLedger._();

  static const List<String> header = <String>[
    'id',
    'date',
    'kind',
    'account',
    'currency',
    'amount',
    'category',
    'note',
    'counter_account',
    'destination_amount',
  ];

  static String export(LedgerSnapshot snapshot) {
    final rows = List<LedgerTransaction>.of(snapshot.transactions)
      ..sort((a, b) {
        final byDate = a.occurredOn.compareTo(b.occurredOn);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });
    final buffer = StringBuffer('${header.join(',')}\n');
    for (final txn in rows) {
      final account = snapshot.accountById(txn.accountId);
      final counter = txn.counterAccountId == null
          ? null
          : snapshot.accountById(txn.counterAccountId!);
      final category = txn.categoryId == null
          ? null
          : snapshot.categoryById(txn.categoryId!);
      buffer.writeln(
        <String>[
          txn.id,
          formatIsoDate(txn.occurredOn),
          txn.kind.storageName,
          account?.name ?? txn.accountId,
          txn.currencyCode,
          _major(txn.amountMinor),
          category?.name ?? '',
          txn.note,
          counter?.name ?? '',
          txn.destinationAmountMinor == null
              ? ''
              : _major(txn.destinationAmountMinor!),
        ].map(_escape).join(','),
      );
    }
    return buffer.toString();
  }

  /// Plans inserts against [current]. Existing ids are skipped. Unknown
  /// account and category names are created. A bad row is reported and the
  /// other rows are still imported.
  static CsvImportPlan parse(
    String csv, {
    required LedgerSnapshot current,
    required DateTime now,
    required String Function(String prefix) newId,
  }) {
    final lines = _splitLines(csv);
    final errors = <CsvRowError>[];
    if (lines.isEmpty) {
      return CsvImportPlan(
        accounts: const <Account>[],
        categories: const <Category>[],
        transactions: const <LedgerTransaction>[],
        skipped: 0,
        errors: const <CsvRowError>[
          CsvRowError(line: 1, message: 'The file is empty.'),
        ],
      );
    }
    final List<String> headerCells;
    try {
      headerCells = _parseLine(lines.first);
    } on FormatException catch (error) {
      return CsvImportPlan(
        accounts: const <Account>[],
        categories: const <Category>[],
        transactions: const <LedgerTransaction>[],
        skipped: 0,
        errors: <CsvRowError>[CsvRowError(line: 1, message: error.message)],
      );
    }
    if (!_headerMatches(headerCells)) {
      return const CsvImportPlan(
        accounts: <Account>[],
        categories: <Category>[],
        transactions: <LedgerTransaction>[],
        skipped: 0,
        errors: <CsvRowError>[
          CsvRowError(
            line: 1,
            message: 'Header must be id,date,kind,account,currency,amount,category,note,counter_account,destination_amount.',
          ),
        ],
      );
    }
    final accounts = <Account>[];
    final categories = <Category>[];
    final transactions = <LedgerTransaction>[];
    final knownAccounts = List<Account>.of(current.accounts);
    final knownCategories = List<Category>.of(current.categories);
    final knownIds = <String>{for (final txn in current.transactions) txn.id};
    var skipped = 0;
    for (var i = 1; i < lines.length; i++) {
      final lineNumber = i + 1;
      final raw = lines[i].trim();
      if (raw.isEmpty) continue;
      final cells = _parseLine(lines[i]);
      if (cells.length != header.length) {
        errors.add(
          CsvRowError(
            line: lineNumber,
            message: 'Expected ${header.length} columns.',
          ),
        );
        continue;
      }
      try {
        final planned = _row(
          cells: cells,
          knownAccounts: knownAccounts,
          knownCategories: knownCategories,
          knownIds: knownIds,
          now: now,
          newId: newId,
          newAccounts: accounts,
          newCategories: categories,
        );
        if (planned == null) {
          skipped += 1;
          continue;
        }
        transactions.add(planned);
        knownIds.add(planned.id);
      } on FormatException catch (error) {
        errors.add(CsvRowError(line: lineNumber, message: error.message));
      }
    }
    return CsvImportPlan(
      accounts: accounts,
      categories: categories,
      transactions: transactions,
      skipped: skipped,
      errors: errors,
    );
  }

  static LedgerTransaction? _row({
    required List<String> cells,
    required List<Account> knownAccounts,
    required List<Category> knownCategories,
    required Set<String> knownIds,
    required DateTime now,
    required String Function(String prefix) newId,
    required List<Account> newAccounts,
    required List<Category> newCategories,
  }) {
    final id = cells[0].trim().isEmpty ? newId('txn') : cells[0].trim();
    if (knownIds.contains(id)) return null;
    final date = parseIsoDate(cells[1].trim());
    final kind = parseTransactionKind(cells[2].trim());
    final accountName = cells[3].trim();
    if (accountName.isEmpty) {
      throw const FormatException('Account is required.');
    }
    final currency = cells[4].trim();
    if (currency.isEmpty) {
      throw const FormatException('Currency is required.');
    }
    final amount = parseMoneyInput(cells[5].trim());
    if (amount == null) {
      throw const FormatException('Amount must be a positive number.');
    }
    final account = _account(
      name: accountName,
      currency: currency,
      known: knownAccounts,
      created: newAccounts,
      now: now,
      newId: newId,
    );
    if (account.currencyCode != currency) {
      throw FormatException(
        '${account.name} is ${account.currencyCode}, not $currency.',
      );
    }
    String? categoryId;
    final categoryName = cells[6].trim();
    if (kind != TransactionKind.transfer) {
      if (categoryName.isEmpty) {
        throw const FormatException('Category is required.');
      }
      final category = _category(
        name: categoryName,
        kind: kind == TransactionKind.income
            ? CategoryKind.income
            : CategoryKind.expense,
        known: knownCategories,
        created: newCategories,
        newId: newId,
      );
      categoryId = category.id;
    }
    String? counterId;
    int? destination;
    final counterName = cells[8].trim();
    if (kind == TransactionKind.transfer) {
      if (counterName.isEmpty) {
        throw const FormatException('A transfer needs a counter account.');
      }
      if (counterName == accountName) {
        throw const FormatException('A transfer needs two accounts.');
      }
      final counter = _account(
        name: counterName,
        currency: currency,
        known: knownAccounts,
        created: newAccounts,
        now: now,
        newId: newId,
      );
      counterId = counter.id;
      final rawDestination = cells[9].trim();
      if (rawDestination.isEmpty) {
        if (counter.currencyCode != currency) {
          throw const FormatException(
            'A cross-currency transfer needs destination_amount.',
          );
        }
        destination = amount;
      } else {
        destination = parseMoneyInput(rawDestination);
        if (destination == null) {
          throw const FormatException('Destination amount is not a number.');
        }
      }
    }
    return LedgerTransaction(
      id: id,
      kind: kind,
      accountId: account.id,
      counterAccountId: counterId,
      categoryId: categoryId,
      amountMinor: amount,
      destinationAmountMinor: destination,
      currencyCode: currency,
      occurredOn: date,
      note: cells[7],
    );
  }

  static Account _account({
    required String name,
    required String currency,
    required List<Account> known,
    required List<Account> created,
    required DateTime now,
    required String Function(String prefix) newId,
  }) {
    for (final account in known) {
      if (account.name == name) return account;
    }
    final account = Account(
      id: newId('acct'),
      name: name,
      kind: AccountKind.bank,
      currencyCode: currency,
      openingBalanceMinor: 0,
      color: 0xFF1F6F8B,
      createdAt: dateOnly(now),
    );
    known.add(account);
    created.add(account);
    return account;
  }

  static Category _category({
    required String name,
    required CategoryKind kind,
    required List<Category> known,
    required List<Category> created,
    required String Function(String prefix) newId,
  }) {
    for (final category in known) {
      if (category.name == name) {
        if (category.kind != kind) {
          throw FormatException(
            '$name is a ${category.kind.storageName} category.',
          );
        }
        return category;
      }
    }
    final category = Category(
      id: newId('cat'),
      name: name,
      kind: kind,
      color: kind == CategoryKind.income ? 0xFF0E7A45 : 0xFFC5922C,
      iconKey: 'other',
    );
    known.add(category);
    created.add(category);
    return category;
  }

  static bool _headerMatches(List<String> cells) {
    if (cells.length != header.length) return false;
    for (var i = 0; i < header.length; i++) {
      if (cells[i].trim() != header[i]) return false;
    }
    return true;
  }

  static String _major(int minor) {
    final negative = minor < 0;
    final absolute = minor.abs();
    final major = absolute ~/ 100;
    final fraction = (absolute % 100).toString().padLeft(2, '0');
    return '${negative ? '-' : ''}$major.$fraction';
  }

  static String _escape(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static List<String> _splitLines(String csv) {
    final normalized = csv.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
    return lines;
  }

  static List<String> _parseLine(String line) {
    final cells = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (quoted) {
        if (char == '"') {
          final next = i + 1 < line.length ? line[i + 1] : '';
          if (next == '"') {
            buffer.write('"');
            i += 1;
          } else {
            quoted = false;
          }
        } else {
          buffer.write(char);
        }
      } else if (char == '"') {
        quoted = true;
      } else if (char == ',') {
        cells.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    if (quoted) {
      throw const FormatException('A quoted field was not closed.');
    }
    cells.add(buffer.toString());
    return cells;
  }
}
