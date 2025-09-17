import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/car.dart';
import 'car_list_page.dart';
import 'Incoming_page.dart'; // ⬅ per CarAuction e AuctionPage
import 'profile_page.dart';
import '../widgets/dark_live_background.dart';

class BrandCatalogPage extends StatefulWidget {
  final List<Car> cars;
  final Map<String, double>? rates;
  final String preferredCurrency;

  const BrandCatalogPage({
    super.key,
    required this.cars,
    this.rates,
    required this.preferredCurrency,
  });

  @override
  State<BrandCatalogPage> createState() => _BrandCatalogPageState();
}

class _BrandCatalogPageState extends State<BrandCatalogPage> {
  final Map<String, bool> _pressed = {};

  @override
  Widget build(BuildContext context) {
    final brands = _luxuryBrands();
    final thumbs = _brandThumbnails();
    final logos = _brandLogos();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Catalogo',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            color: Colors.white,
            fontFamily: 'Cinzel',
            shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
          ),
        ),
      ),
      body: Stack(
        children: [
          const DarkLiveBackground(),
          SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: brands.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final brand = brands[i];
                final cover = thumbs[brand] ?? 'assets/images/mclaren.jpg';
                final logo = logos[brand] ?? 'assets/images/mclaren_logo.png';
                final isPressed = _pressed[brand] ?? false;

                return GestureDetector(
                  onTapDown: (_) => setState(() => _pressed[brand] = true),
                  onTapUp: (_) {
                    setState(() => _pressed[brand] = false);
                    final filtered =
                        widget.cars
                            .where(
                              (c) =>
                                  c.brand.toLowerCase() == brand.toLowerCase(),
                            )
                            .toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CarListPage(
                              brand: brand,
                              cars: filtered,
                              rates: widget.rates,
                              preferredCurrency: widget.preferredCurrency,
                            ),
                      ),
                    );
                  },
                  onTapCancel: () => setState(() => _pressed[brand] = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    transform:
                        Matrix4.identity()..scale(isPressed ? 0.97 : 1.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              logo,
                              height: 60,
                              width: 60,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Center(
                                child: Text(
                                  brand,
                                  style: GoogleFonts.cinzelDecorative(
                                    textStyle: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 6,
                                          color: Colors.black87,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            cover,
                            width: double.infinity,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.black.withOpacity(0.15),
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          if (i == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (i == 2) {
            final auctionCars = widget.cars.where((c) => c.incoming).toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IncomingPage(cars: auctionCars),
              ),
            );
          } else if (i == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ProfilePage(
                      initialCurrency: widget.preferredCurrency,
                      onChanged: (_) {},
                    ),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Catalogo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Aste'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilo'),
        ],
      ),
    );
  }

  // ------ helpers di pagina (invariati) ------
  List<String> _luxuryBrands() => [
    'Bugatti',
    'Ferrari',
    'Lamborghini',
    'McLaren',
    'Porsche',
    'Rolls-Royce',
    'Aston Martin',
    'Maserati',
    'Bentley',
    'Koenigsegg',
    'Pagani',
    'Jaguar',
    'Lotus',
  ];

  Map<String, String> _brandThumbnails() => {
    'Bugatti': 'assets/bugatti.jpg',
    'Ferrari': 'assets/ferrari.jpg',
    'Lamborghini': 'assets/lamborghini.jpg',
    'McLaren': 'assets/mclaren.jpg',
    'Porsche': 'assets/porsche.jpg',
    'Rolls-Royce': 'assets/rolls_royce.jpg',
    'Aston Martin': 'assets/aston_martin.jpg',
    'Maserati': 'assets/maserati.jpg',
    'Bentley': 'assets/bentley.jpg',
    'Koenigsegg': 'assets/koenigsegg.jpg',
    'Pagani': 'assets/pagani.jpg',
    'Jaguar': 'assets/jaguar.jpg',
    'Lotus': 'assets/lotus.jpg',
  };

  Map<String, String> _brandLogos() => {
    'Bugatti': 'assets/loghi/bugatti_logo.png',
    'Ferrari': 'assets/loghi/ferrari_logo.png',
    'Lamborghini': 'assets/loghi/lamborghini_logo.png',
    'McLaren': 'assets/loghi/mclaren_logo.png',
    'Porsche': 'assets/loghi/porsche_logo.png',
    'Rolls-Royce': 'assets/loghi/rolls_royce_logo.png',
    'Aston Martin': 'assets/loghi/aston_martin_logo.png',
    'Maserati': 'assets/loghi/maserati_logo.png',
    'Bentley': 'assets/loghi/bentley_logo.png',
    'Koenigsegg': 'assets/loghi/koenigsegg_logo.png',
    'Pagani': 'assets/loghi/pagani_logo.png',
    'Jaguar': 'assets/loghi/jaguar_logo.png',
    'Lotus': 'assets/loghi/lotus_logo.png',
  };

}
