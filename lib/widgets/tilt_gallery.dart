import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class TiltGallery extends StatefulWidget {
  final List<String> images;
  const TiltGallery({super.key, required this.images});

  @override
  State<TiltGallery> createState() => _TiltGalleryState();
}

class _TiltGalleryState extends State<TiltGallery> {
  late final PageController _controller;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _sub = accelerometerEvents.listen((e) {
      if (e.x > 6) _next();
      if (e.x < -6) _prev();
    });
  }

  void _next() {
    final next = (_controller.page ?? 0).round() + 1;
    if (next < widget.images.length) {
      _controller.animateToPage(next, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  void _prev() {
    final prev = (_controller.page ?? 0).round() - 1;
    if (prev >= 0) {
      _controller.animateToPage(prev, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16/9,
      child: PageView(
        controller: _controller,
        children: widget.images.map((p) => Image.asset(p, fit: BoxFit.cover)).toList(),
      ),
    );
  }
}
