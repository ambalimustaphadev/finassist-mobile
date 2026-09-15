import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final fxRateServiceProvider = Provider<FxRateService>((ref) => FxRateService());

/// A snapshot of exchange rates relative to [base] as of [asOf] — a daily
/// reference rate (not a live market tick), from a free, keyless public
/// endpoint. Callers must present this honestly (e.g. "as of" plus the
/// date), never as real-time market data.
class FxRates {
  const FxRates({required this.base, required this.rates, required this.asOf});

  final String base;
  final Map<String, double> rates;
  final DateTime asOf;

  double? rateFor(String currencyCode) => rates[currencyCode.toUpperCase()];
}

class FxRateServiceException implements Exception {
  const FxRateServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Fetches exchange rates from `open.er-api.com` — free, no API key, no
/// signup, and (unlike ECB-sourced feeds such as Frankfurter) it publishes a
/// rate for NGN, which matters since this app is Naira-centric. On any
/// failure this throws rather than returning a fabricated/zero rate — every
/// caller must treat "no rate" as a real possibility and omit or offer a
/// manual-entry fallback instead of guessing.
class FxRateService {
  FxRateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://open.er-api.com/v6/latest';

  Future<FxRates> getRates(String baseCurrency) async {
    final Uri uri;
    try {
      uri = Uri.parse('$_baseUrl/${baseCurrency.toUpperCase()}');
    } catch (_) {
      throw const FxRateServiceException('Invalid currency code.');
    }

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const FxRateServiceException(
        "Couldn't reach the exchange rate service.",
      );
    }

    if (response.statusCode != 200) {
      throw const FxRateServiceException('Exchange rates are unavailable.');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const FxRateServiceException('Received an unexpected response.');
    }

    if (body['result'] != 'success') {
      throw const FxRateServiceException('Exchange rates are unavailable.');
    }

    final ratesJson = body['rates'] as Map<String, dynamic>?;
    if (ratesJson == null) {
      throw const FxRateServiceException('Exchange rates are unavailable.');
    }

    final rates = ratesJson.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    final updatedUnix = body['time_last_update_unix'] as int?;
    final asOf = updatedUnix != null
        ? DateTime.fromMillisecondsSinceEpoch(updatedUnix * 1000)
        : DateTime.now();

    return FxRates(base: baseCurrency.toUpperCase(), rates: rates, asOf: asOf);
  }
}
