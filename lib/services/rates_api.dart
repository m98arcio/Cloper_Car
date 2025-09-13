import 'dart:convert';
import 'package:http/http.dart' as http;

/// Converte da EUR verso altre valute usando Frankfurter (no API key).
/// Ritorna ad es.: { 'USD': 1.09, 'GBP': 0.84 } oppure null se fallisce.
class RatesApi {
  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Android 14; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
    'Accept': 'application/json,text/plain,*/*',
  };

  Future<Map<String, double>?> fetchRates() async {
    final uri = Uri.parse(
        'https://api.frankfurter.app/latest?from=EUR&to=USD,GBP');

    try {
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;

      final body = utf8.decode(res.bodyBytes);
      final decoded = json.decode(body) as Map<String, dynamic>;
      final rates = (decoded['rates'] as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      );
      return Map<String, double>.from(rates);
    } catch (_) {
      return null; // in Home gestisci già il fallback a EUR
    }
  }
}