import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/car.dart';
import '../widgets/tilt_gallery.dart';

class CarDetailPage extends StatefulWidget {
  final Car car;
  const CarDetailPage({super.key, required this.car});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  Position? _pos;
  String? _locError;
  GoogleMapController? _map;

  @override
  void initState() {
    super.initState();
    _safeGetPosition();
  }

  /// Richiede i permessi e recupera la posizione in modo sicuro.
  /// Mostra messaggi di errore (senza crash) e consente di riprovare.
  Future<void> _safeGetPosition() async {
    if (!mounted) return;
    setState(() {
      _locError = null;
      _pos = null;
    });

    try {
      // 1) Servizi di localizzazione attivi?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS disattivato. Attivalo e riprova.');
      }

      // 2) Permessi
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Permesso posizione negato.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Permesso posizione negato in modo permanente.\n'
          'Apri le Impostazioni e abilita la posizione per l’app.',
        );
      }

      // 3) Posizione corrente
      final p = await Geolocator.getCurrentPosition();

      if (!mounted) return;
      setState(() => _pos = p);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locError = e.toString());
    }
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;

    return Scaffold(
      appBar: AppBar(title: Text('${car.brand} ${car.model}')),
      body: ListView(
        children: [
          // Gallery con accelerometro (tilt)
          TiltGallery(images: car.images),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prezzo: € ${car.priceEur.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Potenza: ${car.powerHp} HP'),
                const SizedBox(height: 16),

                Text('Concessionari vicini',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                SizedBox(height: 220, child: _mapSection()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Costruisce la sezione mappa in modo resiliente:
  /// - Se errore → messaggio + pulsante "Riprova"
  /// - Se in attesa → progress indicator
  /// - Se posizione pronta → GoogleMap con marker demo e navigazione
  Widget _mapSection() {
    if (_locError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _locError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _safeGetPosition,
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pos == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = LatLng(_pos!.latitude, _pos!.longitude);

    // Concessionari (demo) vicini alla posizione dell'utente
    final dealers = <LatLng>[
      LatLng(user.latitude + 0.010, user.longitude + 0.010),
      LatLng(user.latitude - 0.012, user.longitude + 0.008),
      LatLng(user.latitude + 0.008, user.longitude - 0.009),
    ];

    final markers = dealers.asMap().entries.map((e) {
      final idx = e.key;
      final pos = e.value;
      return Marker(
        markerId: MarkerId('dealer_$idx'),
        position: pos,
        infoWindow: InfoWindow(
          title: 'Concessionario #${idx + 1}',
          snippet: 'Tocca per navigare',
          onTap: () async {
            final uri = Uri.parse(
                'google.navigation:q=${pos.latitude},${pos.longitude}');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
        ),
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: user, zoom: 13),
      myLocationEnabled: true,
      markers: markers,
      onMapCreated: (c) => _map = c,
      // Evita gesture eccessive su device lenti
      compassEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
    );
  }
}