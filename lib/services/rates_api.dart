import 'dart:convert';
import 'package:http/http.dart' as http;

class RatesApi {
  // Aggiungi o rimuovi simboli come preferisci
  static const _symbols = ['USD', 'GBP'];

  Future<Map<String, double>> fetchRates() async {
    final url = Uri.parse(
      'https://api.frankfurter.app/latest?from=EUR&to=${_symbols.join(",")}',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Errore tassi: HTTP ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final rates = (json['rates'] as Map).map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    );
    return rates;
  }
}