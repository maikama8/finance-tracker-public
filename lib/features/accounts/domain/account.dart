/// Where an account's money sits.
enum AccountKind { cash, bank, mobileMoney }

/// Reads the kind stored on an account row.
AccountKind parseAccountKind(String value) {
  return switch (value) {
    'cash' => AccountKind.cash,
    'bank' => AccountKind.bank,
    'mobileMoney' => AccountKind.mobileMoney,
    _ => throw ArgumentError.value(value, 'value', 'unknown account kind'),
  };
}

extension AccountKindLabel on AccountKind {
  String get storageName => switch (this) {
    AccountKind.cash => 'cash',
    AccountKind.bank => 'bank',
    AccountKind.mobileMoney => 'mobileMoney',
  };

  String get label => switch (this) {
    AccountKind.cash => 'Cash',
    AccountKind.bank => 'Bank',
    AccountKind.mobileMoney => 'Mobile money',
  };
}

/// A wallet. The balance is not stored: it is the opening balance plus the
/// transactions posted to this account.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.currencyCode,
    required this.openingBalanceMinor,
    required this.color,
    required this.createdAt,
    this.institution,
    this.archived = false,
  });

  final String id;
  final String name;
  final AccountKind kind;
  final String currencyCode;
  final int openingBalanceMinor;
  final String? institution;
  final int color;
  final bool archived;
  final DateTime createdAt;

  Account copyWith({
    String? name,
    AccountKind? kind,
    String? currencyCode,
    int? openingBalanceMinor,
    String? institution,
    bool clearInstitution = false,
    int? color,
    bool? archived,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      currencyCode: currencyCode ?? this.currencyCode,
      openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
      institution: clearInstitution ? null : institution ?? this.institution,
      color: color ?? this.color,
      archived: archived ?? this.archived,
      createdAt: createdAt,
    );
  }
}
