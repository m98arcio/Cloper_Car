import 'package:flutter/material.dart';

/// Logo temporaneo:
/// - se [imagePath] è valorizzato, mostra quell'immagine
/// - altrimenti cerchio/quadrato con iniziale del brand su sfondo gradiente
class BrandLogo extends StatelessWidget {
  final String brand;
  final String? imagePath;
  final double size;
  final bool round;

  const BrandLogo({
    super.key,
    required this.brand,
    this.imagePath,
    this.size = 70,
    this.round = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      final w = round
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: Image.asset(imagePath!, width: size, height: size, fit: BoxFit.cover),
            )
          : Image.asset(imagePath!, width: size, height: size, fit: BoxFit.cover);
      return w;
    }

    // Placeholder generato
    final letter = brand.isNotEmpty ? brand.characters.first.toUpperCase() : '?';
    final colors = _brandColors(brand);
    final borderRadius = round ? BorderRadius.circular(size / 2) : BorderRadius.circular(12);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26, offset: Offset(0, 2))],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.45,
          shadows: const [Shadow(blurRadius: 6, color: Colors.black45)],
        ),
      ),
    );
  }

  /// Palette semplice per rendere i placeholder coerenti tra i brand.
  List<Color> _brandColors(String b) {
    switch (b.toLowerCase()) {
      case 'ferrari':
        return [const Color(0xFFD50000), const Color(0xFF7F0000)];
      case 'lamborghini':
        return [const Color(0xFFFFC107), const Color(0xFFFF8F00)];
      case 'mclaren':
        return [const Color(0xFFFF6F00), const Color(0xFFFF8A00)];
      case 'bugatti':
        return [const Color(0xFF1565C0), const Color(0xFF0D47A1)];
      default:
        return [const Color(0xFF7E57C2), const Color(0xFF5E35B1)];
    }
  }
}