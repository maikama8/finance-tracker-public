/// Converts money between currencies.
///
/// Implementations may be offline fixtures or a live rate feed. Callers depend
/// only on this type, so the source of rates can change without touching
/// budgets, balances, or the screens.
abstract class ExchangeRateService {
  const ExchangeRateService();

  /// How many major units of [quote] equal one major unit of [base].
  ///
  /// `rate(base: 'USD', quote: 'NGN')` is the naira price of one dollar.
  double rate({required String base, required String quote});

  /// Converts an amount in minor units (two decimal places) from [from] to [to].
  ///
  /// The same currency returns [amountMinor] unchanged. Rounding is half away
  /// from zero. Unknown codes throw [ArgumentError].
  int convertMinor({
    required int amountMinor,
    required String from,
    required String to,
  });
}

/// A rate feed failed or returned a document this app cannot use.
class ExchangeRateException implements Exception {
  const ExchangeRateException(this.message);

  final String message;

  @override
  String toString() => message;
}
