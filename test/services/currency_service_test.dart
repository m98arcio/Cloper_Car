import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:concessionario_supercar/services/currency_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CurrencyService.init();
  });

  group('CurrencyService', () {
    test('default preferred = EUR', () {
      expect(CurrencyService.preferred, 'EUR');
      expect(CurrencyService.labelFor('EUR'), 'Euro (€)');
    });

    test('save + reload mantiene la valuta scelta', () async {
      await CurrencyService.save('USD');
      expect(CurrencyService.preferred, 'USD');

      await CurrencyService.init(); // simula riavvio app
      expect(CurrencyService.preferred, 'USD');
    });

    test('labelFor ritorna Euro se codice sconosciuto', () {
      expect(CurrencyService.labelFor('XYZ'), 'Euro (€)');
    });
  });
}
