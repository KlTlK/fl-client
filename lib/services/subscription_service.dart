import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/proxy_parser.dart';

class SubscriptionService {
  /// Качает саб по URL. Отключает auto-redirect чтоб не ловить redirect loop.
  Future<List<ParsedNode>> fetch(String url) async {
    final uri = Uri.parse(url.trim());
    final client = http.Client();
    try {
      final req = http.Request('GET', uri);
      req.headers['User-Agent'] = 'fl-client/0.8';
      req.followRedirects = false;
      final streamed = await client.send(req).timeout(const Duration(seconds: 20));

      // Если редирект - берём Location и идём туда (один раз)
      var resp = await http.Response.fromStream(streamed);
      if (resp.statusCode >= 300 && resp.statusCode < 400) {
        final loc = resp.headers['location'];
        if (loc != null) {
          final req2 = http.Request('GET', Uri.parse(loc));
          req2.headers['User-Agent'] = 'fl-client/0.8';
          req2.followRedirects = false;
          final s2 = await client.send(req2).timeout(const Duration(seconds: 20));
          resp = await http.Response.fromStream(s2);
        }
      }

      if (resp.statusCode != 200) {
        throw StateError('subscription HTTP ${resp.statusCode}');
      }
      return ProxyParser.parseAny(resp.body);
    } finally {
      client.close();
    }
  }
}
