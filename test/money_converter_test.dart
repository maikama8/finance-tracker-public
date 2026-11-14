import 'package:finance_tracker/core/currency/http_exchange_rate_service.dart';
import 'package:finance_tracker/core/currency/mock_exchange_rate_service.dart';
import 'package:finance_tracker/core/currency/scaled_rate_table.dart';
import 'package:finance_tracker/core/formatting/money_format.dart';
import 'package:finance_tracker/core/currency/minor_units.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const rates = MockExchangeRateService();

  test('naira formatting groups thousands and keeps the sign', () {
    expect(formatMinor(160000, 'NGN'), '₦1,600.00');
    expect(formatMinor(0, 'NGN'), '₦0.00');
    expect(formatMinor(-450050, 'NGN'), '-₦4,500.50');
    expect(formatMinor(1250, 'GBP'), '£12.50');
    expect(formatSignedMinor(85000000, 'NGN'), '+₦850,000.00');
    expect(parseMoneyInput('48,600.50'), 4860050);
    expect(parseMoneyInput('12.5'), 1250);
    expect(parseMoneyInput(''), isNull);
    expect(parseMoneyInput('0'), isNull);
    expect(parseMoneyInput('0', allowZero: true), 0);
    expect(parseMoneyInput('1.234'), isNull);
  });

  test('identity, dollar, and cross rates use integer rounding', () {
    expect(
      rates.convertMinor(amountMinor: 160000, from: 'NGN', to: 'NGN'),
      160000,
    );
    expect(
      rates.convertMinor(amountMinor: 100, from: 'USD', to: 'NGN'),
      160000,
    );
    expect(formatMinor(160000, 'NGN'), '₦1,600.00');
    // £1.00 -> dollars: 100 * 2100 / 1600 = 131.25, half rounds away to 131.
    expect(rates.convertMinor(amountMinor: 100, from: 'GBP', to: 'USD'), 131);
    expect(
      rates.convertMinor(amountMinor: -100, from: 'USD', to: 'NGN'),
      -160000,
    );
    expect(rates.rate(base: 'USD', quote: 'NGN'), 1600);
    expect(
      () => rates.convertMinor(amountMinor: 1, from: 'XXX', to: 'NGN'),
      throwsArgumentError,
    );
  });

  test('half away from zero', () {
    expect(divRound(5, 2), 3);
    expect(divRound(-5, 2), -3);
    expect(divRound(1, 2), 1);
    expect(() => divRound(1, 0), throwsArgumentError);
  });

  test('live rate document converts through the pivot', () async {
    const body = '''
{"result":"success","base_code":"NGN","rates":{"NGN":1,"USD":0.000625,"GBP":0.000476190476}}
''';
    final table = ScaledRateTable.parseOpenErApi(body);
    final dollars = table.convertMinor(
      amountMinor: 100,
      from: 'USD',
      to: 'NGN',
    );
    expect((dollars - 160000).abs() <= 1, isTrue);
    final client = MockClient((request) async {
      expect(request.url.host, HttpExchangeRateService.host);
      expect(request.url.path, '/v6/latest/NGN');
      return http.Response(body, 200);
    });
    final live = await HttpExchangeRateService.fetch(client: client);
    expect(
      live.convertMinor(amountMinor: 100, from: 'USD', to: 'NGN'),
      dollars,
    );
    expect(
      () => ScaledRateTable.parseOpenErApi('{"result":"error"}'),
      throwsA(isA<Exception>()),
    );
  });
}
