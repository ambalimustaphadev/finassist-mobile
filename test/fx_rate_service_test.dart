import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:finassist/core/services/fx_rate_service.dart';

void main() {
  test('parses a successful response into rates and an as-of time', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://open.er-api.com/v6/latest/USD');
      return http.Response(
        jsonEncode({
          'result': 'success',
          'time_last_update_unix': 1704067200,
          'rates': {'NGN': 1550.25, 'EUR': 0.92},
        }),
        200,
      );
    });

    final rates = await FxRateService(client: client).getRates('usd');

    expect(rates.base, 'USD');
    expect(rates.rateFor('ngn'), 1550.25);
    expect(rates.rateFor('EUR'), 0.92);
    expect(rates.rateFor('GBP'), isNull);
    expect(rates.asOf, DateTime.fromMillisecondsSinceEpoch(1704067200 * 1000));
  });

  test(
    'a non-200 response throws instead of returning a fabricated rate',
    () async {
      final client = MockClient((request) async => http.Response('', 503));

      expect(
        FxRateService(client: client).getRates('USD'),
        throwsA(isA<FxRateServiceException>()),
      );
    },
  );

  test('a malformed body throws a clear exception, not a crash', () async {
    final client = MockClient(
      (request) async => http.Response('not json', 200),
    );

    expect(
      FxRateService(client: client).getRates('USD'),
      throwsA(isA<FxRateServiceException>()),
    );
  });

  test('result != success throws instead of guessing', () async {
    final client = MockClient(
      (request) async => http.Response(jsonEncode({'result': 'error'}), 200),
    );

    expect(
      FxRateService(client: client).getRates('USD'),
      throwsA(isA<FxRateServiceException>()),
    );
  });

  test('a network failure throws a clear connection error', () async {
    final client = MockClient((request) async => throw Exception('offline'));

    expect(
      FxRateService(client: client).getRates('USD'),
      throwsA(isA<FxRateServiceException>()),
    );
  });
}
