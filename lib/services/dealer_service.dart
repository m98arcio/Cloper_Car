import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import "dart:math" as math;

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
  DealersRepo._();
  static List<DealerPoint>? _cache;

  static Future<List<DealerPoint>> load() async {
    if (_cache != null) return _cache!;
    final txt = await rootBundle.loadString('assets/data/dealers.json');
    final list = (json.decode(txt) as List).cast<Map<String, dynamic>>();
    _cache = list.map(DealerPoint.fromJson).toList();
    return _cache!;
  }

  /// Trova il dealer più vicino tra un sottoinsieme [allowedDealerIds].
  /// Se la lista è vuota o null, considera TUTTI i dealer.
  static Future<DealerPoint> nearestTo(
    LatLng user, {
    List<String>? allowedDealerIds,
  }) async {
    final all = await load();
    final pool = (allowedDealerIds == null || allowedDealerIds.isEmpty)
        ? all
        : all.where((d) => allowedDealerIds.contains(d.id)).toList();

    DealerPoint best = pool.first;
    double bestDist = _haversine(user, best.latLng);
    for (final d in pool.skip(1)) {
      final dist = _haversine(user, d.latLng);
      if (dist < bestDist) {
        best = d;
        bestDist = dist;
      }
    }
    return best;
  }

  static double _haversine(LatLng a, LatLng b) {
    const R = 6371e3; // metri
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);

    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);

    return 2 * R * math.asin(math.min(1, math.sqrt(h)));
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;
}