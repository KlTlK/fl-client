import 'dart:convert';
import 'dart:io';
import '../core/proxy_parser.dart';

class SubscriptionService {
  Future<List<ParsedNode>> fetch(String url) async {
    final client = HttpClient();
    client.badCertificateCallback = (_, __, ___) => true;
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      var currentUrl = url.trim();
      for (var i = 0; i < 5; i++) {
        final req = await client.getUrl(Uri.parse(currentUrl));
        req.headers.set('User-Agent', 'v2rayN/6.23');
        req.headers.set('Accept', '*/*');
        req.headers.set('Accept-Encoding', 'identity');
        req.followRedirects = false;
        final resp = await req.close().timeout(const Duration(seconds: 15));
        if (resp.statusCode == 200) {
          final body = await resp.transform(utf8.decoder).join();
          final nodes = ProxyParser.parseAny(body);
          if (nodes.isEmpty) throw StateError('No supported links (${body.length} bytes)');
          return nodes;
        }
        if (resp.statusCode >= 300 && resp.statusCode < 400) {
          final loc = resp.headers.value('location');
          if (loc == null || loc.isEmpty) throw StateError('Redirect without Location');
          // Resolve relative redirects
          currentUrl = Uri.parse(currentUrl).resolve(loc).toString();
          // Drain response to free connection
          await resp.drain();
          continue;
        }
        throw StateError('HTTP ${resp.statusCode}');
      }
      throw StateError('Too many redirects');
    } finally {
      client.close(force: true);
    }
  }
  void dispose() {}
}
