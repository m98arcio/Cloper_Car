import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/car.dart';
import 'car_list_page.dart';
import 'auctions_swiper_page.dart';
import 'profile_page.dart';
import '../widgets/dark_live_background.dart';

class BrandCatalogPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final brands = _uniqueBrands(cars);
    final thumbs = _brandThumbnails(cars);

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
            fontFamily: 'Cinzel', // font elegante solo per titolo
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
                final b = brands[i];
                final cover = thumbs[b] ?? 'assets/supercar.jpg';
                return InkWell(
                  onTap: () {
                    final filtered =
                        cars
                            .where(
                              (c) => c.brand.toLowerCase() == b.toLowerCase(),
                            )
                            .toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CarListPage(
                              brand: b,
                              cars: filtered,
                              rates: rates,
                              preferredCurrency: preferredCurrency,
                            ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFEF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(blurRadius: 10, color: Colors.black45),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            cover,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Center(
                            child: Text(
                              b,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cinzelDecorative(
                                textStyle: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE5C07B),
                                  letterSpacing: 1.4,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Catalogo attivo
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.black.withOpacity(0.15),
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          if (i == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (i == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AuctionsSwiperPage(cars: cars)),
            );
          } else if (i == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ProfilePage(
                      initialCurrency: preferredCurrency,
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

  List<String> _uniqueBrands(List<Car> cars) {
    final s = <String>{};
    for (final c in cars) s.add(c.brand);
    final list = s.toList()..sort();
    return list;
  }

  Map<String, String> _brandThumbnails(List<Car> cars) {
    final map = <String, String>{};
    for (final c in cars) {
      if (!map.containsKey(c.brand) && c.images.isNotEmpty) {
        map[c.brand] = c.images.first;
      }
    }
    return map;
  }
}
