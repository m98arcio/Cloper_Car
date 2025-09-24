import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

class NewsItem {
  final String title;
  final String link;
  final DateTime? pubDate;
  final String? imageUrl;
  final String source;

  NewsItem({
    required this.title,
    required this.link,
    required this.source,
    this.pubDate,
    this.imageUrl,
  });
}

class NewsService {
  static const Map<String, String> _feeds = {
    'Motor1':     'https://www.motor1.com/rss/news/',
    'Autoblog':   'https://www.autoblog.com/rss.xml',
    'TopGear':    'https://www.topgear.com/feeds/news',
    'AutoExpress':'https://www.autoexpress.co.uk/rss',
    'CarScoops':  'https://www.carscoops.com/feed/',
    'Autocar':    'https://www.autocar.co.uk/rss',
  };

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Android 14; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
    'Accept': 'application/rss+xml, application/xml;q=0.9, */*;q=0.8',
  };

  Future<List<NewsItem>> fetchLatest({
    int maxPerFeed = 8,
    int totalMax = 18,
  }) async {
    final out = <NewsItem>[];

    for (final entry in _feeds.entries) {
      final source = entry.key;
      final url = entry.value;

      try {
        final res = await http
            .get(Uri.parse(url), headers: _headers)
            .timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) continue;

        final body = utf8.decode(res.bodyBytes);

        try {
          final rss = RssFeed.parse(body);
          for (final item in (rss.items ?? const <RssItem>[]).take(maxPerFeed)) {
            out.add(_fromRss(item, source));
          }
          continue;
        } catch (_) {}

        try {
          final atom = AtomFeed.parse(body);
          for (final item in (atom.items ?? const <AtomItem>[]).take(maxPerFeed)) {
            out.add(_fromAtom(item, source));
          }
        } catch (_) {}
      } catch (_) {
      }
    }

    out.sort((a, b) {
      final ad = a.pubDate?.millisecondsSinceEpoch ?? 0;
      final bd = b.pubDate?.millisecondsSinceEpoch ?? 0;
      return bd.compareTo(ad);
    });
    if (out.length > totalMax) out.removeRange(totalMax, out.length);
    return out;
  }

  NewsItem _fromRss(RssItem i, String source) {
    String? img;
    if (i.media?.thumbnails?.isNotEmpty == true) {
      img = i.media!.thumbnails!.first.url;
    } else if (i.media?.contents?.isNotEmpty == true) {
      img = i.media!.contents!.first.url;
    } else if (i.enclosure?.url != null) {
      img = i.enclosure!.url;
    } else if ((i.description ?? '').contains('img')) {
      final m = RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false)
          .firstMatch(i.description!);
      if (m != null) img = m.group(1);
    }

    return NewsItem(
      title: (i.title ?? '').trim().isEmpty ? '(senza titolo)' : i.title!.trim(),
      link: (i.link ?? '').trim(),
      pubDate: i.pubDate,
      imageUrl: img,
      source: source,
    );
  }

  NewsItem _fromAtom(AtomItem i, String source) {
    final linkHref = (i.links != null && i.links!.isNotEmpty)
        ? (i.links!.first.href ?? '')
        : '';

    String? img;
    if (i.media?.thumbnails?.isNotEmpty == true) {
      img = i.media!.thumbnails!.first.url;
    } else if (i.media?.contents?.isNotEmpty == true) {
      img = i.media!.contents!.first.url;
    }

    return NewsItem(
      title: (i.title ?? '').trim().isEmpty ? '(senza titolo)' : i.title!.trim(),
      link: linkHref,
      pubDate: i.updated,
      imageUrl: img,
      source: source,
    );
  }
}