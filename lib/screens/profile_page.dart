import 'package:flutter/material.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/dark_live_background.dart';
import '../models/car.dart';

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
    _currency = widget.initialCurrency;
  }

  void _set(String c) {
    setState(() => _currency = c);
    widget.onChanged(c);
    Navigator.pop(context, true); // segnala il cambiamento
  }

  Future<void> _openProfile() async {
    // già siamo nella pagina profilo
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // AppBar nera fissa con titolo grande a gradiente (niente sottotitolo)
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
                  subtitle: _currencyLabel(_currency),
                  icon: Icons.currency_exchange,
                ),
                const Divider(height: 1, color: Colors.white12),
                RadioListTile<String>(
                  value: 'EUR',
                  groupValue: _currency,
                  onChanged: (v) => _set(v!),
                  title: const Text('Euro (€)'),
                ),
                RadioListTile<String>(
                  value: 'USD',
                  groupValue: _currency,
                  onChanged: (v) => _set(v!),
                  title: const Text('Dollaro USA (\$)'),
                ),
                RadioListTile<String>(
                  value: 'GBP',
                  groupValue: _currency,
                  onChanged: (v) => _set(v!),
                  title: const Text('Sterlina (£)'),
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
        preferredCurrency: _currency,
        onProfileTap: _openProfile,
      ),
    );
  }

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

  String _currencyLabel(String c) {
    switch (c) {
      case 'USD':
        return 'Dollaro USA';
      case 'GBP':
        return 'Sterlina';
      case 'EUR':
      default:
        return 'Euro';
    }
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
          color: Colors.white, // sostituito dallo shader
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
      shaderCallback:
          (bounds) => LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style),
    );
  }
}
