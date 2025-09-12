import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/car.dart';

class LocalCatalog {
  static Future<List<Car>> load() async {
    final raw = await rootBundle.loadString('assets/cars.json');
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Car.fromJson).toList();
  }
}