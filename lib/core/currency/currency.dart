/// A currency the ledger can store.
///
/// Amounts are minor units with two decimal places: kobo, cents, pence.
class Currency {
  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  final String code;
  final String name;
  final String symbol;
}

/// Currencies shipped with Kobo. NGN is the default base.
class Currencies {
  const Currencies._();

  static const ngn = Currency(code: 'NGN', name: 'Nigerian naira', symbol: '₦');
  static const usd = Currency(code: 'USD', name: 'US dollar', symbol: r'$');
  static const gbp = Currency(code: 'GBP', name: 'Pound sterling', symbol: '£');
  static const eur = Currency(code: 'EUR', name: 'Euro', symbol: '€');
  static const ghs = Currency(
    code: 'GHS',
    name: 'Ghanaian cedi',
    symbol: 'GH₵',
  );
  static const kes = Currency(
    code: 'KES',
    name: 'Kenyan shilling',
    symbol: 'KSh',
  );
  static const zar = Currency(
    code: 'ZAR',
    name: 'South African rand',
    symbol: 'R',
  );
  static const cad = Currency(
    code: 'CAD',
    name: 'Canadian dollar',
    symbol: r'C$',
  );

  static const String defaultBase = 'NGN';

  static const List<Currency> all = <Currency>[
    ngn,
    usd,
    gbp,
    eur,
    ghs,
    kes,
    zar,
    cad,
  ];

  static Currency byCode(String code) {
    for (final currency in all) {
      if (currency.code == code) return currency;
    }
    throw ArgumentError.value(code, 'code', 'unknown currency');
  }

  static bool isKnown(String code) {
    for (final currency in all) {
      if (currency.code == code) return true;
    }
    return false;
  }

  static String symbolFor(String code) => byCode(code).symbol;
}
