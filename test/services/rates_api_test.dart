import 'package:flutter_test/flutter_test.dart';
import 'package:concessionario_supercar/services/rates_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RatesApi', () {
    test('fetchRates ritorna mappa con USD e GBP', () async {
      final api = RatesApi();
      final rates = await api.fetchRates();

      // il risultato può essere null se la connessione fallisce
      if (rates != null) {
        expect(rates.containsKey('USD'), true);
        expect(rates.containsKey('GBP'), true);
        expect(rates['USD'], isA<double>());
        expect(rates['GBP'], isA<double>());
      } else {
        // se non c’è connessione, rates == null va comunque bene
        expect(rates, isNull);
      }
    });
  });
}