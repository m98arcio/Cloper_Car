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
          cars: const <Car>[],
          allCars: const <Car>[],
          rates: null,
          preferredCurrency: 'EUR',
          onProfileTap: () => tapped.value = true,
        ),
      ),
    ));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Catalogo'), findsOneWidget);
    expect(find.text('In arrivo'), findsOneWidget);
    expect(find.text('Profilo'), findsOneWidget);

    await tester.tap(find.text('Profilo'));
    await tester.pumpAndSettle();

    expect(tapped.value, isTrue);
  });
}