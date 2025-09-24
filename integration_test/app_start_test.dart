import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:concessionario_supercar/main.dart' as app;
import 'package:concessionario_supercar/main.dart' show MyApp;

void main() {
  // binding di integrazione
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App start test: l\'app si avvia e mostra la root',
      (WidgetTester tester) async {
    // Avvia la tua app
    await app.main();

    // Attendi il primo frame (la SplashScreen verrà mostrata)
    await tester.pump();

    // Verifica che l'app sia partita (MyApp è costruita)
    expect(find.byType(MyApp), findsOneWidget);

    // Se vuoi essere più esplicito:
    // expect(find.byType(SplashScreen), findsOneWidget);
  });
}