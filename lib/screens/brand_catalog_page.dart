import 'package:flutter/material.dart';
import '../models/car.dart';
import 'car_list_page.dart';
import '../widgets/brand_logo.dart';

class BrandCatalogPage extends StatelessWidget {
  final List<Car> cars;
  const BrandCatalogPage({super.key, required this.cars});

  @override
  Widget build(BuildContext context) {
    final brands = _uniqueBrands(cars);
    final thumbs = _brandThumbnails(cars);

    return Scaffold(
      appBar: AppBar(title: const Text('Catalogo')),
      backgroundColor: const Color(0xFF1B171A),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: brands.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (_, i) {
            final b = brands[i];
            final img = thumbs[b];
            final filtered =
                cars
                    .where((c) => c.brand.toLowerCase() == b.toLowerCase())
                    .toList();
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CarListPage(brand: b, cars: filtered),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF262027),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: Center(
                          child: BrandLogo(
                            brand: b,
                            imagePath: img,
                            size: 90,
                            round:
                                false, // rettangolare per riempire bene la card
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        b,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<String> _uniqueBrands(List<Car> cars) {
    final set = <String>{};
    for (final c in cars) set.add(c.brand);
    final list = set.toList()..sort();
    return list;
  }

  Map<String, String> _brandThumbnails(List<Car> cars) {
    final map = <String, String>{};
    for (final c in cars) {
      map.putIfAbsent(c.brand, () => c.images.first);
    }
    return map;
  }
}
