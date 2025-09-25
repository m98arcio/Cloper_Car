import 'dart:math' as math;
import 'package:flutter/material.dart';

// Sfondo scuro animato con onde in movimento.
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
    // loop
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
    // Ridisegna continuamente il canvas in base al valore dell’animazione
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

//Painter che disegna lo sfondo scuro con onde e vignetta
class _WavesPainter extends CustomPainter {
  final double time;
  _WavesPainter({required this.time});

  //Gradiente di base dello sfondo
  final _bg = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0A0A), Color(0xFF111114), Color(0xFF0A0A0B)],
    stops: [0.0, 0.6, 1.0],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    //Disegna sfondo scuro
    canvas.drawRect(rect, Paint()..shader = _bg.createShader(rect));

    // Parametri base delle onde
    final baseAmp = size.height * 0.06; // ampiezza
    final speed = 2 * math.pi * time;   // fase animazione

    //Tre strati di onde sovrapposte (più realistiche)
    _drawWave(canvas, size,
        phase: speed,
        amp: baseAmp,
        color1: Colors.white.withValues(alpha: 0.08),
        color2: Colors.transparent,
        heightFactor: 0.55);

    _drawWave(canvas, size,
        phase: speed + math.pi / 2,
        amp: baseAmp * 0.75,
        color1: Colors.white.withValues(alpha: 0.06),
        color2: Colors.transparent,
        heightFactor: 0.65);

    _drawWave(canvas, size,
        phase: speed + math.pi,
        amp: baseAmp * 0.5,
        color1: Colors.white.withValues(alpha: 0.045),
        color2: Colors.transparent,
        heightFactor: 0.75);

    // Vignetta scura sui bordi (per dare profondità)
    final vignette = RadialGradient(
      center: const Alignment(0.1, -0.2),
      radius: 1.1,
      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.25)],
      stops: const [0.7, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = vignette.createShader(rect));
  }

  // Disegna un'onda con curva sinusoidale e gradiente verticale
  void _drawWave(
    Canvas canvas,
    Size size, {
    required double phase,
    required double amp,
    required Color color1,
    required Color color2,
    required double heightFactor,
  }) {
    final h = size.height * heightFactor; // altezza di partenza
    final w = size.width;

    final path = Path()..moveTo(0, h);
    const seg = 6; // numero segmenti (più alto → curva più precisa)

    for (int i = 0; i <= seg; i++) {
      final x = w * i / seg;
      final t = (i / seg) * 2 * math.pi + phase;
      final y = h + math.sin(t) * amp;

      // punti di controllo per la curva cubica (onda morbida)
      final cp1x = x - w / seg * 0.5;
      final cp2x = x - w / seg * 0.1;
      final cp1y = h + math.sin(t - 0.9) * amp * 0.9;
      final cp2y = h + math.sin(t - 0.2) * amp * 0.9;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, x, y);
    }

    // chiude il path fino in fondo allo schermo
    path
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();

    // gradiente verticale che sfuma verso il basso
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color1, color2],
    ).createShader(Offset.zero & size);

    canvas.drawPath(path, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) =>
      oldDelegate.time != time;
}