import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/car.dart';
import '../widgets/dark_live_background.dart';

class CarDetailPage extends StatefulWidget {
  final Car car;
  final Map<String, double>? rates;
  final String preferredCurrency;

  const CarDetailPage({
    super.key,
    required this.car,
    this.rates,
    required this.preferredCurrency,
  });

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  int _tab = 1; // 0 = Descrizione, 1 = Scheda
  bool _priceOpen = false;

  Position? _pos;
  String? _locError;
  GoogleMapController? _map;

  @override
  void initState() {
    super.initState();
    _getPositionSafe();
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _getPositionSafe() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('GPS disattivato.');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        throw Exception('Permesso posizione negato.');
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception('Permesso negato in modo permanente.');
      }
      final p = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _pos = p);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.car;

    // Prezzi nella valuta preferita + eventuali righe extra
    final mainPriceText = _formatPrice(
      eur: c.priceEur,
      preferred: widget.preferredCurrency,
      rates: widget.rates,
    );
    final otherPrices = _otherPrices(
      eur: c.priceEur,
      preferred: widget.preferredCurrency,
      rates: widget.rates,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${c.brand} ${c.model}'),
      ),
      body: Stack(
        children: [
          const DarkLiveBackground(), // sfondo onde scure
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _HeroGallery(images: c.images),
                const SizedBox(height: 12),

                _SegmentedPill(
                  index: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                  leftIcon: Icons.menu,
                  rightIcon: Icons.description_outlined,
                ),

                const SizedBox(height: 14),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _tab == 0
                      ? _DescriptionCard(text: c.description ?? _defaultDesc(c))
                      : _SpecsCard(car: c),
                ),

                const SizedBox(height: 16),

                // Card PREZZO espandibile (valuta preferita + extra)
                _PriceCard(
                  mainText: mainPriceText,
                  open: _priceOpen,
                  onToggle: () => setState(() => _priceOpen = !_priceOpen),
                  extras: otherPrices,
                ),

                const SizedBox(height: 18),

                _SectionTitle('Concessionari vicini'),
                const SizedBox(height: 8),
                _MapCard(pos: _pos, error: _locError, onRetry: _getPositionSafe),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _defaultDesc(Car c) =>
      '${c.brand} ${c.model} unisce design iconico e prestazioni da pista. '
      'Questa scheda è alimentata dai dati locali del catalogo.';

  // --------- PRICE HELPERS ---------

  String _formatPrice({
    required double eur,
    required String preferred,
    required Map<String, double>? rates,
  }) {
    double value = eur;
    String symbol = '€';

    if (preferred == 'USD' && (rates?['USD'] != null)) {
      value = eur * rates!['USD']!;
      symbol = r'$';
    } else if (preferred == 'GBP' && (rates?['GBP'] != null)) {
      value = eur * rates!['GBP']!;
      symbol = '£';
    }

    return '$symbol ${_kSep(value)}';
  }

  List<String> _otherPrices({
    required double eur,
    required String preferred,
    required Map<String, double>? rates,
  }) {
    final out = <String>[];
    final usd = rates?['USD'];
    final gbp = rates?['GBP'];

    if (preferred != 'EUR') out.add('€ ${_kSep(eur)}');
    if (preferred != 'USD' && usd != null) out.add('\$ ${_kSep(eur * usd)}');
    if (preferred != 'GBP' && gbp != null) out.add('£ ${_kSep(eur * gbp)}');

    return out;
  }

  String _kSep(double v) {
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      b.write(s[i]);
      final group = idxFromEnd > 1 && (idxFromEnd - 1) % 3 == 0;
      if (group) b.write('.');
    }
    return b.toString();
  }
}

/* ======================  WIDGETS  ====================== */

class _HeroGallery extends StatefulWidget {
  final List<String> images;
  const _HeroGallery({required this.images});

  @override
  State<_HeroGallery> createState() => _HeroGalleryState();
}

