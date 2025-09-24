import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:concessionario_supercar/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Splash screen shows brand name', (tester) async {
    app.main();
    // primo frame
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // verifica testo mostrato nella splash
    expect(find.text('CloperCar'), findsOneWidget);
  });
}