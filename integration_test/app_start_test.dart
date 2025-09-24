import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:concessionario_supercar/main.dart' as app;

void main() {
  // Inizializza il binding per i test di integrazione
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App start test - l\'app si avvia e mostra la home',
      (WidgetTester tester) async {
    // Avvia la tua app come se fosse in un device reale
    app.main();

    // Attendi che tutti i frame iniziali vengano renderizzati
    await tester.pumpAndSettle();

    // Asserzione minima: la MaterialApp è presente
    expect(find.byType(MaterialApp), findsOneWidget);

    // Esempio opzionale: controlla che un testo della tua home sia visibile
    // expect(find.text('Concessionario Supercar'), findsOneWidget);
  });
}