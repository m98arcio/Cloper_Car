import 'package:flutter/material.dart';
import '../models/car.dart';
import 'car_list_page.dart';

class BrandCatalogPage extends StatelessWidget {
  final List<Car> cars;
  final Map<String, double>? rates;
  final String preferredCurrency;

  const BrandCatalogPage({
    super.key,
    required this.cars,
    this.rates,
    required this.preferredCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final brands = _uniqueBrands(cars);
    final thumbs = _brandThumbnails(cars);

    return Scaffold(
      appBar: AppBar(title: const Text('Catalogo')),
      backgroundColor: const Color(0xFF1B171A),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: brands.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.05,
        ),
        itemBuilder: (_, i) {
          final b = brands[i];
          final cover = thumbs[b] ?? 'assets/supercar.jpg';
          return InkWell(
            onTap: () {
              final filtered = cars.where((c) => c.brand.toLowerCase() == b.toLowerCase()).toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CarListPage(
                    brand: b,
                    cars: filtered,
                    rates: rates,
                    preferredCurrency: preferredCurrency,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF262027),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Image.asset(cover, fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      b,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _uniqueBrands(List<Car> cars) {
    final s = <String>{};
    for (final c in cars) s.add(c.brand);
    final list = s.toList()..sort();
    return list;
  }

  Map<String, String> _brandThumbnails(List<Car> cars) {
    final map = <String, String>{};
    for (final c in cars) {
      if (!map.containsKey(c.brand) && c.images.isNotEmpty) {
        map[c.brand] = c.images.first;
      }
    }
    return map;
  }
}