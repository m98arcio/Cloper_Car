import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:concessionario_supercar/widgets/brand_logo.dart';

void main() {
  testWidgets('BrandLogo senza imagePath mostra la lettera del brand',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BrandLogo(brand: 'Ferrari', size: 72)),
    ));

    expect(find.text('F'), findsOneWidget);
    expect(find.byType(BrandLogo), findsOneWidget);
  });

  testWidgets('BrandLogo con imagePath vuoto usa comunque il placeholder',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BrandLogo(brand: 'Lamborghini', imagePath: '', size: 64, round: false),
      ),
    ));
    expect(find.text('L'), findsOneWidget);
  });
}