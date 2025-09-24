import 'package:flutter_test/flutter_test.dart';
import 'package:concessionario_supercar/services/local_catalog.dart';
import 'package:concessionario_supercar/models/car.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalCatalog', () {
    test('load legge cars.json e ritorna lista di Car', () async {
      final cars = await LocalCatalog.load();
      expect(cars, isA<List<Car>>());
      expect(cars.isNotEmpty, true);

      final car = cars.first;
      expect(car.id, isNotEmpty);
      expect(car.brand, isNotEmpty);
      expect(car.model, isNotEmpty);
    });
  });
}