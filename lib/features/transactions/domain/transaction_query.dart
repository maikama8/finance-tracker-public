import '../../../core/time/iso_date.dart';
import 'category.dart';
import '../../accounts/domain/account.dart';
import 'ledger_transaction.dart';

/// Search text and optional facets for the activity list.
class TransactionQuery {
  const TransactionQuery({
    this.text = '',
    this.kind,
    this.accountId,
    this.categoryId,
    this.from,
    this.to,
  });

  final String text;
  final TransactionKind? kind;
  final String? accountId;
  final String? categoryId;
  final DateTime? from;
  final DateTime? to;

  /// True when the list is not the full book.
  bool get isNarrowed =>
      text.trim().isNotEmpty ||
      kind != null ||
      accountId != null ||
      categoryId != null ||
      from != null ||
      to != null;

  /// True when a facet other than the search box and the kind chips is set.
  bool get hasFacet =>
      accountId != null || categoryId != null || from != null || to != null;

  TransactionQuery copyWith({
    String? text,
    TransactionKind? kind,
    bool clearKind = false,
    String? accountId,
    bool clearAccount = false,
    String? categoryId,
    bool clearCategory = false,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
  }) {
    return TransactionQuery(
      text: text ?? this.text,
      kind: clearKind ? null : kind ?? this.kind,
      accountId: clearAccount ? null : accountId ?? this.accountId,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      from: clearFrom ? null : from ?? this.from,
      to: clearTo ? null : to ?? this.to,
    );
  }
}

/// Transactions that match [query], newest first.
///
/// An account facet matches the source account and the transfer destination.
/// Search looks at the note, account names, category name, currency, and amount.
List<LedgerTransaction> filterTransactions({
  required List<LedgerTransaction> transactions,
  required List<Account> accounts,
  required List<Category> categories,
  required TransactionQuery query,
}) {
  final accountNames = <String, String>{
    for (final account in accounts) account.id: account.name,
  };
  final categoryNames = <String, String>{
    for (final category in categories) category.id: category.name,
  };
  final needle = query.text.trim().toLowerCase();
  final from = query.from == null ? null : dateOnly(query.from!);
  final to = query.to == null ? null : dateOnly(query.to!);
  final results = <LedgerTransaction>[];
  for (final txn in transactions) {
    if (query.kind != null && txn.kind != query.kind) continue;
    if (query.accountId != null &&
        txn.accountId != query.accountId &&
        txn.counterAccountId != query.accountId) {
      continue;
    }
    if (query.categoryId != null && txn.categoryId != query.categoryId) {
      continue;
    }
    final occurred = dateOnly(txn.occurredOn);
    if (from != null && occurred.isBefore(from)) continue;
    if (to != null && occurred.isAfter(to)) continue;
    if (needle.isNotEmpty) {
      final major = txn.amountMinor ~/ 100;
      final hay = <String>[
        txn.note,
        accountNames[txn.accountId] ?? '',
        if (txn.counterAccountId != null)
          accountNames[txn.counterAccountId] ?? '',
        if (txn.categoryId != null) categoryNames[txn.categoryId] ?? '',
        txn.currencyCode,
        major.toString(),
        (txn.amountMinor / 100).toStringAsFixed(2),
      ].join(' ').toLowerCase();
      if (!hay.contains(needle)) continue;
    }
    results.add(txn);
  }
  results.sort((a, b) {
    final byDate = b.occurredOn.compareTo(a.occurredOn);
    if (byDate != 0) return byDate;
    return b.id.compareTo(a.id);
  });
  return results;
}
