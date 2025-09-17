import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/car.dart';
import '../screens/Incoming_page.dart'; // per la classe Dealer

class FlipIncomingCard extends StatefulWidget {
  final Car car;
  final DateTime eta;
  final Dealer? dealer;
  final AnimationController glow;
  final Position? userPos;

  const FlipIncomingCard({
    required this.car,
    required this.eta,
    required this.dealer,
    required this.glow,
    required this.userPos,
    super.key,
  });

  @override
  State<FlipIncomingCard> createState() => _FlipIncomingCardState();
}

class _FlipIncomingCardState extends State<FlipIncomingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;
  bool get _isBack => _flip.value >= 0.5;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
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
          final angle = _flip.value * math.pi;
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
                  Opacity(
                    opacity: showBack ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: showBack,
                      child: _FrontFace(
                        car: widget.car,
                        eta: widget.eta,
                        glow: widget.glow,
                      ),
                    ),
                  ),
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: Opacity(
                      opacity: showBack ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !showBack,
                        child: _BackFace(
                          car: widget.car,
                          eta: widget.eta,
                          dealer: widget.dealer,
                          userPos: widget.userPos,
                        ),
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
}

/* ========================= FRONT FACE ========================= */

class _FrontFace extends StatelessWidget {
  final Car car;
  final DateTime eta;
  final AnimationController glow;

  const _FrontFace({
    required this.car,
    required this.eta,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String img = car.images.isNotEmpty ? car.images.first : 'assets/macchine/supercar.jpg';

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
              errorBuilder: (_, __, ___) =>
                  Image.asset('assets/macchine/supercar.jpg', fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
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

/* ========================= BACK FACE ========================= */

class _BackFace extends StatelessWidget {
  final Car car;
  final DateTime eta;
  final Dealer? dealer;
  final Position? userPos;

  const _BackFace({
    required this.car,
    required this.eta,
    required this.dealer,
    required this.userPos,
  });

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

    final latLng = dealer != null
        ? LatLng(dealer!.lat, dealer!.lng)
        : const LatLng(41.9028, 12.4964);

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
          // header, specs e mappa simili alla versione originale
        ],
      ),
    );
  }
}
