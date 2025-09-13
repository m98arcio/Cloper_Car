import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/car.dart';
import 'brand_catalog_page.dart';
import 'profile_page.dart';

class AuctionsSwiperPage extends StatefulWidget {
  final List<Car> cars;
  const AuctionsSwiperPage({super.key, required this.cars});

  @override
  State<AuctionsSwiperPage> createState() => _AuctionsSwiperPageState();
}

class _AuctionsSwiperPageState extends State<AuctionsSwiperPage> {
  int _currentIndex = 2; // BottomNavigationBar indice
  late PageController _pageController;
  static const int _initialPage = 1000; // per simulare il loop infinito

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _realIndex(int page) {
    final count = widget.cars.length;
    if (count == 0) return 0;
    return page % count;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cars.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aste')),
        body: const Center(child: Text('Nessuna auto in asta al momento')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) {},
        itemBuilder: (_, pageIndex) {
          final car = widget.cars[_realIndex(pageIndex)];
          return _AuctionSlide(car: car);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.black.withOpacity(0.15),
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (i == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => BrandCatalogPage(
                      cars: widget.cars,
                      preferredCurrency: 'EUR', // o la tua variabile
                    ),
              ),
            );
          } else if (i == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        ProfilePage(initialCurrency: 'EUR', onChanged: (_) {}),
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
}

class _AuctionSlide extends StatelessWidget {
  final Car car;
  const _AuctionSlide({required this.car});

  Color _brandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'ferrari':
        return const Color(0xFF9B0010);
      case 'lamborghini':
        return const Color(0xFF2D2A00);
      case 'mclaren':
        return const Color(0xFF0E2A33);
      case 'bugatti':
        return const Color(0xFF1D2038);
      case 'porsche':
        return const Color(0xFF2A2A2A);
      default:
        return const Color(0xFF4A0010);
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _brandColor(car.brand);
    final size = MediaQuery.of(context).size;
    final startPrice = car.auctionStartEur ?? car.priceEur;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Sfondo gradiente
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                base.withOpacity(0.98),
                base.withOpacity(0.90),
                Colors.black.withOpacity(0.92),
              ],
            ),
          ),
        ),

        // Brand
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                car.brand.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),

        // Watermark modello
        Align(
          alignment: const Alignment(0, -0.05),
          child: IgnorePointer(
            child: Text(
              car.model.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: math.min(size.width * 0.22, 96),
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white.withOpacity(0.18),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Auto con ombra ellittica
        LayoutBuilder(
          builder: (_, c) {
            final h = math.max(320.0, c.maxHeight * 0.48);
            final shadowW = math.min(size.width * 0.75, 500.0);

            return Align(
              alignment: const Alignment(0, 0.28),
              child: SizedBox(
                height: h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      bottom: 6,
                      child: Transform.scale(
                        scaleY: 0.32,
                        child: Container(
                          width: shadowW,
                          height: shadowW,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.black.withOpacity(0.0),
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Image.asset(
                        car.images.isNotEmpty
                            ? car.images.first
                            : 'assets/supercar.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Pill prezzo
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.93),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(blurRadius: 16, color: Colors.black38),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gavel_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Prezzo di partenza: € ${_kSep(startPrice)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _kSep(double v) {
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      b.write(s[i]);
      if (idxFromEnd > 1 && (idxFromEnd - 1) % 3 == 0) b.write('.');
    }
    return b.toString();
  }
}
