import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/car.dart';
import '../models/dealer_point.dart';

class FlipIncomingCard extends StatefulWidget {
  final Car car;
  final DateTime eta;
  final DealerPoint? dealer;
  final AnimationController glow;
  final Position? userPos;

  const FlipIncomingCard({
    super.key,
    required this.car,
    required this.eta,
    required this.dealer,
    required this.glow,
    required this.userPos,
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
                  // FRONT
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
                  // BACK
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
    final img = car.images.isNotEmpty
        ? car.images.first
        : 'assets/macchine/supercar.jpg';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: cs.primary
                .withOpacity(0.3 * (0.6 + 0.4 * math.sin(glow.value * math.pi))),
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
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/macchine/supercar.jpg',
                fit: BoxFit.cover,
              ),
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
          // Pill "Arrivo"
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Arrivo',
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Text(_fmtDate(eta),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          // Titolo + hint
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
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'Tocca la card per saperne di più',
                    style:
                        TextStyle(fontSize: 13, color: Colors.white70),
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
  final DealerPoint? dealer;
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

    final hasDealer = dealer != null;
    final LatLng? latLng = hasDealer ? dealer!.latLng : null;

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
          // Header titolo + data
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${car.brand} ${car.model}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    _fmtDate(eta),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // Specs
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                children: specs
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(s,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Mappa SOLO se esiste un dealer
          if (hasDealer)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: latLng!, zoom: 12.5),
                  markers: {
                    Marker(
                      markerId: const MarkerId('dealer'),
                      position: latLng,
                      infoWindow: InfoWindow(
                        title: dealer!.name,
                        snippet: dealer!.city,
                        onTap: () => _openExternalMaps(
                          dealer!.lat,
                          dealer!.lng,
                        ),
                      ),
                    ),
                    if (userPos != null)
                      Marker(
                        markerId: const MarkerId('me'),
                        position: LatLng(
                            userPos!.latitude, userPos!.longitude),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure),
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

          // Footer (se non c'è dealer → messaggio richiesto)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                hasDealer
                    ? 'Concessionario più vicino: ${dealer!.name} — ${dealer!.city}'
                    : "L'auto non è disponibile",
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternalMaps(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}