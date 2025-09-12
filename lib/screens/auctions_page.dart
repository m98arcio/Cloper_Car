import 'dart:async';
import 'package:flutter/material.dart';

class AuctionsPage extends StatefulWidget {
  const AuctionsPage({super.key});

  @override
  State<AuctionsPage> createState() => _AuctionsPageState();
}

class _AuctionsPageState extends State<AuctionsPage> {
  late final List<_Auction> _auctions;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Demo dataset – sostituisci quando colleghi una vera API
    _auctions = [
      _Auction(
        title: 'Ferrari 488 Pista',
        image: 'assets/ferrari_offer.jpg',
        currentBid: 285000,
        minIncrement: 5000,
        endsAt: DateTime.now().add(const Duration(minutes: 15)),
      ),
      _Auction(
        title: 'McLaren 720S',
        image: 'assets/mclaren.jpg',
        currentBid: 205000,
        minIncrement: 3000,
        endsAt: DateTime.now().add(const Duration(minutes: 42)),
      ),
      _Auction(
        title: 'Lamborghini Aventador',
        image: 'assets/lamborghini.jpg',
        currentBid: 390000,
        minIncrement: 7000,
        endsAt: DateTime.now().add(const Duration(hours: 2, minutes: 5)),
      ),
    ];

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {}); // aggiorna i countdown
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B171A),
      appBar: AppBar(
        title: const Text('Aste'),
        backgroundColor: const Color(0xFF1B171A),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _auctions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _AuctionCard(
          auction: _auctions[i],
          onBid: (value) {
            setState(() {
              _auctions[i] = _auctions[i].copyWith(currentBid: value);
            });
          },
        ),
      ),
    );
  }
}

class _AuctionCard extends StatelessWidget {
  final _Auction auction;
  final ValueChanged<int> onBid;
  const _AuctionCard({required this.auction, required this.onBid});

  @override
  Widget build(BuildContext context) {
    final remaining = auction.endsAt.difference(DateTime.now());
    final ended = remaining.isNegative;
    String timerText;
    if (ended) {
      timerText = 'Terminata';
    } else {
      final h = remaining.inHours;
      final m = remaining.inMinutes % 60;
      final s = remaining.inSeconds % 60;
      timerText = '${h.toString().padLeft(2, '0')}:'
                  '${m.toString().padLeft(2, '0')}:'
                  '${s.toString().padLeft(2, '0')}';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262027),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // immagine
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 16/9,
              child: Image.asset(auction.image, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    auction.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.gavel, size: 18),
                const SizedBox(width: 6),
                Text(timerText, style: TextStyle(
                  color: ended ? Colors.redAccent : Colors.white70,
                  fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Text('Offerta attuale: € ${auction.currentBid}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: ended ? null : () async {
                    final next = auction.currentBid + auction.minIncrement;
                    onBid(next);
                    // snackbar di conferma
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Offerta inviata: € $next'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text('Fai offerta +€${auction.minIncrement}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Auction {
  final String title;
  final String image;
  final int currentBid;
  final int minIncrement;
  final DateTime endsAt;

  _Auction({
    required this.title,
    required this.image,
    required this.currentBid,
    required this.minIncrement,
    required this.endsAt,
  });

  _Auction copyWith({int? currentBid}) => _Auction(
        title: title,
        image: image,
        currentBid: currentBid ?? this.currentBid,
        minIncrement: minIncrement,
        endsAt: endsAt,
      );
}