import 'package:http/http.dart' as http;
import '../core/proxy_parser.dart';

class SubscriptionService {
  Future<List<ParsedNode>> fetch(String url) async {
    final client = http.Client();
    try {
      final resp = await client.get(
        Uri.parse(url.trim()),
        headers: {'User-Agent': 'fl-client/0.8'},
      ).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        throw StateError('subscription HTTP ${resp.statusCode}');
      }
      return ProxyParser.parseAny(resp.body);
    } finally {
      client.close();
    }
  }

  void dispose() {}
}
