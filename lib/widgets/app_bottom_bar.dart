import 'package:flutter/material.dart';
import '../models/car.dart';
import '../screens/brand_catalog_page.dart';
import '../screens/incoming_page.dart';
import '../screens/profile_page.dart';

class AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<Car> cars;
  final Map<String, double>? rates;
  final String preferredCurrency;
  final VoidCallback onProfileTap;

  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.cars,
    required this.rates,
    required this.preferredCurrency,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.redAccent,
      unselectedItemColor: Colors.grey.shade400,
      backgroundColor: Colors.black.withOpacity(0.15),
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        if (i == 0) {
          // Home
          Navigator.popUntil(context, (r) => r.isFirst);
        } else if (i == 1) {
          // Catalogo
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BrandCatalogPage(
                cars: cars,
                rates: rates,
                preferredCurrency: preferredCurrency,
              ),
            ),
          );
        } else if (i == 2) {
          // In arrivo (filtra incoming == true)
          final incomingCars = cars.where((c) => c.incoming).toList();
          if (incomingCars.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nessuna auto in arrivo.')),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IncomingPage(cars: cars),
            ),
          );
        } else if (i == 3) {
          // Profilo
          onProfileTap();
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Catalogo'),
        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'In arrivo'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilo'),
      ],
    );
  }
}