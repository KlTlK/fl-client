import 'dart:convert';
import 'dart:io';
import '../core/proxy_parser.dart';

class SubscriptionService {
  Future<List<ParsedNode>> fetch(String url) async {
    final client = HttpClient();
    client.badCertificateCallback = (_, __, ___) => true;
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(Uri.parse(url.trim()));
      req.headers.set('User-Agent', 'v2rayN/6.23');
      req.headers.set('Accept', '*/*');
      req.followRedirects = true;
      req.maxRedirects = 10;
      final resp = await req.close().timeout(const Duration(seconds: 20));
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode != 200) throw StateError('HTTP ${resp.statusCode}');
      final nodes = ProxyParser.parseAny(body);
      if (nodes.isEmpty) throw StateError('No supported links (${body.length} bytes)');
      return nodes;
    } finally {
      client.close(force: true);
    }
  }
  void dispose() {}
}
