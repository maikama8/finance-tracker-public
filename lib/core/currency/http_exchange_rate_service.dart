import 'dart:async';

import 'package:http/http.dart' as http;

import 'exchange_rate_service.dart';
import 'scaled_rate_table.dart';

/// Live rates from the open ER API, behind [ExchangeRateService].
///
/// Kobo does not call this on startup. The settings screen fetches it when
/// asked, and keeps the offline table if the request fails. Swap the host by
/// passing a different [client] in tests, or by replacing this class with
/// another [ExchangeRateService].
class HttpExchangeRateService implements ExchangeRateService {
  HttpExchangeRateService(this._table);

  static const String host = 'open.er-api.com';

  final ScaledRateTable _table;

  static Future<HttpExchangeRateService> fetch({
    http.Client? client,
    String base = 'NGN',
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final owned = client == null;
    final httpClient = client ?? http.Client();
    try {
      final uri = Uri.https(host, '/v6/latest/$base');
      final response = await httpClient.get(uri).timeout(timeout);
      if (response.statusCode != 200) {
        throw ExchangeRateException(
          'Rate feed answered ${response.statusCode}.',
        );
      }
      return HttpExchangeRateService(
        ScaledRateTable.parseOpenErApi(response.body),
      );
    } on ExchangeRateException {
      rethrow;
    } on TimeoutException {
      throw const ExchangeRateException('Rate feed timed out.');
    } on http.ClientException {
      throw const ExchangeRateException('Rate feed could not be reached.');
    } on FormatException {
      throw const ExchangeRateException('Rate feed was not valid JSON.');
    } finally {
      if (owned) {
        httpClient.close();
      }
    }
  }

  @override
  int convertMinor({
    required int amountMinor,
    required String from,
    required String to,
  }) {
    return _table.convertMinor(amountMinor: amountMinor, from: from, to: to);
  }

  @override
  double rate({required String base, required String quote}) {
    return _table.rate(base: base, quote: quote);
  }
}