class _HeroGalleryState extends State<_HeroGallery> {
  final _pc = PageController();
  int _i = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.images.isNotEmpty ? widget.images : const ['assets/supercar.jpg'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (v) => setState(() => _i = v),
              itemCount: imgs.length,
              itemBuilder: (_, k) => Image.asset(imgs[k], fit: BoxFit.cover),
            ),
          ),
          if (imgs.length > 1)
            Positioned(
              bottom: 10,
              child: Row(
                children: List.generate(imgs.length, (k) {
                  final on = k == _i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: on ? 18 : 6,
                    decoration: BoxDecoration(
                      color: on ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
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

class _SegmentedPill extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final IconData leftIcon;
  final IconData rightIcon;
  const _SegmentedPill({
    required this.index,
    required this.onChanged,
    required this.leftIcon,
    required this.rightIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment: index == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                width: (MediaQuery.of(context).size.width - 16 * 2) / 2 - 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => onChanged(0),
                  child: const Center(child: Icon(Icons.menu, size: 22)),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => onChanged(1),
                  child: const Center(child: Icon(Icons.description_outlined, size: 22)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF).withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black38)],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String text;
  const _DescriptionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Descrizione', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(fontSize: 16, height: 1.35)),
        ],
      ),
    );
  }
}

class _SpecsCard extends StatelessWidget {
  final Car car;
  const _SpecsCard({required this.car});

  @override
  Widget build(BuildContext context) {
    String fmtCm(double? v) =>
        v == null ? '—' : (v % 1 == 0 ? '${v.toStringAsFixed(0)} cm' : '${v.toStringAsFixed(1)} cm');

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${car.brand.toUpperCase()} ${car.model.toUpperCase()}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Row(
            children: const [
              Text('Dati tecnici', style: TextStyle(color: Colors.white70)),
              Spacer(),
              Icon(Icons.settings, size: 18, color: Colors.white70),
            ],
          ),
          const Divider(height: 24),

          _SpecGroup(
            title: 'Motore e Prestazioni',
            icon: Icons.settings,
            rows: [
              _kv('Motore', car.engine ?? '—'),
              _kv('Cambio', car.gearbox ?? '—'),
              _kv('Potenza', '${car.powerHp} CV'),
              _kv('0–100 km/h', car.zeroTo100 ?? '—'),
              _kv('Velocità max', car.topSpeed ?? '—'),
            ],
          ),
          const SizedBox(height: 12),

          _SpecGroup(
            title: 'Dimensioni',
            icon: Icons.straighten,
            rows: [
              _kv('Lunghezza', fmtCm(car.lengthCm)),
              _kv('Larghezza', fmtCm(car.widthCm)),
              _kv('Passo', fmtCm(car.wheelbaseCm)),
            ],
          ),
        ],
      ),
    );
  }

  static MapEntry<String, String> _kv(String k, String v) => MapEntry(k, v);
}

class _SpecGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<MapEntry<String, String>> rows;
  const _SpecGroup({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        ...rows.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text('${e.key}:', style: const TextStyle(fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.value, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/* ======================  CARD PREZZO  ====================== */

class _PriceCard extends StatelessWidget {
  final String mainText;
  final bool open;
  final VoidCallback onToggle;
  final List<String> extras;

  const _PriceCard({
    required this.mainText,
    required this.open,
    required this.onToggle,
    this.extras = const [],
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF).withOpacity(0.07),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black38)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sell_outlined),
                const SizedBox(width: 10),
                const Text('Prezzo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: open ? 0.5 : 0.0,
                  child: const Icon(Icons.expand_more),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mainText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    for (final line in extras) ...[
                      const SizedBox(height: 6),
                      Text(line),
                    ],
                  ],
                ),
              ),
              crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

/* ======================  MAPPA (FACOLTATIVA)  ====================== */

class _MapCard extends StatelessWidget {
  final Position? pos;
  final String? error;
  final VoidCallback onRetry;
  const _MapCard({required this.pos, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF).withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: _content(),
    );
  }

  Widget _content() {
    if (error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: onRetry, child: const Text('Riprova')),
        ]),
      );
    }
    if (pos == null) return const Center(child: CircularProgressIndicator());

    final user = LatLng(pos!.latitude, pos!.longitude);
    final dealers = <LatLng>[
      LatLng(user.latitude + 0.01, user.longitude + 0.01),
      LatLng(user.latitude - 0.012, user.longitude + 0.008),
      LatLng(user.latitude + 0.008, user.longitude - 0.009),
    ];

    final markers = dealers.asMap().entries.map((e) {
      final p = e.value;
      return Marker(
        markerId: MarkerId('d_${e.key}'),
        position: p,
        infoWindow: InfoWindow(
          title: 'Concessionario',
          onTap: () async {
            final uri = Uri.parse(
              'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}',
            );
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: user, zoom: 13),
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      markers: markers,
    );
  }
}