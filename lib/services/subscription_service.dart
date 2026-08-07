import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/proxy_parser.dart';

/// Ходит за подпиской по HTTPS, поддерживает base64-сабы и пачки ссылок.
class SubscriptionService {
  final http.Client _client = http.Client();

  /// Качает саб по URL и парсит. many провайдеров отдают base64 - парсер сам разберёт.
  Future<List<ParsedNode>> fetch(String url) async {
    final uri = Uri.parse(url.trim());
    final resp = await _client.get(uri, headers: {
      'User-Agent': 'fl-client/0.5',
      'Accept': '*/*',
    }).timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) {
      throw StateError('subscription HTTP ${resp.statusCode}');
    }
    // Некоторые сабы приходят base64 без переносов, некоторые - plain text.
    // ProxyParser.parseAny сам отличит base64 от plain.
    return ProxyParser.parseAny(resp.body);
  }

  void dispose() => _client.close();
}
