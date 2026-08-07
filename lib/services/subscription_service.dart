import 'package:http/http.dart' as http;
import '../core/proxy_parser.dart';

class SubscriptionService {
  Future<List<ParsedNode>> fetch(String url) async {
    final client = http.Client();
    try {
      var currentUrl = url.trim();
      for (var i = 0; i < 5; i++) {
        final req = http.Request('GET', Uri.parse(currentUrl));
        req.headers['User-Agent'] = 'clash-verge/v1.5.0';
        req.followRedirects = false;
        final resp = await http.Response.fromStream(
          await client.send(req).timeout(const Duration(seconds: 15)),
        );
        if (resp.statusCode == 200) return ProxyParser.parseAny(resp.body);
        if (resp.statusCode >= 300 && resp.statusCode < 400) {
          final loc = resp.headers['location'];
          if (loc == null || loc.isEmpty) throw StateError('Redirect without Location');
          currentUrl = Uri.parse(currentUrl).resolve(loc).toString();
          continue;
        }
        throw StateError('HTTP ${resp.statusCode}');
      }
      throw StateError('Too many redirects');
    } finally {
      client.close();
    }
  }
  void dispose() {}
}
