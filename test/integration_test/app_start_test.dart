import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:concessionario_supercar/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Splash screen shows brand name', (tester) async {
    // Inizializza valori mock per SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Avvia l'app
    app.main();

    // Attendi che il primo frame e tutti gli animazioni siano completate
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verifica che il testo "CloperCar" sia presente
    expect(find.text('CloperCar'), findsOneWidget);
  });
}
