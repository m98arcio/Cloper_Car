// lib/screens/car_detail_page.dart
import 'package:concessionario_supercar/widgets/app_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/car.dart';
import '../widgets/dark_live_background.dart';
import '../services/dealer_service.dart';
import 'profile_page.dart';

class CarDetailPage extends StatefulWidget {
  final Car car;
  final Map<String, double>? rates;
  final String preferredCurrency;
  final List<Car> cars;

  const CarDetailPage({
    super.key,
    required this.car,
    this.rates,
    required this.preferredCurrency,
    required this.cars,
  });

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  int _tab = 0;
  bool _priceOpen = false;

  Position? _pos;
  String? _locError;

  @override
  void initState() {
    super.initState();
    _getPositionSafe();
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

  Future<void> _openProfile() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ProfilePage(
              initialCurrency: widget.preferredCurrency,
              onChanged: (_) {},
              cars: widget.cars,
              rates: widget.rates,
            ),
      ),
    );
  }

  String _defaultDesc(Car c) =>
      '${c.brand} ${c.model} unisce design iconico e prestazioni da pista. Questa scheda è alimentata dai dati locali del catalogo.';

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
      if (idxFromEnd > 1 && (idxFromEnd - 1) % 3 == 0) b.write('.');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.car;

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
          const DarkLiveBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _HeroGallery(images: c.images, title: '${c.brand} ${c.model}'),
                const SizedBox(height: 12),
                _SegmentedPill(
                  index: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                  leftIcon: Icons.description_outlined,
                  rightIcon: Icons.menu,
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child:
                      _tab == 0
                          ? _DescriptionCard(
                            text: c.description ?? _defaultDesc(c),
                          )
                          : _SpecsCard(car: c),
                ),
                const SizedBox(height: 16),
                _PriceCard(
                  mainText: mainPriceText,
                  open: _priceOpen,
                  onToggle: () => setState(() => _priceOpen = !_priceOpen),
                  extras: otherPrices,
                ),
                const SizedBox(height: 18),
                const _SectionTitle('Concessionari vicini'),
                const SizedBox(height: 8),
                _MapCard(
                  car: c, // <-- passiamo l’auto
                  pos: _pos, // posizione utente (può essere null)
                  error: _locError, // eventuale errore
                  onRetry: _getPositionSafe, // per riprovare i permessi
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: 0,
        cars: widget.cars,
        rates: widget.rates,
        preferredCurrency: widget.preferredCurrency,
        onProfileTap: _openProfile,
      ),
    );
  }
}

/* ======================  WIDGETS  ====================== */

class _HeroGallery extends StatefulWidget {
  final List<String> images;
  final String title;
  const _HeroGallery({required this.images, required this.title});

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
    final imgs =
        widget.images.isNotEmpty
            ? widget.images
            : const ['assets/macchine/supercar.jpg'];

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (v) => setState(() => _i = v),
              itemCount: imgs.length,
              itemBuilder: (_, k) => Image.asset(imgs[k], fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
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
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment:
                index == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                width: (MediaQuery.of(context).size.width - 32) / 2 - 4,
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
                  child: Center(child: Icon(leftIcon, size: 22)),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => onChanged(1),
                  child: Center(child: Icon(rightIcon, size: 22)),
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
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
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
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(blurRadius: 14, color: Colors.black38)],
      ),
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Descrizione',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
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
        v == null
            ? '—'
            : (v % 1 == 0
                ? '${v.toStringAsFixed(0)} cm'
                : '${v.toStringAsFixed(1)} cm');

    MapEntry<String, String> _kv(String k, String v) => MapEntry(k, v);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${car.brand.toUpperCase()} ${car.model.toUpperCase()}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Text('Dati tecnici', style: TextStyle(color: Colors.white70)),
              Spacer(),
              Icon(Icons.settings, size: 18, color: Colors.white70),
            ],
          ),
          const Divider(height: 20),
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
}

