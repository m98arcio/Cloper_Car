import 'dart:async';
import 'dart:math' as math;
import 'package:concessionario_supercar/screens/profile_page.dart';
import 'package:concessionario_supercar/widgets/app_bottom_bar.dart';
import 'package:concessionario_supercar/widgets/dark_live_background.dart';
import 'package:concessionario_supercar/widgets/flip_incoming_card.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../data/dealers_repo.dart';
import '../models/car.dart';
import '../models/dealer_point.dart';
import '../services/local_catalog.dart';

class IncomingPage extends StatefulWidget {
  const IncomingPage({
    super.key,
    required this.cars,
    this.allCars,
  });

  final List<Car> cars;
  final List<Car>? allCars;

  @override
  State<IncomingPage> createState() => _IncomingPageState();
}

class _IncomingPageState extends State<IncomingPage>
    with SingleTickerProviderStateMixin {
  // -------- sensori / animazioni --------
  StreamSubscription? _accSub, _gyroSub;
  double _roll = 0, _pitch = 0, _accRoll = 0, _accPitch = 0;
  DateTime? _lastGyroTime;
  static const _alpha = 0.92;
  static const _clamp = 0.30;
  double _deadzone(double v, [double eps = 0.02]) => v.abs() < eps ? 0 : v;

  // Baseline con calibrazione ritardata
  double? _offsetRoll, _offsetPitch;
  Timer? _calibTimer;
  bool _calibrated = false;

  late final PageController _page;
  late final AnimationController _glow;

  // -------- dealers + posizione utente --------
  List<DealerPoint> _dealers = const [];
  Position? _pos;
  String? _loadError;

  // -------- catalogo completo --------
  List<Car>? _allCars;
  bool _loadingCars = false;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 0.78);
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_initData(), _ensureAllCarsLoaded()]);
    _startSensors();
  }

  Future<void> _ensureAllCarsLoaded() async {
    if (widget.allCars != null) {
      setState(() => _allCars = widget.allCars);
      return;
    }
    try {
      setState(() => _loadingCars = true);
      final all = await LocalCatalog.load();
      if (!mounted) return;
      setState(() {
        _allCars = all;
        _loadingCars = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allCars = null;
        _loadingCars = false;
      });
    }
  }

  Future<Position?> _getPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      return null;
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _initData() async {
    try {
      final dealers = await DealersRepo.load();
      final pos = await _getPosition();
      if (!mounted) return;
      setState(() {
        _dealers = dealers;
        _pos = pos;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.toString());
    }
  }

  void _startSensors() {
    _accSub = accelerometerEventStream().listen((e) {
      final ax = e.x.toDouble(), ay = e.y.toDouble(), az = e.z.toDouble();
      _accRoll = math.atan2(ay, az);
      _accPitch = math.atan2(-ax, math.sqrt(ay * ay + az * az));
    });

    _gyroSub = gyroscopeEventStream().listen((g) {
      final now = DateTime.now();
      final dt = _lastGyroTime == null
          ? 0.016
          : (now.difference(_lastGyroTime!).inMicroseconds / 1e6);
      _lastGyroTime = now;

      _roll  = (_alpha * (_roll  + g.y * dt)) + ((1 - _alpha) * _accRoll);
      _pitch = (_alpha * (_pitch + g.x * dt)) + ((1 - _alpha) * _accPitch);

      _roll  = _roll.clamp(-_clamp, _clamp);
      _pitch = _pitch.clamp(-_clamp, _clamp);

      // Calibrazione ritardata
      _calibTimer ??= Timer(const Duration(milliseconds: 400), () {
        _offsetRoll  = _roll;
        _offsetPitch = _pitch;
        _calibrated = true;
        if (mounted) setState(() {});
      });

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _glow.dispose();
    _page.dispose();
    _calibTimer?.cancel();
    _accSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = _allCars ?? widget.allCars ?? widget.cars;
    final cars = source.where((c) => c.incoming).toList();

    if (_loadingCars) {
      return const Scaffold(
        appBar: _IncomingAppBar(),
        body: Stack(
          children: [
            DarkLiveBackground(),
            SafeArea(
              top: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    if (cars.isEmpty) {
      return const Scaffold(
        appBar: _IncomingAppBar(),
        body: Stack(
          children: [
            DarkLiveBackground(),
            SafeArea(
              top: false,
              child: Center(child: Text('Nessuna auto in arrivo.')),
            ),
          ],
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: const _IncomingAppBar(),
        body: Stack(
          children: [
            const DarkLiveBackground(),
            SafeArea(
              top: false,
              child: Center(child: Text('Errore: caricamento dealer.')),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: const _IncomingAppBar(),
      body: Stack(
        children: [
          const DarkLiveBackground(),
          SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemCount: cars.length,
                    itemBuilder: (context, i) {
                      final car = cars[i];
                      final eta = DateTime.now().add(
                        Duration(days: (car.id.hashCode % 20).abs() + 3),
                      );
                      final dealer = _nearestDealerFor(car);

                      double rotX = 0, rotY = 0;
                      if (_calibrated && _offsetRoll != null && _offsetPitch != null) {
                        rotX = _deadzone(_pitch - _offsetPitch!) * 0.50;
                        rotY = -_deadzone(_roll  - _offsetRoll! ) * 0.40;
                      }

                      return Transform(
                        alignment: Alignment.center,
                        transform: _perspective(rotX: rotX, rotY: rotY),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: FlipIncomingCard(
                            car: car,
                            eta: eta,
                            dealer: dealer,
                            glow: _glow,
                            userPos: _pos,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _AvailabilityBanner(
                    city: _nearestDealerFor(cars[_index])?.city ?? '—',
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
      bottomNavigationBar: AppBottomBar(
        currentIndex: 2,
        cars: source,
        allCars: _allCars ?? widget.allCars ?? source,
        rates: null,
        preferredCurrency: 'EUR',
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfilePage(
                initialCurrency: 'EUR',
                onChanged: (_) {},
                cars: source,
                rates: null,
              ),
            ),
          );
        },
      ),
    );
  }

  DealerPoint? _nearestDealerFor(Car car) {
    if (_dealers.isEmpty) return null;

    final List<DealerPoint> candidates;
    if (car.availableAt.isNotEmpty) {
      final byId = {for (final d in _dealers) d.id: d};
      candidates = [
        for (final id in car.availableAt)
          if (byId.containsKey(id)) byId[id]!,
      ];
      if (candidates.isEmpty) return null;
    } else {
      candidates = _dealers;
    }

    if (_pos == null) return candidates.first;

    final user = LatLng(_pos!.latitude, _pos!.longitude);
    DealerPoint best = candidates.first;
    double bestD =
        _haversine(user.latitude, user.longitude, best.lat, best.lng);

    for (int i = 1; i < candidates.length; i++) {
      final d = candidates[i];
      final dist =
          _haversine(user.latitude, user.longitude, d.lat, d.lng);
      if (dist < bestD) {
        bestD = dist;
        best = d;
      }
    }
    return best;
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(1 - a), math.sqrt(a));
    return R * c;
  }

  double _toRad(double d) => d * math.pi / 180.0;

  Matrix4 _perspective({double rotX = 0, double rotY = 0}) {
    return Matrix4.identity()
      ..setEntry(3, 2, 0.0016)
      ..rotateX(rotX)
      ..rotateY(rotY);
  }
}

/* ---------------- AppBar con titolo a gradiente ---------------- */

class _IncomingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _IncomingAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0E0E0F),
      elevation: 0,
      centerTitle: true,
      toolbarHeight: preferredSize.height,
      title: const _GradientText(
        'In Arrivo',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
          color: Colors.white,
        ),
        colors: [Colors.orangeAccent, Colors.deepOrange],
      ),
    );
  }
}

/* ---------------- GradientText ---------------- */

class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<Color> colors;

  const _GradientText(this.text, {required this.style, required this.colors});

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

/* ---------------- Availability Banner ---------------- */

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