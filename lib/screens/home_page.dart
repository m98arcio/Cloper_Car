import 'package:flutter/material.dart';
import '../models/car.dart';
import '../services/catalog_api.dart';
import '../services/rates_api.dart';
import 'brand_catalog_page.dart';
import 'car_list_page.dart';
import '../widgets/brand_logo.dart';
import 'auctions_page.dart';
import 'auctions_swiper_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final CatalogApi _api;
  final RatesApi _ratesApi = RatesApi();
  Map<String, double>? _rates;
  List<Car> _cars = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _api = CatalogApi(baseUrl: ''); // lascia vuoto per usare assets/cars.json
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final cars = await _api.fetchCars();
      Map<String, double>? rates;
      try { rates = await _ratesApi.fetchRates(); } catch (_) { rates = null; }
      if (!mounted) return;
      setState(() { _cars = cars; _rates = rates; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
    } finally {
      if (!mounted) return;
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B171A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B171A),
        elevation: 0,
        title: const Text('Luxury Supercars', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        actions: [ IconButton(onPressed: _load, icon: const Icon(Icons.refresh)) ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text(_error));

    final brands = _uniqueBrands(_cars); // lista di brand unici
    final brandThumb = _brandThumbnails(_cars); // brand -> immagine di copertina

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // HERO
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                AspectRatio(
                  aspectRatio: 16/9,
                  child: Image.asset('assets/supercar.jpg', fit: BoxFit.cover),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Scopri le migliori supercar',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, shadows: [Shadow(blurRadius: 6, color: Colors.black54)]),
                  ),
                ),
              ],
            ),
          ),
        ),

        // HEADER + pulsante "Catalogo"
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text('Catalogo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BrandCatalogPage(cars: _cars),
                  ));
                },
                icon: const Icon(Icons.apps),
                label: const Text('Vedi tutto'),
              ),
            ],
          ),
        ),

        // PREVIEW MARCHI (scroll orizzontale)
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
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CarListPage(
                      brand: b,
                      cars: _cars.where((c) => c.brand.toLowerCase() == b.toLowerCase()).toList(),
                      rates: _rates,
                    ),
                  ));
                },
              );
            },
          ),
        ),

        // (Opzionale) Sezione "Nuovi arrivi" con 4 auto a caso:
        if (_cars.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Nuovi arrivi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          _carsGrid(_cars.take(4).toList()),
        ],
      ],
    );
  }

  Widget _carsGrid(List<Car> cars) {
    final usd = _rates?['USD'], gbp = _rates?['GBP'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: cars.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.88,
        ),
        itemBuilder: (_, i) {
          final c = cars[i];
          return InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CarListPage(
                brand: c.brand,
                cars: _cars.where((x) => x.brand == c.brand).toList(),
                rates: _rates,
              ),
            )),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFF262027), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: AspectRatio(aspectRatio: 16/10, child: Image.asset(c.images.first, fit: BoxFit.cover)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Text('${c.brand} ${c.model}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '€ ${c.priceEur.toStringAsFixed(0)}'
                      '${usd != null ? '  |  \$ ${(c.priceEur*usd).toStringAsFixed(0)}' : ''}'
                      '${gbp != null ? '  |  £ ${(c.priceEur*gbp).toStringAsFixed(0)}' : ''}',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade300),
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

  List<String> _uniqueBrands(List<Car> cars) {
    final set = <String>{};
    for (final c in cars) set.add(c.brand);
    final list = set.toList()..sort();
    return list;
    // se vuoi un ordine custom, rimpiazza qui.
  }

  Map<String, String> _brandThumbnails(List<Car> cars) {
    final map = <String, String>{};
    for (final c in cars) {
      map.putIfAbsent(c.brand, () => c.images.first);
    }
    return map; // brand -> path immagine
  }

Widget _bottomBar() => BottomNavigationBar(
  currentIndex: 0,
  selectedItemColor: Colors.redAccent,
  unselectedItemColor: Colors.grey.shade400,
  backgroundColor: const Color(0xFF1B171A),
  type: BottomNavigationBarType.fixed,
  onTap: (i) {
    if (i == 1) {
      // Catalogo (auto)
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => BrandCatalogPage(cars: _cars),
      ));
    } else if (i == 2) {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => AuctionsSwiperPage(cars: _cars),
  ));
} // i==0 Home, i==3 Profilo (per ora no-op)
  },
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Catalogo'),
    BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Aste'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilo'),
  ],
);
}

class _BrandChip extends StatelessWidget {
  final String brand;
  final String? imagePath;
  final VoidCallback onTap;
  const _BrandChip({required this.brand, required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF262027),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            BrandLogo(brand: brand, imagePath: imagePath, size: 70, round: true),
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
