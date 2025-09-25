import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const _key = 'preferred_currency'; // chiave per salvare la valuta
  static String _preferred = 'EUR'; // default EUR
  static SharedPreferences? _prefs; // memoria locale

  // inizializza caricando la valuta salvata (se esiste)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _preferred = _prefs?.getString(_key) ?? 'EUR';
  }

  // valuta attualmente preferita
  static String get preferred => _preferred;

  // salva nuova valuta nelle preferenze
  static Future<void> save(String currency) async {
    _preferred = currency;
    await _prefs?.setString(_key, currency);
  }

  // elenco valute disponibili
  static const List<Map<String, String>> currencies = [
    {'code': 'EUR', 'label': 'Euro (€)'},
    {'code': 'USD', 'label': 'Dollaro USA (\$)'},
    {'code': 'GBP', 'label': 'Sterlina (£)'},
  ];

  // restituisce l’etichetta leggibile da un codice (es. "EUR" → "Euro (€)")
  static String labelFor(String code) {
    final match = currencies.firstWhere(
      (c) => c['code'] == code,
      orElse: () => const {'code': 'EUR', 'label': 'Euro (€)'},
    );
    return match['label']!;
  }
}