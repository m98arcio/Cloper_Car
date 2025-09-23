// lib/services/currency_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const _key = 'preferred_currency';
  static String _preferred = 'EUR'; // default
  static SharedPreferences? _prefs;

  /// Inizializza il service (da chiamare in main.dart)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _preferred = _prefs?.getString(_key) ?? 'EUR';
  }

  /// Restituisce la valuta corrente
  static String get preferred => _preferred;

  /// Imposta e salva la valuta scelta
  static Future<void> save(String currency) async {
    _preferred = currency;
    await _prefs?.setString(_key, currency);
  }

  /// Lista delle valute supportate (codice + label con simbolo)
  static const List<Map<String, String>> currencies = [
    {'code': 'EUR', 'label': 'Euro (€)'},
    {'code': 'USD', 'label': 'Dollaro USA (\$)'},
    {'code': 'GBP', 'label': 'Sterlina (£)'},
  ];

  /// Restituisce l’etichetta leggibile partendo dal codice
  static String labelFor(String code) {
    final match = currencies.firstWhere(
      (c) => c['code'] == code,
      orElse: () => const {'code': 'EUR', 'label': 'Euro (€)'},
    );
    return match['label']!;
  }
}