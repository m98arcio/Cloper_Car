import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:concessionario_supercar/widgets/app_bottom_bar.dart';
import 'package:concessionario_supercar/models/car.dart';

void main() {
  testWidgets('AppBottomBar rende le quattro voci e chiama onProfileTap',
      (WidgetTester tester) async {
    final tapped = ValueNotifier<bool>(false);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: const SizedBox(),
        bottomNavigationBar: AppBottomBar(
          currentIndex: 0,
          cars: const <Car>[],          // lista vuota ok per il test
          allCars: const <Car>[],       // opzionale; passata per sicurezza
          rates: null,
          preferredCurrency: 'EUR',
          onProfileTap: () => tapped.value = true,
        ),
      ),
    ));

    // Verifica etichette
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Catalogo'), findsOneWidget);
    expect(find.text('In arrivo'), findsOneWidget);
    expect(find.text('Profilo'), findsOneWidget);

    // Tap su Profilo deve invocare la callback, non navigare
    await tester.tap(find.text('Profilo'));
    await tester.pumpAndSettle();

    expect(tapped.value, isTrue);
  });
}