import 'package:flutter/material.dart';
import '../models/car.dart';
import 'car_detail_page.dart';

class CarListPage extends StatelessWidget {
  final String brand;
  final List<Car> cars;
  final Map<String, double>? rates;
  final String preferredCurrency;

  const CarListPage({
    super.key,
    required this.brand,
    required this.cars,
    this.rates,
    required this.preferredCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(brand)),
      backgroundColor: const Color(0xFF1B171A),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: cars.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (_, i) {
            final c = cars[i];
            final priceText = _formatPrice(
              eur: c.priceEur,
              preferred: preferredCurrency,
              rates: rates,
            );

            return InkWell(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => CarDetailPage(
                            car: c,
                            rates: rates,
                            preferredCurrency: preferredCurrency,
                          ),
                    ),
                  ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF262027),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Immagine
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Image.asset(
                          c.images.isNotEmpty
                              ? c.images.first
                              : 'assets/supercar.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Titolo
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                      child: Text(
                        '${c.brand} ${c.model}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Prezzo nella valuta preferita
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        priceText,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade300,
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

  // ------ helpers ------

  String _formatPrice({
    required double eur,
    required String preferred,
    required Map<String, double>? rates,
  }) {
    double value = eur;
    String symbol = '€';

    if (preferred == 'USD' && (rates?['USD'] != null)) {
      value = eur * rates!['USD']!;
      symbol = r'$';
    } else if (preferred == 'GBP' && (rates?['GBP'] != null)) {
      value = eur * rates!['GBP']!;
      symbol = '£';
    } else if (preferred == 'EUR') {
      symbol = '€';
    }

    return '$symbol ${_kSep(value)}';
  }

  String _kSep(double v) {
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      b.write(s[i]);
      final group = idxFromEnd > 1 && (idxFromEnd - 1) % 3 == 0;
      if (group) b.write('.');
    }
    return b.toString();
  }
}
