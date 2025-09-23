import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/car.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/dark_live_background.dart';
import '../services/currency_service.dart';

class ProfilePage extends StatefulWidget {
  final String initialCurrency; // 'EUR' | 'USD' | 'GBP'
  final ValueChanged<String> onChanged;
  final List<Car> cars; // lista completa di auto
  final Map<String, double>? rates;

  const ProfilePage({
    super.key,
    required this.initialCurrency,
    required this.onChanged,
    required this.cars,
    this.rates,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _currency;

  @override
  void initState() {
    super.initState();
    _currency = CurrencyService.preferred.isNotEmpty
        ? CurrencyService.preferred
        : widget.initialCurrency;
  }

  Future<void> _set(String code) async {
    setState(() => _currency = code);
    await CurrencyService.save(code);
    widget.onChanged(code);
  }

  Future<void> _openProfile() async {
    // già nella pagina profilo
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = CurrencyService.labelFor(_currency);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const _ProfileAppBar(),
      body: Stack(
        children: [
          const DarkLiveBackground(),
          SafeArea(
            top: false,
            child: ListView(
              children: [
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Impostazioni',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                _tile(
                  title: 'Valuta preferita',
                  subtitle: subtitle,
                  icon: Icons.currency_exchange,
                ),
                const Divider(height: 1, color: Colors.white12),

                for (final c in CurrencyService.currencies)
                  RadioListTile<String>(
                    value: c['code']!,
                    groupValue: _currency,
                    onChanged: (v) => _set(v!),
                    title: Row(
                      children: [
                        Text(
                          _symbolFromLabel(c['label']!),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(_nameFromLabel(c['label']!)),
                      ],
                    ),
                  ),

                // ------------------- PULSANTE ESCI -------------------
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () {
                      if (Platform.isAndroid) {
                        SystemNavigator.pop();
                      } else if (Platform.isIOS) {
                        exit(0);
                      }
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.orangeAccent, Colors.deepOrange],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        height: 50,
                        child: const Text(
                          'Esci dall\'app',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: 3,
        cars: widget.cars,
        allCars: widget.cars,
        rates: widget.rates,
        preferredCurrency: CurrencyService.preferred,
        onProfileTap: _openProfile,
      ),
    );
  }

  // ----- helpers UI -----
  Widget _tile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    );
  }

  String _nameFromLabel(String label) {
    final idx = label.indexOf('(');
    return (idx > 0) ? label.substring(0, idx).trim() : label;
  }

  String _symbolFromLabel(String label) {
    final start = label.indexOf('(');
    final end = label.indexOf(')');
    if (start != -1 && end != -1 && end > start) {
      return label.substring(start + 1, end).trim();
    }
    return '';
  }
}

/* ---------------- AppBar con titolo a gradiente ---------------- */
class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0E0E0F),
      elevation: 0,
      centerTitle: true,
      toolbarHeight: preferredSize.height,
      title: const _GradientText(
        'Profilo',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
          color: Colors.white,
        ),
        colors: [Colors.orangeAccent, Colors.deepOrange],
      ),
    );
  }
}

/* ---------------- GradientText riutilizzabile (privato) ---------------- */
class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<Color> colors;

  const _GradientText(this.text, {required this.style, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style),
    );
  }
}
