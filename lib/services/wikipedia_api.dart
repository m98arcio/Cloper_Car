import 'dart:convert';
import 'package:http/http.dart' as http;

/// Wikipedia REST Summary (no key).
/// Doc: https://wikimedia.org/api/rest_v1/
class WikipediaApi {
  static Future<String?> getSummary(String title, {String lang = 'en'}) async {
    final t = title.replaceAll(' ', '_');
    final uri = Uri.parse(
      'https://$lang.wikipedia.org/api/rest_v1/page/summary/$t',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = json.decode(res.body) as Map<String, dynamic>;
    return (data['extract'] as String?)?.trim();
  }
}