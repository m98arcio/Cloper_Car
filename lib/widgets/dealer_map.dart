import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/dealers_repo.dart';
import '../models/dealer_point.dart';
import '../models/car.dart';

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
  GoogleMapController? _controller;
  CameraPosition? _initial;
  Set<Marker> _markers = const {};
  String? _centeredDealerId;
  double? _nearestDistanceM;

  String? _error;
  Position? _pos;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // 1) Permessi + posizione
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _error = 'Servizi di localizzazione disabilitati.');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        setState(() => _error = 'Permesso posizione negato.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _pos = pos;
      });

      // 2) Prepara mappa
      await _prepare();
    } catch (e) {
      setState(() => _error = 'Errore geolocalizzazione: $e');
    }
  }

  Future<void> _prepare() async {
    if (!mounted) return;
    if (_pos == null) return;

    final all = await DealersRepo.load();
    final byId = {for (final d in all) d.id: d};

    // Se l’auto limita i dealer, filtra; altrimenti usa tutti
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

    // Marker dei dealer (evidenzia il più vicino in verde)
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
    if (_error != null) {
      return _errorBox(_error!, _bootstrap);
    }

    if (_pos == null || _initial == null) {
      return _skeleton(widget.height);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
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
            onMapCreated: (c) => _controller = c,
          ),
        ),
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

  // --- helpers UI/geo ---

  Widget _skeleton(double h) => Container(
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF).withOpacity(0.07),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );

  Widget _errorBox(String msg, VoidCallback onRetry) {
    return Container(
      height: widget.height,
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

  Future<void> _openExternalMaps(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDistance(double meters) {
    if (meters < 950) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * (math.pi / 180.0);
}

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
