class Car {
  final String id;
  final String brand;
  final String model;
  final double priceEur;
  final int powerHp;
  final List<String> images;

  // opzionali
  final String? zeroTo100;
  final String? topSpeed;
  final String? engine;
  final String? gearbox;
  final double? lengthCm;
  final double? widthCm;
  final double? wheelbaseCm;
  final String? description;
  final int? year;
  final bool incoming;
  /// Elenco ID dei dealer dove l’auto è disponibile
  final List<String> availableAt;

  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.priceEur,
    required this.powerHp,
    required this.images,
    this.zeroTo100,
    this.topSpeed,
    this.engine,
    this.gearbox,
    this.lengthCm,
    this.widthCm,
    this.wheelbaseCm,
    this.description,
    this.year,
    this.incoming = false,
    this.availableAt = const [],
  });

  // Costruzione dell' oggetto Car a partire da JSON
  factory Car.fromJson(Map<String, dynamic> j) => Car(
        id: j['id'] as String,
        brand: j['brand'] as String,
        model: j['model'] as String,
        priceEur: (j['priceEur'] as num).toDouble(),
        powerHp: (j['powerHp'] as num).toInt(),
        images: (j['images'] as List).cast<String>(),
        zeroTo100: j['zeroTo100'] as String?,
        topSpeed: j['topSpeed'] as String?,
        engine: j['engine'] as String?,
        gearbox: j['gearbox'] as String?,
        lengthCm: (j['lengthCm'] as num?)?.toDouble(),
        widthCm: (j['widthCm'] as num?)?.toDouble(),
        wheelbaseCm: (j['wheelbaseCm'] as num?)?.toDouble(),
        description: j['description'] as String?,
        year: (j['year'] as num?)?.toInt(),
        incoming: j['incoming'] as bool? ?? false,
        availableAt: ((j['availableDealerIds'] ?? j['availableAt']) as List?)
                ?.cast<String>() ??
            const [],
      );
}
