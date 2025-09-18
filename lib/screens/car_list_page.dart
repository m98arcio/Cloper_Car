import 'package:concessionario_supercar/screens/car_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/car.dart';
import '../widgets/dark_live_background.dart';
import '../widgets/app_bottom_bar.dart';
import 'profile_page.dart';

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
  VideoPlayerController? _videoController;
  Future<void>? _videoInit;

  @override
  void initState() {
    super.initState();
    _loadBrandVideo(_videoForBrand(widget.brand));
  }

  @override
  void didUpdateWidget(covariant CarListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brand != widget.brand) {
      _loadBrandVideo(_videoForBrand(widget.brand));
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // Mappa brand -> video asset (aggiungi qui i tuoi file reali)
  String _videoForBrand(String brand) {
    final b = brand.toLowerCase().trim();
    if (b.contains('ferrari')) return 'assets/video/ferrari.mp4';
    if (b.contains('lamborghini')) return 'assets/video/Lamborghini.mp4';
    if (b.contains('bugatti')) return 'assets/video/Bugatti.mp4';
    if (b.contains('mclaren')) return 'assets/video/Mclaren.mp4';
    if (b.contains('porsche')) return 'assets/video/porsche.mp4';
    if (b.contains('aston')) return 'assets/video/Aston_Martin.mp4';
    if (b.contains('bentley')) return 'assets/video/Bentley.mp4';
    if (b.contains('rolls')) return 'assets/video/Rolls.mp4';
    if (b.contains('pagani')) return 'assets/video/Pagani.mp4';
    if (b.contains('koenigsegg')) return 'assets/video/Koenigsegg.mp4';
    if (b.contains('lotus')) return 'assets/video/Lotus.mp4';
    // fallback
    return 'assets/video/ferrari.mp4';
  }

  void _loadBrandVideo(String assetPath) {
    // Chiude il precedente controller (se c'è)
    _videoController?.dispose();

    // Prova a caricare il video del brand, se fallisse userà il fallback
    final controller = VideoPlayerController.asset(assetPath);
    setState(() {
      _videoController = controller;
      _videoInit = controller.initialize().then((_) {
        controller
          ..setLooping(true)
          ..setVolume(0)
          ..play();
        if (mounted) setState(() {});
      }).catchError((_) async {
        // Fallback sicuro
        final fb = VideoPlayerController.asset('assets/video/ferrari.mp4');
        _videoController = fb;
        _videoInit = fb.initialize().then((_) {
          fb
            ..setLooping(true)
            ..setVolume(0)
            ..play();
          if (mounted) setState(() {});
        });
      });
    });
  }

  Future<void> _openProfile() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          initialCurrency: widget.preferredCurrency,
          onChanged: (_) {},
          cars: widget.cars,
          rates: widget.rates,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brand;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          brand,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Stack(
        children: [
          const DarkLiveBackground(),
          Column(
            children: [
              // ---------- HERO VIDEO ----------
              Stack(
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: (_videoController != null)
                        ? FutureBuilder<void>(
                            future: _videoInit,
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.done &&
                                  _videoController!.value.isInitialized) {
                                return VideoPlayer(_videoController!);
                              }
                              return const Center(child: CircularProgressIndicator());
                            },
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  // overlay per leggere il testo
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Text(
                      'Scopri le auto di $brand',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

              // ---------- LISTA AUTO ----------
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: widget.cars.length,
                  itemBuilder: (context, index) {
                    final car = widget.cars[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CarDetailPage(
                              car: car,
                              rates: widget.rates,
                              preferredCurrency: widget.preferredCurrency,
                              cars: widget.cars, // per la bottom bar nel dettaglio
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(255, 163, 10, 10),
                              Color.fromARGB(255, 6, 19, 70),
                            ],
                          ),
                          border: Border.all(color: Colors.white24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(22),
                              ),
                              child: car.images.isNotEmpty
                                  ? Image.asset(
                                      car.images.first,
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 160,
                                      color: Colors.grey[800],
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.car_rental,
                                        size: 40,
                                        color: Colors.white54,
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '${car.brand} ${car.model}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      // Sei nella sezione Catalogo → indice 1
      bottomNavigationBar: AppBottomBar(
        currentIndex: 1,
        cars: widget.cars,
        rates: widget.rates,
        preferredCurrency: widget.preferredCurrency,
        onProfileTap: _openProfile,
      ),
    );
  }
}