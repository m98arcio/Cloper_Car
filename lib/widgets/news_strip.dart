import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/news_service.dart';

class NewsStrip extends StatefulWidget {
  final List<NewsItem> items;      // elenco notizie da mostrare
  final VoidCallback? onRefresh;   // callback "riprova"
  final bool autoScroll;           // scorrimento automatico on/off
  const NewsStrip({
    super.key,
    required this.items,
    this.onRefresh,
    this.autoScroll = true,
  });

  @override
  State<NewsStrip> createState() => _NewsStripState();
}

class _NewsStripState extends State<NewsStrip> {
  final _pc = PageController(viewportFraction: 0.9); // card quasi a piena larghezza
  Timer? _timer;      // timer per auto-scroll
  int _index = 0;     // pagina corrente

  @override
  void initState() {
    super.initState();
    _setupTimer();    // avvia auto-scroll se serve
  }

  @override
  void didUpdateWidget(covariant NewsStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // se cambiano items o autoScroll, ri-configura il timer
    if (oldWidget.items != widget.items ||
        oldWidget.autoScroll != widget.autoScroll) {
      _disposeTimer();
      _setupTimer();
    }
  }

  void _setupTimer() {
    // attiva solo se richiesto e se ci sono almeno 2 card
    if (!widget.autoScroll || widget.items.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pc.hasClients) return;
      _index = (_index + 1) % widget.items.length;
      _pc.animateToPage(
        _index,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _disposeTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _disposeTimer();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // stato "vuoto"
    if (widget.items.isEmpty) {
      return _empty(onRefresh: widget.onRefresh);
    }

    // strip: pageview + pallini indicatore
    return SizedBox(
      height: 190,
      child: Column(
        children: [
          // cards
          Expanded(
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: widget.items.length,
              itemBuilder: (_, i) => _NewsCard(item: widget.items[i]),
            ),
          ),
          const SizedBox(height: 8),
          // indicatori pagina
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.items.length, (i) {
              final on = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: on ? 18 : 6,
                decoration: BoxDecoration(
                  color: on ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // box "nessuna notizia" con eventuale pulsante refresh
  Widget _empty({VoidCallback? onRefresh}) => Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.newspaper),
            const SizedBox(width: 10),
            const Expanded(child: Text('Nessuna notizia disponibile al momento.')),
            if (onRefresh != null)
              IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
          ],
        ),
      );
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    // data "dd MMM" se disponibile
    final date = item.pubDate != null
        ? DateFormat('dd MMM').format(item.pubDate!)
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        // apre la notizia nel browser esterno
        final uri = Uri.tryParse(item.link);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black38)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // immagine o placeholder
            if ((item.imageUrl ?? '').isNotEmpty)
              Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, evt) {
                  if (evt == null) return child;
                  return Container(color: Colors.black12);
                },
                errorBuilder: (_, __, ___) => Container(color: Colors.black12),
              )
            else
              Container(color: Colors.black12),

            // overlay sfumato per leggibilità
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.60),
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // testo (source+data in alto, titolo in basso)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // badge fonte
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.source,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (date != null)
                        Text(date, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                  const Spacer(),
                  // titolo
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.5,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}