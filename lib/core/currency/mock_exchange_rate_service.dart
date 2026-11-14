import 'currency.dart';
import 'exchange_rate_service.dart';
import 'minor_units.dart';

/// Offline rates, pivoted through the naira.
///
/// These are rounded fixtures for the demo and the tests, not live quotes.
/// One US dollar is ₦1,600. Cross rates divide through that table, so the
/// book does not need a network call to show a base-currency total.
class MockExchangeRateService implements ExchangeRateService {
  const MockExchangeRateService();

  /// Naira major units for one major unit of each currency.
  static const Map<String, int> nairaPerMajorUnit = <String, int>{
    'NGN': 1,
    'USD': 1600,
    'GBP': 2100,
    'EUR': 1750,
    'GHS': 110,
    'KES': 12,
    'ZAR': 88,
    'CAD': 1180,
  };

  static int nairaPerMajor(String code) {
    final rate = nairaPerMajorUnit[code];
    if (rate == null || rate <= 0) {
      throw ArgumentError.value(code, 'code', 'unknown currency');
    }
    return rate;
  }

  @override
  double rate({required String base, required String quote}) {
    return nairaPerMajor(base) / nairaPerMajor(quote);
  }

  @override
  int convertMinor({
    required int amountMinor,
    required String from,
    required String to,
  }) {
    if (!Currencies.isKnown(from)) {
      throw ArgumentError.value(from, 'from', 'unknown currency');
    }
    if (!Currencies.isKnown(to)) {
      throw ArgumentError.value(to, 'to', 'unknown currency');
    }
    if (from == to) return amountMinor;
    return divRound(amountMinor * nairaPerMajor(from), nairaPerMajor(to));
  }
}
