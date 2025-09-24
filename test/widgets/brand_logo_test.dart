import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:concessionario_supercar/widgets/brand_logo.dart';

void main() {
  testWidgets('BrandLogo renders for Ferrari without crashing', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BrandLogo(brand: 'Ferrari'),
      ),
    ));

    // Il widget è presente nell'albero
    expect(find.byType(BrandLogo), findsOneWidget);
  });
}