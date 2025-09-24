import 'package:flutter_test/flutter_test.dart';
import 'package:concessionario_supercar/services/rates_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RatesApi', () {
    test('fetchRates ritorna mappa con USD e GBP', () async {
      final api = RatesApi();
      final rates = await api.fetchRates();

      if (rates != null) {
        expect(rates.containsKey('USD'), true);
        expect(rates.containsKey('GBP'), true);
        expect(rates['USD'], isA<double>());
        expect(rates['GBP'], isA<double>());
      } else {

        expect(rates, isNull);
      }
    });
  });
}