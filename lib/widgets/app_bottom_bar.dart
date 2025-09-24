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
      selectedItemColor: Colors.white, // sarà sostituito dal gradient
      unselectedItemColor: Colors.grey.shade400,
      backgroundColor: Colors.black.withValues(alpha: 0.95),
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
      items: [
        _buildGradientIconItem(Icons.home, 'Home', 0),
        _buildGradientIconItem(Icons.directions_car, 'Catalogo', 1),
        _buildGradientIconItem(Icons.local_shipping, 'In arrivo', 2),
        _buildGradientIconItem(Icons.person, 'Profilo', 3),
      ],
    );
  }

  BottomNavigationBarItem _buildGradientIconItem(
      IconData icon, String label, int index) {
    if (index == currentIndex) {
      return BottomNavigationBarItem(
        icon: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.orangeAccent, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Icon(icon, color: Colors.white),
        ),
        label: label,
      );
    } else {
      return BottomNavigationBarItem(
        icon: Icon(icon),
        label: label,
      );
    }
  }
}
