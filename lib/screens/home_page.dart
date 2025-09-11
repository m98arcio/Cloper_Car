import 'package:flutter/material.dart';
import '../models/car.dart';
import '../services/catalog_api.dart';
import '../services/rates_api.dart';
import 'car_detail_page.dart';

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
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _api = CatalogApi(baseUrl: ''); // lascia vuoto: usa assets/cars.json
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final cars = await _api.fetchCars();

      Map<String, double>? rates;
      try {
        rates = await _ratesApi.fetchRates();
      } catch (_) {
        rates = null; // se offline, mostriamo solo EUR
      }

      if (!mounted) return;
      setState(() {
        _cars = cars;
        _rates = rates;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // bottom-nav “finto”: per ora cambiamo solo colore, la Home è la 1ª tab
    return Scaffold(
      backgroundColor: const Color(0xFF1B171A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B171A),
        elevation: 0,
        title: const Text(
          'Luxury Supercars',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: const Color(0xFF1B171A),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Modelli'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Offerte'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilo'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(child: Text(_error));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // HERO con immagine di testata + testo grande
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset('assets/supercar.jpg', fit: BoxFit.cover),
                ),
                Container(
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Scopri le migliori supercar',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // TITOLO “Catalogo”
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Catalogo',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),

        // GRID 2 colonne in stile card tondeggiante
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _cars.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, i) {
              final c = _cars[i];
              final usd = _rates?['USD'];
              final gbp = _rates?['GBP'];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CarDetailPage(car: c)),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF262027),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(18)),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Image.asset(
                            c.images.first,
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
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '€ ${c.priceEur.toStringAsFixed(0)}'
                          '${usd != null ? '  |  \$ ${(c.priceEur * usd).toStringAsFixed(0)}' : ''}'
                          '${gbp != null ? '  |  £ ${(c.priceEur * gbp).toStringAsFixed(0)}' : ''}',
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
        ),
      ],
    );
  }
}