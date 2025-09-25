import 'dart:convert';
import 'package:http/http.dart' as http;

// Classe che gestisce i tassi di cambio da EUR a .... usando l'API Frankfurter.
class RatesApi {
  // Header HTTP usati nella richiesta
  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (Android 14; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
    'Accept': 'application/json,text/plain,*/*',
  };

  // Metodo che recupera i tassi di cambio
  Future<Map<String, double>?> fetchRates() async {
    // URL dell'API con valute da richiedere
    final uri =
        Uri.parse('https://api.frankfurter.app/latest?from=EUR&to=USD,GBP');

    try {
      // Richiesta HTTP GET con timeout
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      // Se la risposta non è OK -> ritorna null
      if (res.statusCode != 200) return null;

      // Decodifica il JSON della risposta
      final body = utf8.decode(res.bodyBytes);
      final decoded = json.decode(body) as Map<String, dynamic>;

      // Estrae i tassi e li converte in mappa {valuta: valore}
      final rates = (decoded['rates'] as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      );
      return Map<String, double>.from(rates);
    } catch (_) {
      // In caso di errore -> ritorna null
      return null;
    }
  }
}