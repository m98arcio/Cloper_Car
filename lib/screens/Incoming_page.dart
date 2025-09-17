import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:concessionario_supercar/screens/profile_page.dart';
import 'package:concessionario_supercar/widgets/app_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/car.dart';
import '../widgets/dark_live_background.dart';

class IncomingPage extends StatefulWidget {
  const IncomingPage({super.key, required this.cars, required Null Function() onProfileTap});
  final List<Car> cars;

  @override
  State<IncomingPage> createState() => _IncomingPageState();
}

/* --------------------------- Dealer & helpers --------------------------- */

class Dealer {
  final String name;
  final String city;
  final double lat;
  final double lng;
  const Dealer({required this.name, required this.city, required this.lat, required this.lng});

  factory Dealer.fromJson(Map<String, dynamic> j) =>
      Dealer(name: j['name'], city: j['city'], lat: (j['lat'] as num).toDouble(), lng: (j['lng'] as num).toDouble());
}

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return R * c;
}

double _toRad(double d) => d * math.pi / 180.0;

/* ------------------------------- Pagina -------------------------------- */

class _IncomingPageState extends State<IncomingPage> with SingleTickerProviderStateMixin {
  // sensori
  StreamSubscription? _accSub, _gyroSub;
  double _roll = 0, _pitch = 0, _accRoll = 0, _accPitch = 0;
  double? _baseRoll, _basePitch; // baseline per partire dritti
  DateTime? _lastGyroTime;
  static const _alpha = 0.92;
  static const _clamp = 0.30;
  double _deadzone(double v, [double eps = 0.02]) => v.abs() < eps ? 0 : v;

  late final PageController _page;
  late final AnimationController _glow;

