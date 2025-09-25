import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/dealers_repo.dart';
import '../models/dealer_point.dart';
import '../models/car.dart';

// Card con mappa che mostra i concessionari per un’auto
class DealerMapCard extends StatefulWidget {
  final Car car;
  final double height;

  const DealerMapCard({
    super.key,
    required this.car,
    this.height = 220,
  });

  @override
  State<DealerMapCard> createState() => _DealerMapCardState();
}

class _DealerMapCardState extends State<DealerMapCard> {
  GoogleMapController? _controller;   // controller mappa
  CameraPosition? _initial;           // posizione iniziale camera
  Set<Marker> _markers = const {};    // marker dei dealer + utente
  String? _centeredDealerId;          // dealer attualmente centrato
  double? _nearestDistanceM;          // distanza dal più vicino

  String? _error;                     // errori geolocalizzazione
  Position? _pos;                     // posizione utente

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  // Avvio: chiede permessi + posizione, poi prepara mappa
  Future<void> _bootstrap() async {
    try {
      // controlla servizi attivi
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _error = 'Servizi di localizzazione disabilitati.');
        return;
      }

      // gestisce permessi posizione
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        setState(() => _error = 'Permesso posizione negato.');
        return;
      }

      // prende posizione utente
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() => _pos = pos);

      await _prepare();
    } catch (e) {
      setState(() => _error = 'Errore geolocalizzazione: $e');
    }
  }

  // Prepara marker + camera centrata sul dealer più vicino
  Future<void> _prepare() async {
    if (!mounted || _pos == null) return;

    final all = await DealersRepo.load();
    final byId = {for (final d in all) d.id: d};

    // Filtra dealer se l’auto ha restrizioni
    final allowedIds = widget.car.availableAt;
    List<DealerPoint> visible;
    if (allowedIds.isNotEmpty) {
      visible = [
        for (final id in allowedIds)
          if (byId.containsKey(id)) byId[id]!,
      ];
      if (visible.isEmpty) {
        setState(() => _error = 'Nessun dealer valido per questa auto.');
        return;
      }
    } else {
      visible = all;
    }

    final user = LatLng(_pos!.latitude, _pos!.longitude);
    final nearest = await DealersRepo.nearestTo(
      user,
      allowedDealerIds: visible.map((d) => d.id).toList(),
    );

    final distM = _distanceMeters(
        user.latitude, user.longitude, nearest.lat, nearest.lng);

    // marker: utente + dealer
    final markers = <Marker>{
      for (final d in visible)
        Marker(
          markerId: MarkerId(d.id),
          position: d.latLng,
          icon: d.id == nearest.id
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: d.name,
            snippet: d.id == nearest.id
                ? '${d.city} · più vicino (${_formatDistance(distM)})'
                : d.city,
            onTap: () => _openExternalMaps(d.lat, d.lng),
          ),
        ),
      Marker(
        markerId: const MarkerId('me'),
        position: user,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'La tua posizione'),
      ),
    };

    final shouldAnimate =
        _controller != null && _centeredDealerId != nearest.id;

    setState(() {
      _markers = markers;
      _initial ??= CameraPosition(target: nearest.latLng, zoom: 11.5);
      _centeredDealerId = nearest.id;
      _nearestDistanceM = distM;
    });

    if (shouldAnimate && _controller != null) {
      await _controller!
          .animateCamera(CameraUpdate.newLatLngZoom(nearest.latLng, 11.5));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _errorBox(_error!, _bootstrap);
    if (_pos == null || _initial == null) return _skeleton(widget.height);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // mappa google
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFEF).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(22),
          ),
          clipBehavior: Clip.antiAlias,
          child: GoogleMap(
            initialCameraPosition: _initial!,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            markers: _markers,
            onMapCreated: (c) => _controller = c,
          ),
        ),
        // banner sotto la mappa con info dealer più vicino
        if (_centeredDealerId != null && _nearestDistanceM != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 6, right: 6),
            child: FutureBuilder<List<DealerPoint>>(
              future: DealersRepo.load(),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final d = snap.data!.firstWhere(
                    (x) => x.id == _centeredDealerId!,
                    orElse: () => snap.data!.first);
                return _NearestBanner(
                  title: d.name,
                  city: d.city,
                  distanceMeters: _nearestDistanceM!,
                  onNavigate: () => _openExternalMaps(d.lat, d.lng),
                );
              },
            ),
          ),
      ],
    );
  }

  //UI helper per caricamento/errore
  Widget _skeleton(double h) => Container(
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );

  Widget _errorBox(String msg, VoidCallback onRetry) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF).withValues(alpha: 0.07),
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

  //funzioni di supporto
  Future<void> _openExternalMaps(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  //formatta la distanza in un testo leggibile
  String _formatDistance(double meters) =>
      meters < 950 ? '${meters.toStringAsFixed(0)} m' : '${(meters / 1000).toStringAsFixed(1)} km';

  // distanza con formula Haversine
  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * R * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * (math.pi / 180.0);
}

//Banner sotto la mappa con info del dealer più vicino
class _NearestBanner extends StatelessWidget {
  final String title;
  final String city;
  final double distanceMeters;
  final VoidCallback onNavigate;

  const _NearestBanner({
    required this.title,
    required this.city,
    required this.distanceMeters,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final dist = distanceMeters < 950
        ? '${distanceMeters.toStringAsFixed(0)} m'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.place, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$title · $city · $dist',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          TextButton(onPressed: onNavigate, child: const Text('Naviga')),
        ],
      ),
    );
  }
}