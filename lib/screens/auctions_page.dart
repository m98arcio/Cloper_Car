import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/car.dart';
import '../widgets/dark_live_background.dart';

/// ViewModel minimale per la UI aste (deriva da Car)
class CarAuctionVM {
  final String id;
  final String title;
  final String subtitle;
  final String assetImage;
  final double currentBid;
  final Duration timeLeft;

  CarAuctionVM({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetImage,
    required this.currentBid,
    required this.timeLeft,
  });

  factory CarAuctionVM.fromCar(Car c) {
    final img = (c.images.isNotEmpty) ? c.images.first : 'assets/supercar.jpg';
    final parts = <String>[];
    if ((c.engine ?? '').isNotEmpty) parts.add(c.engine!);
    parts.add('${c.powerHp} CV');
    final subt = parts.join(' • ');
    // timer fittizio ma deterministico (se vuoi un campo 'auctionEndsAt' mettilo qui)
    final h = (c.id.hashCode % 8).abs() + 2; // 2..9 ore
    return CarAuctionVM(
      id: c.id,
      title: '${c.brand} ${c.model}',
      subtitle: subt,
      assetImage: img,
      currentBid: c.priceEur,
      timeLeft: Duration(hours: h, minutes: 15),
    );
  }
}

/// Controller sensori con fusione semplice acc+gyro
class MotionController with ChangeNotifier {
  StreamSubscription? _accSub;
  StreamSubscription? _gyroSub;

  double _roll = 0.0; // rad
  double _pitch = 0.0; // rad
  double _accRoll = 0.0, _accPitch = 0.0;
  DateTime? _lastGyroTime;

  // filtro complementare
  static const double _alpha = 0.92;
  // limiti per evitare valori estremi
  static const double _clamp = 0.30;

  // buffer per oscilloscopio
  final List<double> oscGyroX = List.filled(256, 0);
  final List<double> oscGyroY = List.filled(256, 0);
  int _oscIndex = 0;

  double get roll => _roll;
  double get pitch => _pitch;

  void start() {
    _accSub = accelerometerEventStream().listen((e) {
      final ax = e.x.toDouble(), ay = e.y.toDouble(), az = e.z.toDouble();
      _accRoll = math.atan2(ay, az);
      _accPitch = math.atan2(-ax, math.sqrt(ay * ay + az * az));
    });

    _gyroSub = gyroscopeEventStream().listen((g) {
      final now = DateTime.now();
      final dt =
          _lastGyroTime == null
              ? 0.016
              : (now.difference(_lastGyroTime!).inMicroseconds / 1e6);
      _lastGyroTime = now;

      _roll = (_alpha * (_roll + g.x * dt)) + ((1 - _alpha) * _accRoll);
      _pitch = (_alpha * (_pitch + g.y * dt)) + ((1 - _alpha) * _accPitch);

      _roll = _roll.clamp(-_clamp, _clamp);
      _pitch = _pitch.clamp(-_clamp, _clamp);

      oscGyroX[_oscIndex] = g.x;
      oscGyroY[_oscIndex] = g.y;
      _oscIndex = (_oscIndex + 1) % oscGyroX.length;

      notifyListeners();
    });
  }

