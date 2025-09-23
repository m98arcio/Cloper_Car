import 'package:flutter/material.dart';
import '../models/car.dart';
import '../screens/brand_catalog_page.dart';
import '../screens/incoming_page.dart';

class AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<Car> cars;
  final List<Car>? allCars;
  final Map<String, double>? rates;
  final String preferredCurrency;
  final VoidCallback onProfileTap;

  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.cars,
    this.allCars,
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
      backgroundColor: Colors.black.withOpacity(0.95),
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        if (i == 0) {
          Navigator.popUntil(context, (r) => r.isFirst);
        } else if (i == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BrandCatalogPage(
                cars: allCars ?? cars,
                rates: rates,
                preferredCurrency: preferredCurrency,
              ),
            ),
          );
        } else if (i == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IncomingPage(
                cars: allCars ?? cars,
                allCars: null,
              ),
            ),
          );
        } else if (i == 3) {
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