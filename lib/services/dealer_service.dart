import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class DealerPoint {
  final String id;
  final String name;
  final String city;
  final LatLng latLng;

  DealerPoint({
    required this.id,
    required this.name,
    required this.city,
    required this.latLng,
  });

  // crea un DealerPoint da JSON (dati presi dal file dealers.json)
  factory DealerPoint.fromJson(Map<String, dynamic> j) => DealerPoint(
        id: j['id'] as String,
        name: j['name'] as String,
        city: j['city'] as String,
        latLng: LatLng(
          (j['lat'] as num).toDouble(),
          (j['lng'] as num).toDouble(),
        ),
      );
}

class DealersRepo {
  static List<DealerPoint>? _cache; // cache per evitare ricariche

  // Carica i dealer dal file JSON (solo la prima volta, poi usa la cache)
  static Future<List<DealerPoint>> load() async {
    if (_cache != null) return _cache!;
    final txt = await rootBundle.loadString('assets/dealers.json');
    final raw = json.decode(txt) as List<dynamic>;
    _cache = raw
        .map((e) => DealerPoint.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  // Trova il dealer più vicino a una posizione utente.
  // Se passo degli ID, considera solo quelli.
  static Future<DealerPoint> nearestTo(
    LatLng user, {
    List<String>? allowedDealerIds,
  }) async {
    final all = await load();

    // filtra per allowedDealerIds (se forniti)
    final pool = (allowedDealerIds == null || allowedDealerIds.isEmpty)
        ? all
        : all.where((d) => allowedDealerIds.contains(d.id)).toList();

    // se il filtro è vuoto, usa comunque tutti
    final list = pool.isEmpty ? all : pool;

    // calcola il più vicino
    DealerPoint best = list.first;
    double bestDist = _haversine(user, best.latLng);
    for (final d in list.skip(1)) {
      final dist = _haversine(user, d.latLng);
      if (dist < bestDist) {
        best = d;
        bestDist = dist;
      }
    }
    return best;
  }

  // formula di Haversine -> distanza in metri tra due coordinate
  static double _haversine(LatLng a, LatLng b) {
    const R = 6371e3; // raggio Terra in metri
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);

    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);

    return 2 * R * math.asin(math.min(1, math.sqrt(h)));
  }

  // converte gradi in radianti
  static double _toRad(double deg) => deg * math.pi / 180.0;
}