class _SpecGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<MapEntry<String, String>> rows;
  const _SpecGroup({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...rows.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${e.key}:',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    e.value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF).withOpacity(0.07),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(blurRadius: 14, color: Colors.black38)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sell_outlined),
                const SizedBox(width: 8),
                const Text(
                  'Prezzo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
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
                    Text(
                      mainText,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    for (final line in extras) ...[
                      const SizedBox(height: 6),
                      Text(line),
                    ],
                  ],
                ),
              ),
              crossFadeState:
                  open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

/* =================== MAP =================== */
/* =================== MAP =================== */

class _MapCard extends StatefulWidget {
  final Car car;
  final Position? pos;
  final String? error;
  final VoidCallback onRetry;

  const _MapCard({
    required this.car,
    required this.pos,
    required this.error,
    required this.onRetry,
  });

  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard> {
  GoogleMapController? _controller;
  Set<Marker> _markers = const <Marker>{};
  CameraPosition? _initial;
  String? _centeredDealerId;

  @override
  void didUpdateWidget(covariant _MapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Quando arriva la posizione o cambia l'auto, prepara la mappa
    if (oldWidget.pos != widget.pos || oldWidget.car != widget.car || oldWidget.error != widget.error) {
      _prepare();
    }
  }

  Future<void> _prepare() async {
    // Se c'è un errore permessi → box errore (gestito in build), azzera stato interno
    if (widget.error != null) {
      setState(() {
        _markers = const <Marker>{};
        _initial = null;           // niente camera finché non si risolve
        _centeredDealerId = null;
      });
      return;
    }

    // Finché NON ho la posizione, non calcolo nulla: mostro solo lo spinner
    if (widget.pos == null) {
      setState(() {
        _markers = const <Marker>{};
        _initial = null;
        _centeredDealerId = null;
      });
      return;
    }

    // --- Da qui in poi POSIZIONE PRESENTE ---
    final all = await DealersRepo.load();
    final Map<String, DealerPoint> byId = {for (final d in all) d.id: d};

    final allowedIds = widget.car.availableAt ?? const <String>[];
    List<DealerPoint> visible;

    if (allowedIds.isNotEmpty) {
      // usa SOLO i dealer dichiarati nell’auto (ordine preservato)
      visible = [
        for (final id in allowedIds)
          if (byId.containsKey(id)) byId[id]!,
      ];
      // Se per errore non ne trova nessuno, fallback: nessun marker (così è evidente il problema dati)
      if (visible.isEmpty) {
        setState(() {
          _markers = const <Marker>{};
          _initial = null;
          _centeredDealerId = null;
        });
        return;
      }
    } else {
      // auto senza availableAt: usa tutti
      visible = all;
    }

    // Calcola il dealer più vicino tra i VISIBILI
    final user = LatLng(widget.pos!.latitude, widget.pos!.longitude);
    final nearest = await DealersRepo.nearestTo(
      user,
      allowedDealerIds: visible.map((d) => d.id).toList(),
    );

    // Marker dealer visibili
    final markers = <Marker>{
      for (final d in visible)
        Marker(
          markerId: MarkerId(d.id),
          position: d.latLng,
          infoWindow: InfoWindow(
            title: d.name,
            snippet: d.city,
            onTap: () async {
              final uri = Uri.parse(
                'https://www.google.com/maps/dir/?api=1&destination=${d.latLng.latitude},${d.latLng.longitude}',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ),
      // Marker dell’utente
      Marker(
        markerId: const MarkerId('me'),
        position: user,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'La tua posizione'),
      ),
    };

    if (!mounted) return;

    final shouldAnimate =
        _controller != null && _centeredDealerId != nearest.id;

    setState(() {
      _markers = markers;
      _initial ??= CameraPosition(target: nearest.latLng, zoom: 11.5);
      _centeredDealerId = nearest.id;
    });

    if (shouldAnimate) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(nearest.latLng, 11.5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Box errore permessi/GPS
    if (widget.error != null) {
      return _errorBox(widget.error!, widget.onRetry);
    }

    // Finché non ho la posizione → spinner (niente centering provvisorio)
    if (widget.pos == null || _initial == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF).withOpacity(0.07),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF).withOpacity(0.07),
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        initialCameraPosition: _initial!,
        myLocationEnabled: true,
        zoomControlsEnabled: false,
        markers: _markers,
        onMapCreated: (c) {
          _controller = c;
          // dopo la creazione, se serviva, centriamo (la prima volta _prepare lo ha già fatto)
        },
      ),
    );
  }

  Widget _errorBox(String msg, VoidCallback onRetry) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF).withOpacity(0.07),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(msg, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: onRetry, child: const Text('Riprova')),
        ]),
      ),
    );
  }
}