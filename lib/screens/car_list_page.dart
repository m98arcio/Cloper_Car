import 'package:flutter/material.dart';
import '../models/car.dart';
import 'car_detail_page.dart';

class CarListPage extends StatelessWidget {
  final String brand;
  final List<Car> cars;
  final Map<String, double>? rates;
  const CarListPage({super.key, required this.brand, required this.cars, this.rates});

  @override
  Widget build(BuildContext context) {
    final usd = rates?['USD'], gbp = rates?['GBP'];

    return Scaffold(
      appBar: AppBar(title: Text(brand)),
      backgroundColor: const Color(0xFF1B171A),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: cars.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.88,
          ),
          itemBuilder: (_, i) {
            final c = cars[i];
            return InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CarDetailPage(car: c))),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFF262027), borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: AspectRatio(aspectRatio: 16/10, child: Image.asset(c.images.first, fit: BoxFit.cover)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                      child: Text('${c.brand} ${c.model}', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '€ ${c.priceEur.toStringAsFixed(0)}'
                        '${usd != null ? '  |  \$ ${(c.priceEur*usd).toStringAsFixed(0)}' : ''}'
                        '${gbp != null ? '  |  £ ${(c.priceEur*gbp).toStringAsFixed(0)}' : ''}',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade300),
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
}