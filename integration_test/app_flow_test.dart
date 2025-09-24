import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:concessionario_supercar/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flow base: avvio, Catalogo, In arrivo, ritorno Home',
      (WidgetTester tester) async {
    // 1) Avvia l'app
    app.main();
    await tester.pumpAndSettle();

    // 2) Verifica che la Home sia caricata (bottom bar presente)
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Catalogo'), findsOneWidget);
    expect(find.text('In arrivo'), findsOneWidget);
    expect(find.text('Profilo'), findsOneWidget);

    // 3) Vai su "Catalogo"
    await tester.tap(find.text('Catalogo'));
    await tester.pumpAndSettle();

    // La pagina del catalogo dovrebbe mostrare un titolo/indicatore contenente "Catalogo"
    // (usa find.textContaining per essere più robusti a titoli personalizzati)
    expect(find.textContaining('Catalogo'), findsWidgets);

    // 4) Vai su "In arrivo"
    await tester.tap(find.text('In arrivo'));
    await tester.pumpAndSettle();

    // Verifica che la pagina "In Arrivo" sia visibile (AppBar con titolo "In Arrivo")
    expect(find.text('In Arrivo'), findsWidgets);

    // In base ai dati, potresti vedere card incoming oppure empty state:
    // Non imponiamo una condizione specifica: basta che il titolo esista.

    // 5) Torna alla Home toccando "Home"
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // Verifica di essere rientrato alla schermata principale (bottom bar sempre presente)
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}