import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const _key = 'preferred_currency';
  static String _preferred = 'EUR';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _preferred = _prefs?.getString(_key) ?? 'EUR';
  }

  static String get preferred => _preferred;

  static Future<void> save(String currency) async {
    _preferred = currency;
    await _prefs?.setString(_key, currency);
  }

  static const List<Map<String, String>> currencies = [
    {'code': 'EUR', 'label': 'Euro (€)'},
    {'code': 'USD', 'label': 'Dollaro USA (\$)'},
    {'code': 'GBP', 'label': 'Sterlina (£)'},
  ];

  static String labelFor(String code) {
    final match = currencies.firstWhere(
      (c) => c['code'] == code,
      orElse: () => const {'code': 'EUR', 'label': 'Euro (€)'},
    );
    return match['label']!;
  }
}