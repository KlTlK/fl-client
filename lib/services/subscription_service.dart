import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import '../core/proxy_parser.dart';

class SubscriptionService {
  final _cookieJar = CookieJar();
  late final Dio _dio;

  SubscriptionService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      followRedirects: true,
      maxRedirects: 10,
      validateStatus: (status) => status != null && status < 500,
    ));
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  String _fixBase64Padding(String input) {
    input = input.trim();
    switch (input.length % 4) {
      case 2: return input + '==';
      case 3: return input + '=';
      default: return input;
    }
  }

  Future<List<ParsedNode>> fetch(String url) async {
    final response = await _dio.get(
      url.trim(),
      options: Options(
        headers: {
          'User-Agent': 'v2rayN/6.23',
          'Accept': '*/*',
        },
        responseType: ResponseType.plain,
      ),
    );

    if (response.statusCode != 200) {
      throw StateError('HTTP ${response.statusCode}');
    }

    var body = response.data.toString().trim();
    if (body.isEmpty) throw StateError('Empty response');

    // Try direct parse first
    var nodes = ProxyParser.parseAny(body);
    if (nodes.isNotEmpty) return nodes;

    // Try base64 decode with padding fix
    final padded = _fixBase64Padding(body);
    try {
      final decoded = utf8.decode(base64Decode(padded));
      nodes = ProxyParser.parseAny(decoded);
      if (nodes.isNotEmpty) return nodes;
    } catch (_) {}

    throw StateError('No supported links found (${body.length} bytes)');
  }

  void dispose() {
    _cookieJar.deleteAll();
  }
}
