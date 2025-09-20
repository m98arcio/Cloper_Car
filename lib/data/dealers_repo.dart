import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/dealer_point.dart';

class DealersRepo {
  static List<DealerPoint>? _cache;

  static Future<List<DealerPoint>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/dealers.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _cache = list.map(DealerPoint.fromJson).toList();
    return _cache!;
  }

  /// Dealer più vicino a [origin]; se [allowedDealerIds] è non-vuoto, filtra.
  static Future<DealerPoint> nearestTo(
    LatLng origin, {
    List<String>? allowedDealerIds,
  }) async {
    final all = await load();
    final candidates = (allowedDealerIds != null && allowedDealerIds.isNotEmpty)
        ? all.where((d) => allowedDealerIds.contains(d.id)).toList()
        : all;

    if (candidates.isEmpty) {
      throw StateError('Nessun dealer corrisponde al filtro specificato.');
    }

    DealerPoint best = candidates.first;
    double bestDist = _distanceMeters(origin.latitude, origin.longitude, best.lat, best.lng);

    for (int i = 1; i < candidates.length; i++) {
      final d = candidates[i];
      final dist = _distanceMeters(origin.latitude, origin.longitude, d.lat, d.lng);
      if (dist < bestDist) {
        best = d;
        bestDist = dist;
      }
    }
    return best;
  }

  /// Haversine (metri)
  static double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * (math.pi / 180.0);
}