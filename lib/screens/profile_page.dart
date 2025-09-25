import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/car.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/dark_live_background.dart';
import '../services/currency_service.dart';

class ProfilePage extends StatefulWidget {
  final String initialCurrency; // valuta iniziale
  final ValueChanged<String> onChanged; // callback cambio valuta
  final List<Car> cars; // lista completa auto (per bottom bar)
  final Map<String, double>? rates; // cambi (se disponibili)

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
  late String _currency; // valuta selezionata

  @override
  void initState() {
    super.initState();
    // usa preferenza salvata, altrimenti quella passata
    _currency = CurrencyService.preferred.isNotEmpty
        ? CurrencyService.preferred
        : widget.initialCurrency;
  }

  // salva e notifica nuova valuta
  Future<void> _set(String code) async {
    setState(() => _currency = code);
    await CurrencyService.save(code);
    widget.onChanged(code);
  }

  // profilo già aperto (placeholder)
  Future<void> _openProfile() async {
    // niente: siamo già qui
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = CurrencyService.labelFor(_currency); // label leggibile

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const _ProfileAppBar(), // appbar con gradiente
      body: Stack(
        children: [
          const DarkLiveBackground(), // sfondo animato
          SafeArea(
            top: false,
            child: ListView(
              children: [
                const SizedBox(height: 8),
                // sezione impostazioni
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Impostazioni',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                // tile intestazione valuta
                _tile(
                  title: 'Valuta preferita',
                  subtitle: subtitle,
                  icon: Icons.currency_exchange,
                ),
                const Divider(height: 1, color: Colors.white12),

                // elenco scelte valuta 
                for (final c in CurrencyService.currencies) ...[
                  ListTile(
                    leading: Icon(
                      _currency == c['code']!
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
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
                    onTap: () => _set(c['code']!), // cambia valuta
                  ),
                  const Divider(height: 1, color: Colors.white12),
                ],

                // pulsante uscita app (Android/iOS)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
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
                        SystemNavigator.pop(); // chiude app su Android
                      } else if (Platform.isIOS) {
                        exit(0); // forza uscita su iOS (non consigliato in prod)
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
      // bottom bar: indice profilo, passa lista auto e valute
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

  //helper UI per una riga titolo/sottotitolo con icona
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

  // estrae nome valuta dalla label (es. "Euro (€)" -> "Euro")
  String _nameFromLabel(String label) {
    final idx = label.indexOf('(');
    return (idx > 0) ? label.substring(0, idx).trim() : label;
  }

  // estrae simbolo dalla label (es. "Euro (€)" -> "€")
  String _symbolFromLabel(String label) {
    final start = label.indexOf('(');
    final end = label.indexOf(')');
    if (start != -1 && end != -1 && end > start) {
      return label.substring(start + 1, end).trim();
    }
    return '';
  }
}

//AppBar con titolo a gradiente
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

//Testo con gradiente
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