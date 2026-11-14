import 'dart:convert';

import 'exchange_rate_service.dart';
import 'minor_units.dart';

/// Rates expressed as major units of each currency per one major unit of a pivot.
///
/// A live feed usually publishes "foreign per 1 NGN". Conversion uses an
/// integer scale so a parsed quote does not drift through repeated doubles.
class ScaledRateTable implements ExchangeRateService {
  ScaledRateTable({required this.pivot, required Map<String, double> perPivot})
    : _scaled = <String, int>{
        for (final entry in perPivot.entries)
          entry.key: _scale(entry.value, entry.key),
      };

  static const int scale = 100000000;

  final String pivot;
  final Map<String, int> _scaled;

  /// Parses an open.er-api.com `latest` document.
  ///
  /// The `rates` object is major units of each currency per one unit of
  /// `base_code`. `result` must be `success`.
  factory ScaledRateTable.parseOpenErApi(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const ExchangeRateException('Rate feed was not a JSON object.');
    }
    if (decoded['result'] != 'success') {
      throw const ExchangeRateException('Rate feed did not succeed.');
    }
    final base = decoded['base_code'];
    final rates = decoded['rates'];
    if (base is! String || base.isEmpty || rates is! Map) {
      throw const ExchangeRateException('Rate feed is missing base or rates.');
    }
    final perPivot = <String, double>{};
    for (final entry in rates.entries) {
      final code = entry.key;
      final value = entry.value;
      if (code is! String || value is! num || value <= 0) {
        throw const ExchangeRateException('Rate feed has an unusable quote.');
      }
      perPivot[code] = value.toDouble();
    }
    if (!perPivot.containsKey(base)) {
      perPivot[base] = 1;
    }
    return ScaledRateTable(pivot: base, perPivot: perPivot);
  }

  static int _scale(double value, String code) {
    if (value <= 0 || value.isNaN || value.isInfinite) {
      throw ArgumentError.value(code, 'code', 'rate must be positive');
    }
    return (value * scale).round();
  }

  int _require(String code) {
    final scaled = _scaled[code];
    if (scaled == null || scaled <= 0) {
      throw ArgumentError.value(code, 'code', 'unknown currency');
    }
    return scaled;
  }

  @override
  double rate({required String base, required String quote}) {
    final baseScaled = _require(base);
    final quoteScaled = _require(quote);
    return quoteScaled / baseScaled;
  }

  @override
  int convertMinor({
    required int amountMinor,
    required String from,
    required String to,
  }) {
    if (from == to) return amountMinor;
    final fromPerPivot = _require(from);
    final toPerPivot = _require(to);
    final pivotMinor = divRound(amountMinor * scale, fromPerPivot);
    return divRound(pivotMinor * toPerPivot, scale);
  }
}
