import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:concessionario_supercar/widgets/dark_live_background.dart';

void main() {
  testWidgets('DarkLiveBackground si costruisce senza eccezioni',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: DarkLiveBackground()),
    ));

    expect(find.byType(DarkLiveBackground), findsOneWidget);
  });
}