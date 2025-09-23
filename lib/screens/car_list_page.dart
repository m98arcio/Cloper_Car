import 'dart:ui' show ImageFilter;
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
  final List<Car>? allCars;

  const CarListPage({
    super.key,
    required this.brand,
    required this.cars,
    this.rates,
    required this.preferredCurrency,
    this.allCars,
  });

  @override
  State<CarListPage> createState() => _CarListPageState();
}

class _CarListPageState extends State<CarListPage> {
  VideoPlayerController? _videoController;
  Future<void>? _videoInit;
  final PageController _pageController = PageController(viewportFraction: 0.6);

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
    _pageController.dispose();
    super.dispose();
  }

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
    return 'assets/video/ferrari.mp4';
  }

  void _loadBrandVideo(String assetPath) {
    _videoController?.dispose();
    final controller = VideoPlayerController.asset(assetPath);
    setState(() {
      _videoController = controller;
      _videoInit = controller
          .initialize()
          .then((_) {
            controller
              ..setLooping(true)
              ..setVolume(0)
              ..play();
            if (mounted) setState(() {});
          })
          .catchError((_) async {
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
          cars: widget.allCars ?? widget.cars,
          rates: widget.rates,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brand;

    final availableCars = widget.cars.where((c) => !c.incoming).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 72,
        title: _GradientText(
          brand,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            color: Colors.white,
          ),
          colors: const [Colors.orangeAccent, Colors.deepOrange],
        ),
      ),
      body: Stack(
        children: [
          const DarkLiveBackground(),
          Column(
            children: [
              /* ================== HERO VIDEO ================== */
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

              /* ============== LISTA VERTICALE ANIMATA ============== */
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: availableCars.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final car = availableCars[index];

                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 0.0;
                        if (_pageController.hasClients) {
                          value = ((_pageController.page ?? _pageController.initialPage) - index).toDouble();
                        }
                        final scale = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                        final verticalOffset = (value * 40).clamp(-40.0, 40.0);

                        return Transform.translate(
                          offset: Offset(0, verticalOffset),
                          child: Transform.scale(
                            scale: scale,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: _CarCard(
                        car: car,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CarDetailPage(
                                car: car,
                                rates: widget.rates,
                                preferredCurrency: widget.preferredCurrency,
                                cars: availableCars,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: 1,
        cars: availableCars,
        allCars: widget.allCars ?? widget.cars,
        rates: widget.rates,
        preferredCurrency: widget.preferredCurrency,
        onProfileTap: _openProfile,
      ),
    );
  }
}

class _CarCard extends StatefulWidget {
  final Car car;
  final VoidCallback onTap;

  const _CarCard({required this.car, required this.onTap});

  @override
  State<_CarCard> createState() => _CarCardState();
}

class _CarCardState extends State<_CarCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) => setState(() => _scale = 0.95);
  void _onTapUp(TapUpDetails details) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  void _onLongPress() {
    setState(() => _scale = 0.9);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _scale = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.car.images.isNotEmpty ? widget.car.images.first : 'assets/macchine/supercar.jpg';

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onLongPress: _onLongPress,
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // IMMAGINE
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Image.asset(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 40, color: Colors.white54),
                      ),
                    ),
                  ),

                  // SCRIM in basso
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // PILL CON NOME
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 25,
                    child: _Frosted(
                      borderRadius: 14,
                      blur: 12,
                      opacity: 0.18,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Text(
                          widget.car.model,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- frosted glass helper ---------- */
class _Frosted extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;

  const _Frosted({
    required this.child,
    this.borderRadius = 12,
    this.blur = 10,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(opacity),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}

/* ---------- GradientText per AppBar ---------- */
class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<Color> colors;

  const _GradientText(this.text, {required this.style, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight)
              .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style),
    );
  }
}