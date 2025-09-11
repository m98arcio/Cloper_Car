import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/car.dart';

class CatalogApi {
  final String? baseUrl;
  CatalogApi({this.baseUrl});

  Future<List<Car>> fetchCars() async {
    // Try network first if baseUrl provided
    if (baseUrl != null && baseUrl!.isNotEmpty) {
      try {
        final r = await http.get(Uri.parse(baseUrl!));
        if (r.statusCode == 200) {
          final data = json.decode(r.body) as List;
          return data.map((e) => Car.fromJson(e)).toList();
        }
      } catch (_) {}
    }
    // Fallback to bundled assets
    final local = await rootBundle.loadString('assets/cars.json');
    final data = json.decode(local) as List;
    return data.map((e) => Car.fromJson(e)).toList();
  }
}
