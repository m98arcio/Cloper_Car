import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/car.dart';
import '../widgets/dark_live_background.dart';
import '../widgets/app_bottom_bar.dart';
import '../screens/car_list_page.dart';
import '../screens/Incoming_page.dart';
import '../screens/profile_page.dart';
import '../services/rates_api.dart';

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
  String _preferredCurrency = 'EUR';
  Map<String, double>? _rates;

  @override
  void initState() {
    super.initState();
    _preferredCurrency = widget.preferredCurrency;
    _rates = widget.rates;
    _bootstrapPreferences();
  }

  Future<void> _bootstrapPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferred = prefs.getString('preferred_currency') ?? 'EUR';
      setState(() => _preferredCurrency = preferred);

      final ratesApi = RatesApi();
      Map<String, double>? rates;
      try {
        rates = await ratesApi.fetchRates();
      } catch (_) {
        rates = null;
      }
      if (mounted) setState(() => _rates = rates);
    } catch (_) {}
  }

  Future<void> _openProfile() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          initialCurrency: _preferredCurrency,
          onChanged: (c) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('preferred_currency', c);
          }, cars: [],
        ),
      ),
    );

    if (changed == true) {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _preferredCurrency = prefs.getString('preferred_currency') ?? 'EUR';
      });
    }
  }

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
                final cover = thumbs[brand] ?? 'assets/macchine/mclaren.jpg';
                final logo = logos[brand] ?? 'assets/macchine/mclaren_logo.png';
                final isPressed = _pressed[brand] ?? false;

                return GestureDetector(
                  onTapDown: (_) => setState(() => _pressed[brand] = true),
                  onTapUp: (_) {
                    setState(() => _pressed[brand] = false);
                    final filtered =
                        widget.cars.where((c) => c.brand.toLowerCase() == brand.toLowerCase()).toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CarListPage(
                          brand: brand,
                          cars: filtered,
                          rates: _rates,
                          preferredCurrency: _preferredCurrency,
                        ),
                      ),
                    );
                  },
                  onTapCancel: () => setState(() => _pressed[brand] = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    transform: Matrix4.identity()..scale(isPressed ? 0.97 : 1.0),
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
                                      shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
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
bottomNavigationBar: AppBottomBar(
  currentIndex: 1, // Catalogo
  cars: widget.cars,
  rates: widget.rates,
  preferredCurrency: widget.preferredCurrency,
  onProfileTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          initialCurrency: widget.preferredCurrency,
          onChanged: (_) {},
          cars: widget.cars,
          rates: widget.rates,
        ),
      ),
    );
  },
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
        'Bugatti': 'assets/macchine/bugatti.jpg',
        'Ferrari': 'assets/macchine/ferrari.jpg',
        'Lamborghini': 'assets/macchine/lamborghini.jpg',
        'McLaren': 'assets/macchine/mclaren.jpg',
        'Porsche': 'assets/macchine/porsche.jpg',
        'Rolls-Royce': 'assets/macchine/rolls_royce.jpg',
        'Aston Martin': 'assets/macchine/aston_martin.jpg',
        'Maserati': 'assets/macchine/maserati.jpg',
        'Bentley': 'assets/macchine/bentley.jpg',
        'Koenigsegg': 'assets/macchine/koenigsegg.jpg',
        'Pagani': 'assets/macchine/pagani.jpg',
        'Jaguar': 'assets/macchine/jaguar.jpg',
        'Lotus': 'assets/macchine/lotus.jpg',
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
        'Pagani': 'assets/loghi/pagani.png',
        'Jaguar': 'assets/loghi/jaguar_logo.png',
        'Lotus': 'assets/loghi/lotus_logo.png',
      };
}
