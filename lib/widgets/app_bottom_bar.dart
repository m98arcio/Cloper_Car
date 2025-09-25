import 'package:flutter/material.dart';
import '../models/car.dart';
import '../screens/brand_catalog_page.dart';
import '../screens/incoming_page.dart';

// Prova a tornare a una route già presente nello stack (per nome).
// Ritorna true se trovata, false se non esiste.
bool _popUntilName(BuildContext context, String name) {
  var found = false;
  Navigator.popUntil(context, (route) {
    if (route.settings.name == name) found = true;
    // fermati se l'hai trovata oppure se stai per uscire dalla prima
    return found || route.isFirst;
  });
  return found;
}

// Se la route name è già nello stack fa pop fino a lei; altrimenti fa push.
void _navigateUnique(
  BuildContext context, {
  required String name,
  required WidgetBuilder builder,
}) {
  final exists = _popUntilName(context, name);
  if (!exists) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(name: name),
        builder: builder,
      ),
    );
  }
}

class AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<Car> cars;                 // lista “corrente” (es. filtrata/ordinata)
  final List<Car>? allCars;             // lista completa, se disponibile
  final Map<String, double>? rates;
  final String preferredCurrency;
  final VoidCallback onProfileTap;      // lasciato come callback esterno

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
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey.shade400,
      backgroundColor: Colors.black.withOpacity(0.95),
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        if (i == 0) {
          // HOME: se ha un nome, prova a tornarci; altrimenti pop fino alla prima.
          final wentHome = _popUntilName(context, '/home');
          if (!wentHome) {
            Navigator.popUntil(context, (r) => r.isFirst);
          }
        } else if (i == 1) {
          // CATALOGO: evita duplicati
          _navigateUnique(
            context,
            name: '/catalog',
            builder: (_) => BrandCatalogPage(
              cars: allCars ?? cars,
              rates: rates,
              preferredCurrency: preferredCurrency,
            ),
          );
        } else if (i == 2) {
          // IN ARRIVO: evita duplicati
          _navigateUnique(
            context,
            name: '/incoming',
            builder: (_) => IncomingPage(
              cars: allCars ?? cars,
              allCars: allCars ?? cars,
            ),
          );
        } else if (i == 3) {
          // PROFILO: puoi lasciare il comportamento esistente,
          // oppure applicare lo stesso pattern con un nome '/profile'
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
          child: const Icon(Icons.circle, size: 0), // placeholder per Shader
        ),
        label: label,
        // Trucco: sopra ho usato ShaderMask su un "placeholder".
        // Per mostrare l’icona vera con il gradiente:
        activeIcon: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.orangeAccent, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Icon(icon, color: Colors.white),
        ),
      );
    } else {
      return BottomNavigationBarItem(
        icon: Icon(icon),
        label: label,
      );
    }
  }
}