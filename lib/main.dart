import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/currency_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CurrencyService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Concessionario SuperCar',
      theme: ThemeData.dark(useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}
