// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/car.dart';
import '../services/local_catalog.dart';
import '../services/rates_api.dart';
import '../services/news_service.dart';
import '../widgets/dark_live_background.dart';
import '../widgets/brand_logo.dart';
import '../widgets/news_strip.dart';
import '../widgets/app_bottom_bar.dart';

import 'brand_catalog_page.dart';
import 'car_list_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _prefKeyCurrency = 'preferred_currency';
  String _preferred = 'EUR';

  final RatesApi _ratesApi = RatesApi();
  List<Car> _cars = [];
  Map<String, double>? _rates;

  bool _loading = true;
  String _error = '';

  final _newsService = NewsService();
  List<NewsItem> _news = [];
  bool _newsLoading = true;
  String _newsError = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _loadNews();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _preferred = prefs.getString(_prefKeyCurrency) ?? 'EUR';

      final cars = await LocalCatalog.load();
      Map<String, double>? rates;

      try {
        rates = await _ratesApi.fetchRates();
      } catch (_) {
        rates = null;
      }

      if (!mounted) return;
      setState(() {
        _cars = cars;
        _rates = rates;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadNews() async {
    setState(() {
      _newsLoading = true;
      _newsError = '';
    });

    try {
      final items = await _newsService.fetchLatest();
      if (!mounted) return;
      setState(() => _news = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _newsError = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _newsLoading = false);
    }
  }

  Future<void> _openProfile() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (_) => ProfilePage(
              initialCurrency: _preferred,
              onChanged: (c) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(_prefKeyCurrency, c);
              },
              cars: _cars,
              rates: _rates,
            ),
      ),
    );

    if (changed == true) {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _preferred = prefs.getString(_prefKeyCurrency) ?? 'EUR';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0F), // nero fisso
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 72, // leggermente più alta del default
        title: const _AppBarBrandTitle(),
      ),

      body: Stack(
        children: [
          const DarkLiveBackground(),
          SafeArea(top: false, child: _buildBody()),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: 0,
        cars: _cars,
        allCars: _cars,
        rates: _rates,
        preferredCurrency: _preferred,
        onProfileTap: _openProfile,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text(_error));

    final allBrands = _uniqueBrands(_cars);

    final brandLogos = {
      'Ferrari': 'assets/loghi/ferrari_logo.png',
      'Lotus': 'assets/loghi/lotus_logo.png',
      'Lamborghini': 'assets/loghi/lamborghini_logo.png',
    };

    // Ordine fisso dei primi 4 brand
    final fixedBrands = ['Ferrari', 'Lotus', 'Lamborghini', 'Porsche'];
    final displayedBrands =
        fixedBrands.where((b) => allBrands.contains(b)).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // Hero con titolo incavato
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    'assets/macchine/supercar.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.asset(
                        'assets/macchine/supercar.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Drive Different',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 6,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Catalogo
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Catalogo',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => BrandCatalogPage(
                            cars: _cars,
                            rates: _rates,
                            preferredCurrency: _preferred,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.apps),
                label: const Text('Vedi tutto'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: displayedBrands.length + 1, // 4 brand + SeeAll
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              if (i < displayedBrands.length) {
                final b = displayedBrands[i];
                final logo = brandLogos[b] ?? '';
                return _BrandChip(
                  brand: b,
                  imagePath: logo,
                  onTap: () {
                    final filtered =
                        _cars
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
                              rates: _rates,
                              preferredCurrency: _preferred,
                            ),
                      ),
                    );
                  },
                );
              } else {
                return _SeeAllChip(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => BrandCatalogPage(
                              cars: _cars,
                              rates: _rates,
                              preferredCurrency: _preferred,
                            ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),

        // Notizie
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 22, 16, 10),
          child: Text(
            'Ultime notizie',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        if (_newsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_newsError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.error_outline),
                const SizedBox(width: 8),
                Expanded(child: Text('Errore notizie: $_newsError')),
                IconButton(
                  onPressed: _loadNews,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          )
        else
          NewsStrip(items: _news, onRefresh: _loadNews),

        const SizedBox(height: 100),

        // Footer
        Container(
          width: double.infinity,
          color: const Color(0xFF212121),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Informazioni',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'CloperCar è un progetto fittizio dedicato agli appassionati di auto di lusso. '
                'Tutti i contenuti, prezzi e marchi presenti sono simulati a scopo dimostrativo.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 30),
              Text(
                'Contatti',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Email: info@clopercar.fake',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                'Telefono: +39 012 345 6789',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _uniqueBrands(List<Car> cars) {
    final s = <String>{};
    for (final c in cars) {
      s.add(c.brand);
    }
    final list = s.toList()..sort();
    return list;
  }
}

/* ---------- Titolo AppBar con gradiente ---------- */

class _AppBarBrandTitle extends StatelessWidget {
  const _AppBarBrandTitle();

  @override
  Widget build(BuildContext context) {
    return const _GradientText(
      'CloperCar',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
        color: Colors.white, // sostituito dal gradient
      ),
      colors: [Colors.orangeAccent, Colors.deepOrange],
    );
  }
}

class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<Color> colors;

  const _GradientText(this.text, {required this.style, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback:
          (bounds) => LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style),
    );
  }
}

// ----------- Chip brand (invariato) -----------

class _BrandChip extends StatefulWidget {
  final String brand;
  final String? imagePath;
  final VoidCallback onTap;

  const _BrandChip({
    required this.brand,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_BrandChip> createState() => _BrandChipState();
}

class _BrandChipState extends State<_BrandChip> {
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
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          onLongPress: _onLongPress,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(blurRadius: 10, color: Colors.black26),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                BrandLogo(
                  brand: widget.brand,
                  imagePath: widget.imagePath,
                  size: 50,
                  round: true,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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

class _SeeAllChip extends StatefulWidget {
  final VoidCallback onTap;

  const _SeeAllChip({required this.onTap});

  @override
  State<_SeeAllChip> createState() => _SeeAllChipState();
}

class _SeeAllChipState extends State<_SeeAllChip> {
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
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          onLongPress: _onLongPress,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Container(
            width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.grey.withOpacity(0.5),
                  Colors.grey.withOpacity(0.25),
                  Colors.grey.withOpacity(0.125),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 0.75, 1.0],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.arrow_forward_ios,
                size: 30,
                color: Colors.black45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
