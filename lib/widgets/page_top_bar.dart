import 'package:flutter/material.dart';

// Barra superiore riutilizzabile con titolo, sottotitolo opzionale e icona.
// Usata per intestare le varie pagine con uno stile coerente.
class PageTopBar extends StatelessWidget {
  final String title;      // titolo principale
  final String? subtitle;  // sottotitolo opzionale
  final IconData? icon;    // icona opzionale a sinistra del titolo

  const PageTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Titolo con gradiente (e icona se presente)
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.redAccent, Colors.orangeAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 30, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Sottotitolo (se fornito)
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}