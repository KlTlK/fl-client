import 'package:http/http.dart' as http;
import '../core/proxy_parser.dart';

class SubscriptionService {
  Future<List<ParsedNode>> fetch(String url) async {
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url.trim()));
      req.headers['User-Agent'] = 'fl-client/0.8';
      req.followRedirects = false;
      var resp = await http.Response.fromStream(
        await client.send(req).timeout(const Duration(seconds: 20)),
      );
      if (resp.statusCode >= 300 && resp.statusCode < 400) {
        final loc = resp.headers['location'];
        if (loc != null && loc.isNotEmpty) {
          final req2 = http.Request('GET', Uri.resolve(url.trim(), loc));
          req2.headers['User-Agent'] = 'fl-client/0.8';
          req2.followRedirects = false;
          resp = await http.Response.fromStream(
            await client.send(req2).timeout(const Duration(seconds: 20)),
          );
        }
      }
      if (resp.statusCode != 200) throw StateError('HTTP ${resp.statusCode}');
      return ProxyParser.parseAny(resp.body);
    } finally {
      client.close();
    }
  }
  void dispose() {}
}
