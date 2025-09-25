import 'package:google_maps_flutter/google_maps_flutter.dart';

class DealerPoint {
  final String id;
  final String name;
  final String city;
  final double lat;
  final double lng;

  const DealerPoint({
    required this.id,
    required this.name,
    required this.city,
    required this.lat,
    required this.lng,
  });

  LatLng get latLng => LatLng(lat, lng);

  factory DealerPoint.fromJson(Map<String, dynamic> json) {
    return DealerPoint(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}