  // dealers + user location
  List<Dealer> _dealers = const [];
  Position? _pos;
  String? _loadError;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 0.78);
    _glow = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _initData();
    _startSensors();
  }

  Future<void> _initData() async {
    try {
      // load dealers
      final txt = await rootBundle.loadString('assets/dealers.json');
      final list = (jsonDecode(txt) as List).map((e) => Dealer.fromJson(e)).toList();
      // get location
      final pos = await _getPosition();
      if (!mounted) return;
      setState(() {
        _dealers = list;
        _pos = pos;
      });
    } catch (e) {
      setState(() => _loadError = e.toString());
    }
  }

  Future<Position?> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) return null;
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _startSensors() {
    _accSub = accelerometerEventStream().listen((e) {
      final ax = e.x.toDouble(), ay = e.y.toDouble(), az = e.z.toDouble();
      _accRoll = math.atan2(ay, az);
      _accPitch = math.atan2(-ax, math.sqrt(ay * ay + az * az));
    });
    _gyroSub = gyroscopeEventStream().listen((g) {
      final now = DateTime.now();
      final dt = _lastGyroTime == null ? 0.016 : (now.difference(_lastGyroTime!).inMicroseconds / 1e6);
      _lastGyroTime = now;

      _roll = (_alpha * (_roll + g.x * dt)) + ((1 - _alpha) * _accRoll);
      _pitch = (_alpha * (_pitch + g.y * dt)) + ((1 - _alpha) * _accPitch);

      _roll = _roll.clamp(-_clamp, _clamp);
      _pitch = _pitch.clamp(-_clamp, _clamp);

      // set baseline la prima volta, così si parte dritti
      _baseRoll ??= _roll;
      _basePitch ??= _pitch;

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _glow.dispose();
    _page.dispose();
    _accSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }

// ...tutto il codice precedente rimane uguale fino alla build() di _IncomingPageState...

@override
Widget build(BuildContext context) {
  final cars = widget.cars.where((c) => c.incoming).toList();

  if (cars.isEmpty) {
    return const Scaffold(
      body: Stack(children: [
        DarkLiveBackground(),
        SafeArea(child: Center(child: Text('Nessuna auto in arrivo.')))
      ]),
    );
  }

  if (_loadError != null) {
    return Scaffold(
      body: Stack(children: [
        const DarkLiveBackground(),
        SafeArea(child: Center(child: Text(_loadError!)))
      ]),
    );
  }

  return Scaffold(
    body: Stack(
      children: [
        const DarkLiveBackground(),
        SafeArea(
          child: Column(
            children: [
              const _TopBar(),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: cars.length,
                  itemBuilder: (context, i) {
                    final car = cars[i];
                    final eta = DateTime.now().add(Duration(days: (car.id.hashCode % 20).abs() + 3));
                    final nearest = _nearestDealer();

                    final rotY = _deadzone((_roll - (_baseRoll ?? 0))) * 0.45;
                    final rotX = _deadzone((_pitch - (_basePitch ?? 0))) * 0.35;

                    return Transform(
                      alignment: Alignment.center,
                      transform: _perspective(rotX: rotX, rotY: rotY),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        child: _FlipIncomingCard(
                          car: car,
                          eta: eta,
                          dealer: nearest,
                          glow: _glow,
                          userPos: _pos,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // banner in basso (testuale)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _AvailabilityBanner(
                  city: _nearestDealer()?.city ?? '—',
                  eta: DateTime.now().add(
                    Duration(days: (cars[_index].id.hashCode % 20).abs() + 3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),

    // -------------------- BOTTOM BAR --------------------
    bottomNavigationBar: AppBottomBar(
      currentIndex: 2, // indice della sezione "In arrivo"
      cars: widget.cars,
      rates: null,
      preferredCurrency: 'EUR',
      onProfileTap: () {
        // navigazione verso ProfilePage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(
              initialCurrency: 'EUR',
              onChanged: (_) {},
              cars: widget.cars,
              rates: null,
            ),
          ),
        );
      },
    ),
  );
}


  Dealer? _nearestDealer() {
    if (_dealers.isEmpty || _pos == null) return _dealers.isNotEmpty ? _dealers.first : null;
    Dealer best = _dealers.first;
    double bestD = double.infinity;
    for (final d in _dealers) {
      final dist = _haversine(_pos!.latitude, _pos!.longitude, d.lat, d.lng);
      if (dist < bestD) {
        bestD = dist;
        best = d;
      }
    }
    return best;
  }

  Matrix4 _perspective({double rotX = 0, double rotY = 0}) {
    return Matrix4.identity()..setEntry(3, 2, 0.0016)..rotateX(rotX)..rotateY(rotY);
  }
}

/* ------------------------------ Top bar ------------------------------ */

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        height: 44,
        child: Center(
          child: Text('In arrivo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

/* --------------------------- Flip Incoming Card --------------------------- */

class _FlipIncomingCard extends StatefulWidget {
  final Car car;
  final DateTime eta;
  final Dealer? dealer;
  final AnimationController glow;
  final Position? userPos;

  const _FlipIncomingCard({
    required this.car,
    required this.eta,
    required this.dealer,
    required this.glow,
    required this.userPos,
  });

  @override
  State<_FlipIncomingCard> createState() => _FlipIncomingCardState();
}

class _FlipIncomingCardState extends State<_FlipIncomingCard> with SingleTickerProviderStateMixin {
  late final AnimationController _flip; // 0 -> front, 1 -> back
  bool get _isBack => _flip.value >= 0.5;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isBack) {
      _flip.reverse();
    } else {
      _flip.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          final angle = _flip.value * math.pi; // 0..pi
          final showBack = angle > math.pi / 2;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle);

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // gestiamo front/back con "inversione" e visibilità
                  Opacity(
                    opacity: showBack ? 0.0 : 1.0,
                    child: IgnorePointer(ignoring: showBack, child: _FrontFace(car: widget.car, eta: widget.eta, glow: widget.glow)),
                  ),
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi), // per disegnare il retro correttamente
                    child: Opacity(
                      opacity: showBack ? 1.0 : 0.0,
                      child: IgnorePointer(ignoring: !showBack, child: _BackFace(car: widget.car, eta: widget.eta, dealer: widget.dealer, userPos: widget.userPos)),
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
}

/* ------------------------------- Front -------------------------------- */

class _FrontFace extends StatelessWidget {
  final Car car;
  final DateTime eta;
  final AnimationController glow;
  const _FrontFace({required this.car, required this.eta, required this.glow});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final img = car.images.isNotEmpty ? car.images.first : 'assets/supercar.jpg';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.3 * (0.6 + 0.4 * math.sin(glow.value * math.pi))),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1733), Color(0xFF141C3A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              img,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, size: 48),
              ),
            ),
          ),
          // sfumatura
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          // pill in alto a destra con la data di arrivo
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Arrivo', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Text(_fmtDate(eta), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          // titolo + hint "tocca la card..."
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${car.brand} ${car.model}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'Tocca la card per saperne di più',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/* -------------------------------- Back -------------------------------- */

class _BackFace extends StatelessWidget {
  final Car car;
  final DateTime eta;
  final Dealer? dealer;
  final Position? userPos;

  const _BackFace({required this.car, required this.eta, required this.dealer, required this.userPos});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final specs = <String>[
      if (car.engine?.isNotEmpty == true) 'Motore: ${car.engine}',
      '${car.powerHp} CV',
      if (car.year != null) 'Anno: ${car.year}',
      if (car.topSpeed != null) 'Vel. max: ${car.topSpeed}',
      if (car.zeroTo100 != null) '0-100: ${car.zeroTo100}',
      if (car.gearbox != null) 'Cambio: ${car.gearbox}',
    ];

    final latLng = dealer != null ? LatLng(dealer!.lat, dealer!.lng) : const LatLng(41.9028, 12.4964);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withOpacity(0.35)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1733), Color(0xFF141C3A)],
        ),
      ),
      child: Column(
        children: [
          // header con titolo + pill data
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text('${car.brand} ${car.model}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(_fmtDate(eta), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          // specs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                children: specs
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(s, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Google Map (con marker del dealer più vicino)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: latLng, zoom: 12.5),
                markers: {
                  if (dealer != null)
                    Marker(markerId: const MarkerId('dealer'), position: latLng, infoWindow: InfoWindow(title: dealer!.name, snippet: dealer!.city)),
                  if (userPos != null)
                    Marker(
                      markerId: const MarkerId('me'),
                      position: LatLng(userPos!.latitude, userPos!.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      infoWindow: const InfoWindow(title: 'Tu sei qui'),
                    ),
                },
                myLocationEnabled: userPos != null,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                tiltGesturesEnabled: false,
                buildingsEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // footer con dealer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                dealer != null
                    ? 'Concessionario più vicino: ${dealer!.name} — ${dealer!.city}'
                    : 'Nessun concessionario disponibile',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/* --------------------------- Availability Banner --------------------------- */

class _AvailabilityBanner extends StatelessWidget {
  final String city;
  final DateTime eta;
  const _AvailabilityBanner({required this.city, required this.eta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        'Presto disponibile al concessionario di: $city — Arrivo previsto: '
        '${eta.day.toString().padLeft(2, '0')}/${eta.month.toString().padLeft(2, '0')}/${eta.year}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}