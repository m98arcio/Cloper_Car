class Car {
  final String id;
  final String brand;
  final String model;
  final double priceEur;
  final int powerHp;
  final List<String> images;

  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.priceEur,
    required this.powerHp,
    required this.images,
  });

  factory Car.fromJson(Map<String, dynamic> j) => Car(
    id: j['id'],
    brand: j['brand'],
    model: j['model'],
    priceEur: (j['priceEur'] as num).toDouble(),
    powerHp: j['powerHp'],
    images: (j['images'] as List).cast<String>(),
  );
}
