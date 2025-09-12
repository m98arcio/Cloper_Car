import 'dart:convert';
import 'package:http/http.dart' as http;

/// Wrapper minimale per CarQuery API (no API key).
/// Doc: https://www.carqueryapi.com/documentation/api-usage/
class CarQueryApi {
  static const _base = 'https://www.carqueryapi.com/api/0.3/';

  /// Ritorna una lista di "trims" (versioni) per marca/modello/anno.
  /// Se `model` è null, prende tutti i modelli della marca per l'anno.
  static Future<List<Map<String, dynamic>>> getTrims({
    required String make,
    int? year,
    String? model,
  }) async {
    final params = {
      'cmd': 'getTrims',
      'make': make.toLowerCase(),
      if (year != null) 'year': '$year',
      if (model != null) 'model': model.toLowerCase(),
      'full_results': '0',
      'sold_in_us': '0', // non filtriamo per US
    };

    final uri = Uri.parse(_base).replace(queryParameters: {
      ...params,
      // CarQuery spesso usa JSONP; "callback=?" fa restituire JSON testuale
      'callback': '?'
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('CarQuery error ${res.statusCode}');
    }

    // Risposta es: "?({...json...});"
    final body = res.body.trim();
    final jsonStart = body.indexOf('{');
    final jsonEnd = body.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) {
      return [];
    }
    final jsonStr = body.substring(jsonStart, jsonEnd + 1);
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final trims = (data['Trims'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return trims;
  }
}