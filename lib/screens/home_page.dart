import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/car.dart';
import '../services/local_catalog.dart';
import '../services/rates_api.dart';

import '../widgets/dark_live_background.dart';
import '../widgets/brand_logo.dart';

import 'brand_catalog_page.dart';
import 'car_list_page.dart';
import 'auctions_swiper_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _prefKeyCurrency = 'preferred_currency'; // EUR, USD, GBP

  final RatesApi _ratesApi = RatesApi();
  List<Car> _cars = [];
  Map<String, double>? _rates;
  String _preferred = 'EUR'; // default
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      // 1) preferenze
      final prefs = await SharedPreferences.getInstance();
      _preferred = prefs.getString(_prefKeyCurrency) ?? 'EUR';

      // 2) catalogo locale
      final cars = await LocalCatalog.load();

      // 3) tassi (se servono)
      Map<String, double>? rates;
      try {
        rates = await _ratesApi.fetchRates();
      } catch (_) {
        rates = null; // rete non disponibile -> useremo solo EUR
      }

      if (!mounted) return;
      setState(() {
        _cars = cars;
        _rates = rates;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
            ),
      ),
    );

    // Se rientriamo e la valuta è cambiata, ricarico solo preferenza (tassi già in cache)
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
    final title =
        _preferred == 'EUR'
            ? 'Luxury Supercars • €'
            : _preferred == 'USD'
            ? 'Luxury Supercars • \$'
            : 'Luxury Supercars • £';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _bootstrap),
        ],
      ),
      body: Stack(
        children: [const DarkLiveBackground(), SafeArea(child: _buildBody())],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text(_error));

    final brands = _uniqueBrands(_cars);
    final brandThumb = _brandThumbnails(_cars);

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // HERO
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset('assets/supercar.jpg', fit: BoxFit.cover),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Text(
                    'Scopri le migliori supercar',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Header Catalogo + Vedi tutto
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

        // Anteprima marchi
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final b = brands[i];
              final cover = brandThumb[b];
              return _BrandChip(
                brand: b,
                imagePath: cover,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => CarListPage(
                            brand: b,
                            cars:
                                _cars
                                    .where(
                                      (c) =>
                                          c.brand.toLowerCase() ==
                                          b.toLowerCase(),
                                    )
                                    .toList(),
                            rates: _rates,
                            preferredCurrency: _preferred,
                          ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Nuovi arrivi (prime 4 per esempio)
        if (_cars.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 22, 16, 10),
            child: Text(
              'Nuovi arrivi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          _carsGrid(_cars.take(4).toList()),
        ],
      ],
    );
  }

  Widget _carsGrid(List<Car> cars) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: cars.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.88,
        ),
        itemBuilder: (_, i) {
          final c = cars[i];
          final priceText = _formatPrice(c.priceEur);

          return InkWell(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => CarListPage(
                          brand: c.brand,
                          cars: _cars.where((x) => x.brand == c.brand).toList(),
                          rates: _rates,
                          preferredCurrency: _preferred,
                        ),
                  ),
                ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF).withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(blurRadius: 10, color: Colors.black26),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.asset(
                        c.images.isNotEmpty
                            ? c.images.first
                            : 'assets/supercar.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Text(
                      '${c.brand} ${c.model}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      priceText,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatPrice(double eur) {
    // EUR base, converto se preferito diverso e ho i tassi
    switch (_preferred) {
      case 'USD':
        final r = _rates?['USD'];
        return r == null ? '€ ${_kSep(eur)}' : '\$ ${_kSep(eur * r)}';
      case 'GBP':
        final r = _rates?['GBP'];
        return r == null ? '€ ${_kSep(eur)}' : '£ ${_kSep(eur * r)}';
      case 'EUR':
      default:
        return '€ ${_kSep(eur)}';
    }
  }

  String _kSep(double v) {
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      b.write(s[i]);
      final isBeforeGroup = idxFromEnd > 1 && (idxFromEnd - 1) % 3 == 0;
      if (isBeforeGroup) b.write('.');
    }
    return b.toString();
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
      map.putIfAbsent(
        c.brand,
        () => c.images.isNotEmpty ? c.images.first : 'assets/supercar.jpg',
      );
    }
    return map;
  }

  Widget _bottomBar() => BottomNavigationBar(
    currentIndex: 0,
    selectedItemColor: Colors.redAccent,
    unselectedItemColor: Colors.grey.shade400,
    backgroundColor: Colors.black.withOpacity(0.15),
    type: BottomNavigationBarType.fixed,
    onTap: (i) {
      if (i == 1) {
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
      } else if (i == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AuctionsSwiperPage(cars: _cars)),
        );
      } else if (i == 3) {
        _openProfile();
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
  );
}

class _BrandChip extends StatelessWidget {
  final String brand;
  final String? imagePath;
  final VoidCallback onTap;
  const _BrandChip({
    required this.brand,
    required this.imagePath,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF).withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            BrandLogo(
              brand: brand,
              imagePath: imagePath,
              size: 70,
              round: true,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                brand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
