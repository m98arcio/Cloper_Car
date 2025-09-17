// lib/screens/car_list_page.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/car.dart';

class CarListPage extends StatefulWidget {
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
  State<CarListPage> createState() => _CarListPageState();
}

class _CarListPageState extends State<CarListPage> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();

    // Usa un video locale: assets/ferrari.mp4
    _videoController = VideoPlayerController.asset('assets/ferrari.mp4')
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0); // muto
        _videoController.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brand;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          brand,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // -------- HERO VIDEO --------
          Stack(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: _videoController.value.isInitialized
                    ? VideoPlayer(_videoController)
                    : const Center(child: CircularProgressIndicator()),
              ),
              Container(
                height: 220,
                width: double.infinity,
                color: Colors.black.withOpacity(0.35),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: Text(
                  "Scopri le auto di $brand",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                  ),
                ),
              ),
            ],
          ),

          // -------- LISTA AUTO --------
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: widget.cars.length,
              itemBuilder: (context, index) {
                final car = widget.cars[index];
                return GestureDetector(
                  onTap: () {
                    // TODO: naviga ai dettagli dell'auto
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Immagine Auto
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: car.images.isNotEmpty
                              ? Image.asset(
                                  car.images.first,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 140,
                                  color: Colors.grey[300],
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.car_rental,
                                      size: 40, color: Colors.black54),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '${car.brand} ${car.model}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              // TODO: Azione dettaglio auto
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}