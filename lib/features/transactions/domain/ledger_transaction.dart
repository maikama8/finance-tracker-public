/// What a posting does to the accounts it touches.
enum TransactionKind { income, expense, transfer }

/// Reads the kind stored on a transaction or a recurring rule.
TransactionKind parseTransactionKind(String value) {
  return switch (value) {
    'income' => TransactionKind.income,
    'expense' => TransactionKind.expense,
    'transfer' => TransactionKind.transfer,
    _ => throw ArgumentError.value(value, 'value', 'unknown transaction kind'),
  };
}

extension TransactionKindLabel on TransactionKind {
  String get storageName => switch (this) {
    TransactionKind.income => 'income',
    TransactionKind.expense => 'expense',
    TransactionKind.transfer => 'transfer',
  };

  String get label => switch (this) {
    TransactionKind.income => 'Income',
    TransactionKind.expense => 'Expense',
    TransactionKind.transfer => 'Transfer',
  };
}

/// One posted movement.
///
/// [amountMinor] is always positive and in [currencyCode], which is the
/// source account's currency. A transfer also stores [destinationAmountMinor]
/// in the destination account's currency, computed once when it is saved so a
/// later rate change does not rewrite the posting.
class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.kind,
    required this.accountId,
    required this.amountMinor,
    required this.currencyCode,
    required this.occurredOn,
    required this.note,
    this.counterAccountId,
    this.categoryId,
    this.destinationAmountMinor,
    this.recurringRuleId,
  });

  final String id;
  final TransactionKind kind;
  final String accountId;
  final String? counterAccountId;
  final String? categoryId;
  final int amountMinor;
  final int? destinationAmountMinor;
  final String currencyCode;
  final DateTime occurredOn;
  final String note;
  final String? recurringRuleId;

  LedgerTransaction copyWith({
    TransactionKind? kind,
    String? accountId,
    String? counterAccountId,
    bool clearCounter = false,
    String? categoryId,
    bool clearCategory = false,
    int? amountMinor,
    int? destinationAmountMinor,
    bool clearDestination = false,
    String? currencyCode,
    DateTime? occurredOn,
    String? note,
    String? recurringRuleId,
    bool clearRecurring = false,
  }) {
    return LedgerTransaction(
      id: id,
      kind: kind ?? this.kind,
      accountId: accountId ?? this.accountId,
      counterAccountId: clearCounter
          ? null
          : counterAccountId ?? this.counterAccountId,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      amountMinor: amountMinor ?? this.amountMinor,
      destinationAmountMinor: clearDestination
          ? null
          : destinationAmountMinor ?? this.destinationAmountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      occurredOn: occurredOn ?? this.occurredOn,
      note: note ?? this.note,
      recurringRuleId: clearRecurring
          ? null
          : recurringRuleId ?? this.recurringRuleId,
    );
  }
}
