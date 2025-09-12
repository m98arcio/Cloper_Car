import 'package:flutter/material.dart';
import '../models/car.dart';

class AuctionsSwiperPage extends StatefulWidget {
  final List<Car> cars;
  const AuctionsSwiperPage({super.key, required this.cars});

  @override
  State<AuctionsSwiperPage> createState() => _AuctionsSwiperPageState();
}

class _AuctionsSwiperPageState extends State<AuctionsSwiperPage> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cars = widget.cars;
    return Scaffold(
      body: Stack(
        children: [
          // pagine a scorrimento orizzontale
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: cars.length,
            itemBuilder: (_, i) => _AuctionSlide(car: cars[i]),
          ),

          // indicatori tipo onboarding
          Positioned(
            bottom: 16,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(cars.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: active ? 22 : 8,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuctionSlide extends StatelessWidget {
  final Car car;
  const _AuctionSlide({required this.car});

  @override
  Widget build(BuildContext context) {
    final bg = _brandBackground(car.brand);

    // userò la prima immagine disponibile degli asset
    final imagePath = car.images.isNotEmpty ? car.images.first : 'assets/supercar.jpg';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bg,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Headline
            const Text(
              'Find Your',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'DREAM CAR',
              style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Container(
              width: 56, height: 4,
              decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 18),

            // chip brand
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(28),
              ),
              child: Text(
                car.brand.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1.1),
              ),
            ),

            const SizedBox(height: 18),

            // immagine auto
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // descrizione breve
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _taglineForBrand(car.brand),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.35),
              ),
            ),

            // “prezzo di partenza” (al posto del pulsante Explore)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
              ),
              child: Text(
                'Prezzo di partenza: € ${car.priceEur.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Palette di sfondo per dare “mood” tipo video
  List<Color> _brandBackground(String brand) {
    switch (brand.toLowerCase()) {
      case 'ferrari':
        return [const Color(0xFF1976D2), const Color(0xFF0D47A1)]; // blu profondo (come screenshot BMW)
      case 'lamborghini':
        return [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]; // verde
      case 'mclaren':
        return [const Color(0xFF37474F), const Color(0xFF263238)]; // grigio scuro
      case 'bugatti':
        return [const Color(0xFF546E7A), const Color(0xFF37474F)]; // blu/grey
      default:
        return [const Color(0xFF303030), const Color(0xFF121212)];
    }
  }

  String _taglineForBrand(String brand) {
    switch (brand.toLowerCase()) {
      case 'ferrari':
        return 'Italian performance with precision and power.';
      case 'lamborghini':
        return 'Raw design and uncompromised performance.';
      case 'mclaren':
        return 'Lightweight engineering for pure speed and control.';
      case 'bugatti':
        return 'Unmatched luxury with extraordinary power.';
      default:
        return 'Excellence in performance and luxury.';
    }
  }
}