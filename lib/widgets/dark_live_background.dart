import 'dart:math' as math;
import 'package:flutter/material.dart';

class DarkLiveBackground extends StatefulWidget {
  const DarkLiveBackground({super.key});

  @override
  State<DarkLiveBackground> createState() => _DarkLiveBackgroundState();
}

class _DarkLiveBackgroundState extends State<DarkLiveBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return CustomPaint(
          painter: _WavesPainter(time: _c.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WavesPainter extends CustomPainter {
  final double time; // 0..1
  _WavesPainter({required this.time});

  final _bg = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0A0A), Color(0xFF111114), Color(0xFF0A0A0B)],
    stops: [0.0, 0.6, 1.0],
  );

  @override
  void paint(Canvas canvas, Size size) {
    // base scura
    final rect = Offset.zero & size;
    final bgPaint = Paint()..shader = _bg.createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // parametri onda
    final baseAmp = size.height * 0.06;
    final speed = 2 * math.pi * time;

    // disegna 3 strati di onde con fasi/ampiezze diverse
    _drawWave(
      canvas,
      size,
      phase: speed,
      amp: baseAmp,
      color1: Colors.white.withValues(alpha: 0.08),
      color2: Colors.transparent,
      heightFactor: 0.55,
    );

    _drawWave(
      canvas,
      size,
      phase: speed + math.pi / 2,
      amp: baseAmp * 0.75,
      color1: Colors.white.withValues(alpha: 0.06),
      color2: Colors.transparent,
      heightFactor: 0.65,
    );

    _drawWave(
      canvas,
      size,
      phase: speed + math.pi,
      amp: baseAmp * 0.5,
      color1: Colors.white.withValues(alpha: 0.045),
      color2: Colors.transparent,
      heightFactor: 0.75,
    );

    // vignette leggera ai bordi
    final vignette = RadialGradient(
      center: const Alignment(0.1, -0.2),
      radius: 1.1,
      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.25)],
      stops: const [0.7, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = vignette.createShader(rect));
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double phase,
    required double amp,
    required Color color1,
    required Color color2,
    required double heightFactor,
  }) {
    final h = size.height * heightFactor;
    final w = size.width;

    final path = Path()..moveTo(0, h);
    final seg = 6;
    for (int i = 0; i <= seg; i++) {
      final x = w * i / seg;
      final t = (i / seg) * 2 * math.pi + phase;
      final y = h + math.sin(t) * amp;

      final cp1x = x - w / seg * 0.5;
      final cp2x = x - w / seg * 0.1;
      final cp1y = h + math.sin(t - 0.9) * amp * 0.9;
      final cp2y = h + math.sin(t - 0.2) * amp * 0.9;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, x, y);
    }
    path
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();

    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color1, color2],
    ).createShader(Offset.zero & size);

    final paint = Paint()..shader = shader;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) =>
      oldDelegate.time != time;
}
