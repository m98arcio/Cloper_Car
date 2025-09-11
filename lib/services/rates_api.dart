import 'dart:convert';
import 'package:http/http.dart' as http;

class RatesApi {
  // Uses exchangerate.host (no key)
  static const _endpoint = 'https://api.exchangerate.host/latest?base=EUR&symbols=USD,GBP';

  Future<Map<String, double>> fetchRates() async {
    final r = await http.get(Uri.parse(_endpoint));
    if (r.statusCode != 200) {
      throw Exception('Errore nel caricamento tassi');
    }
    final data = json.decode(r.body) as Map<String, dynamic>;
    final rates = (data['rates'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble()));
    return {'USD': rates['USD']!, 'GBP': rates['GBP']!};
  }
}
