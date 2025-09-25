import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/car.dart';
import '../widgets/dark_live_background.dart';
import '../widgets/app_bottom_bar.dart';
import '../screens/car_list_page.dart';
import '../screens/profile_page.dart';
import '../services/rates_api.dart';
import '../services/currency_service.dart';

// Pagina del catalogo, mostra i marchi di auto
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
  String _preferredCurrency = CurrencyService.preferred;
  Map<String, double>? _rates;

  @override
  void initState() {
    super.initState();
    _preferredCurrency = CurrencyService.preferred;
    _rates = widget.rates;
    _bootstrapRatesIfNeeded();
  }

  Future<void> _bootstrapRatesIfNeeded() async {
    if (_rates != null) return;
    try {
      final r = await RatesApi().fetchRates(); // richiama API esterna
      if (!mounted) return;
      setState(() => _rates = r);
    } catch (_) {
      // Se fallisce usa solo EUR
    }
  }

  // apre pagina profilo (aggiunto settings name)
  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/profile'),
        builder: (_) => ProfilePage(
          initialCurrency: CurrencyService.preferred,
          onChanged: (_) {},
          cars: widget.cars,
          rates: _rates,
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _preferredCurrency = CurrencyService.preferred; // refresh UI
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brands = _luxuryBrands();
    final thumbs = _brandThumbnails();
    final logos = _brandLogos();

    // filtra solo auto già disponibili
    final availableCars = widget.cars.where((c) => !c.incoming).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 72,
        title: const _GradientText(
          'Catalogo',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: 1.1,
            color: Colors.white,
          ),
          colors: [Colors.orangeAccent, Colors.deepOrange],
        ),
      ),
      body: Stack(
        children: [
          const DarkLiveBackground(), // sfondo animato
          SafeArea(
            top: false,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: brands.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final brand = brands[i];
                final cover = thumbs[brand] ?? 'assets/macchine/mclaren.jpg';
                final logo = logos[brand] ?? 'assets/macchine/mclaren_logo.png';

                return _BrandCard(
                  brand: brand,
                  cover: cover,
                  logo: logo,
                  onTap: () {
                    // apre lista auto di quel marchio (aggiunto settings name)
                    final filtered = availableCars
                        .where((c) =>
                            c.brand.toLowerCase() == brand.toLowerCase())
                        .toList();

                    // route name stabile per singolo brand
                    final routeName =
                        '/catalog/${brand.toLowerCase().replaceAll(' ', '-')}';

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: RouteSettings(name: routeName),
                        builder: (_) => CarListPage(
                          brand: brand,
                          cars: filtered,
                          rates: _rates,
                          preferredCurrency: _preferredCurrency,
                          allCars: widget.cars,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: 1,
        cars: availableCars,
        allCars: widget.cars,
        rates: _rates,
        preferredCurrency: CurrencyService.preferred, // sempre aggiornata
        onProfileTap: _openProfile,
      ),
    );
  }

  // ----- helpers -----
  List<String> _luxuryBrands() => [
        'Bugatti',
        'Ferrari',
        'Lamborghini',
        'McLaren',
        'Porsche',
        'Rolls-Royce',
        'Aston Martin',
        'Bentley',
        'Koenigsegg',
        'Pagani',
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
        'Bentley': 'assets/macchine/bentley.jpg',
        'Koenigsegg': 'assets/macchine/koenigsegg.jpg',
        'Pagani': 'assets/macchine/pagani.jpg',
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
        'Bentley': 'assets/loghi/bentley_logo.png',
        'Koenigsegg': 'assets/loghi/koenigsegg_logo.png',
        'Pagani': 'assets/loghi/pagani_logo.png',
        'Lotus': 'assets/loghi/lotus_logo.png',
      };
}

/* ------- Brand card con effetto tap/hold (come HomePage) ------- */
class _BrandCard extends StatefulWidget {
  final String brand;
  final String cover;
  final String logo;
  final VoidCallback onTap;

  const _BrandCard({
    required this.brand,
    required this.cover,
    required this.logo,
    required this.onTap,
  });

  @override
  State<_BrandCard> createState() => _BrandCardState();
}

class _BrandCardState extends State<_BrandCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) => setState(() => _scale = 0.95);
  void _onTapUp(TapUpDetails details) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  void _onLongPress() {
    setState(() => _scale = 0.9);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _scale = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          onLongPress: _onLongPress,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(blurRadius: 8, color: Colors.black26)
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(widget.logo,
                        height: 60, width: 60, fit: BoxFit.contain),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.brand,
                          style: GoogleFonts.cinzelDecorative(
                            textStyle: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(blurRadius: 6, color: Colors.black87)
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
                    widget.cover,
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ------- titolo con gradiente ------- */
class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<Color> colors;

  const _GradientText(
    this.text, {
    required this.style,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style),
    );
  }
}