  void stop() {
    _accSub?.cancel();
    _gyroSub?.cancel();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

class AuctionPage extends StatefulWidget {
  const AuctionPage({super.key, required this.items});
  final List<Car> items; // ← viene dal JSON già caricato nell’app

  @override
  State<AuctionPage> createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage>
    with SingleTickerProviderStateMixin {
  late final MotionController motion;
  late final PageController pageController;
  late final AnimationController glowController;
  late final List<CarAuctionVM> auctions;
  double _deadzone(double v, [double eps = 0.025]) => (v.abs() < eps) ? 0.0 : v;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    motion = MotionController()..start();
    pageController = PageController(viewportFraction: 0.78);
    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    auctions = widget.items.map(CarAuctionVM.fromCar).toList();
  }

  @override
  void dispose() {
    glowController.dispose();
    pageController.dispose();
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (auctions.isEmpty) {
      return Scaffold(
        body: Stack(
          children: const [
            DarkLiveBackground(),
            SafeArea(
              child: Center(child: Text('Nessuna auto in asta al momento.')),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          const DarkLiveBackground(),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _TopBar(),
                const SizedBox(height: 8),

                // --- CAROSELLO ---
                Expanded(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([motion, pageController]),
                    builder: (context, _) {
                      return PageView.builder(
                        controller: pageController,
                        onPageChanged: (i) => setState(() => currentIndex = i),
                        itemCount: auctions.length,
                        itemBuilder: (context, index) {
                          final car = auctions[index];
                          final page =
                              pageController.hasClients &&
                                      pageController.page != null
                                  ? pageController.page!
                                  : currentIndex.toDouble();
                          final delta = index - page;
                          final isCurrent = index == currentIndex;

                          // Card DRITTA: nessuna inclinazione base
                          final rotY =
                              _deadzone(motion.roll) * 0.5; // sensibilità lieve
                          final rotX = _deadzone(motion.pitch) * 0.4;
                          final scale = (1 - (delta.abs() * 0.05)).clamp(
                            0.95,
                            1.0,
                          );

                          return Transform(
                            alignment: Alignment.center,
                            transform: _perspective(
                              rotX: rotX,
                              rotY: rotY,
                              translateZ: -60 * delta,
                              scale: scale,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              child: _AuctionCard(
                                car: car,
                                highlight: isCurrent,
                                glowPhase: glowController,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // --- OSCILLOSCOPIO (nessuna scritta) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: SizedBox(
                    height: 84,
                    child: AnimatedBuilder(
                      animation: motion,
                      builder:
                          (context, _) => DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: CustomPaint(
                              painter: _OscilloscopePainter(
                                valuesA: motion.oscGyroX,
                                valuesB: motion.oscGyroY,
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // NB: rimosso FAB "Partecipa all’asta"
        ],
      ),
    );
  }

  Matrix4 _perspective({
    double rotX = 0,
    double rotY = 0,
    double rotZ = 0,
    double translateZ = 0,
    double scale = 1.0,
  }) {
    return Matrix4.identity()
      ..setEntry(3, 2, 0.0016)
      ..multiply(Matrix4.diagonal3Values(scale, scale, scale))
      ..rotateX(rotX)
      ..rotateY(rotY)
      ..rotateZ(rotZ)
      ..translate(0.0, 0.0, translateZ);
  }
}

/// ---------- UI WIDGETS ----------
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        height: 44,
        child: Center(
          child: Text(
            'Aste',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuctionCard extends StatelessWidget {
  final CarAuctionVM car;
  final bool highlight;
  final AnimationController glowPhase;

  const _AuctionCard({
    required this.car,
    required this.highlight,
    required this.glowPhase,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight ? cs.primary.withOpacity(0.35) : Colors.white10,
          width: highlight ? 2 : 1,
        ),
        boxShadow: [
          if (highlight)
            BoxShadow(
              color: cs.primary.withOpacity(
                0.32 * (0.6 + 0.4 * math.sin(glowPhase.value * math.pi)),
              ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Immagine asset
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 350),
                tween: Tween(begin: 0.9, end: highlight ? 1 : 0.92),
                builder:
                    (context, v, child) => ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.12 * (1 - v)),
                        BlendMode.darken,
                      ),
                      child: child,
                    ),
                child: Image.asset(
                  car.assetImage,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        color: Colors.black26,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.white70,
                        ),
                      ),
                ),
              ),
            ),

            // sfumatura inferiore
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // timer in alto
            Positioned(
              right: 14,
              top: 14,
              child: _TimeBadge(duration: car.timeLeft),
            ),

            // footer info + prezzo corrente
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          car.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          car.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.primary.withOpacity(0.45)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Prezzo Di Partenza',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              height: 1,
                            ),
                          ),
                          Text(
                            '€ ${_fmt(car.currentBid)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && (idx - 1) % 3 == 0) b.write('.');
    }
    return b.toString();
  }
}

class _TimeBadge extends StatefulWidget {
  final Duration duration;
  const _TimeBadge({required this.duration});

  @override
  State<_TimeBadge> createState() => _TimeBadgeState();
}

class _TimeBadgeState extends State<_TimeBadge> {
  late Duration left;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    left = widget.duration;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        left = left - const Duration(seconds: 1);
        if (left.isNegative) left = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = left.inHours.toString().padLeft(2, '0');
    final m = left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = left.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, size: 16),
          const SizedBox(width: 6),
          Text('$h:$m:$s', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Oscilloscopio: due tracce, griglia centrale, linee più nitide
class _OscilloscopePainter extends CustomPainter {
  final List<double> valuesA; // gyro X
  final List<double> valuesB; // gyro Y
  _OscilloscopePainter({required this.valuesA, required this.valuesB});

  @override
  void paint(Canvas canvas, Size size) {
    // riga centrale
    final mid =
        Paint()
          ..color = Colors.white12
          ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      mid,
    );

    // helper
    double mapY(double v, double amp) {
      final clamped = v.clamp(-amp, amp);
      return size.height / 2 - (clamped / amp) * (size.height / 2 - 6);
    }

    final n = valuesA.length;
    final pathA = Path();
    final pathB = Path();
    for (int i = 0; i < n; i++) {
      final x = (i / (n - 1)) * size.width;
      final yA = mapY(valuesA[i], 6);
      final yB = mapY(valuesB[i], 6);
      if (i == 0) {
        pathA.moveTo(x, yA);
        pathB.moveTo(x, yB);
      } else {
        pathA.lineTo(x, yA);
        pathB.lineTo(x, yB);
      }
    }

    final paintA =
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final paintB =
        Paint()
          ..color = Colors.purpleAccent.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawPath(pathA, paintA);
    canvas.drawPath(pathB, paintB);
  }

  @override
  bool shouldRepaint(covariant _OscilloscopePainter old) =>
      old.valuesA != valuesA || old.valuesB != valuesB;
}
