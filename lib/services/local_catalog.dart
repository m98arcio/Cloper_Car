import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/car.dart';

class LocalCatalog {
  // Carica l'elenco delle auto dal file JSON locale
  static Future<List<Car>> load() async {
    // legge il file come stringa
    final raw = await rootBundle.loadString('assets/cars.json');

    // converte la stringa JSON in lista di mappe
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();

    // trasforma ogni mappa in oggetto Car
    return list.map(Car.fromJson).toList();
  }
}