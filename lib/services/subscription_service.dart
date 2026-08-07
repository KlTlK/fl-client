import 'package:http/http.dart' as http;
import '../core/proxy_parser.dart';

class SubscriptionService {
  Future<List<ParsedNode>> fetch(String url) async {
    final client = http.Client();
    try {
      final resp = await client.get(
        Uri.parse(url.trim()),
        headers: {
          'User-Agent': 'v2rayN/6.23',
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
        },
      ).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) throw StateError('HTTP ${resp.statusCode}');
      final nodes = ProxyParser.parseAny(resp.body);
      if (nodes.isEmpty) throw StateError('No supported links in response (${resp.body.length} bytes)');
      return nodes;
    } finally {
      client.close();
    }
  }
  void dispose() {}
}
