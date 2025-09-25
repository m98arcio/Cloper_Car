import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:concessionario_supercar/services/currency_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'preferred_currency': 'USD',
    });
    await CurrencyService.init();
  });

  test('loads initial preferred currency from SharedPreferences', () async {
    expect(CurrencyService.preferred, 'USD');
  });

  test('save() updates and persists preferred currency', () async {
    await CurrencyService.save('GBP');
    expect(CurrencyService.preferred, 'GBP');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('preferred_currency'), 'GBP');
  });

  test('labelFor returns a friendly label', () {
    expect(CurrencyService.labelFor('EUR'), contains('Euro'));
  });
}
