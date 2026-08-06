import 'dart:convert';

/// Универсальный парсер прокси-ссылок и подписок (чистый Dart, без плагинов).
/// Жрёт: vless:// vmess:// trojan:// ss:// hysteria2:// hy2://
/// а также base64-подписки (пачка ссылок) и многострочные пачки.
/// На выходе - список [ParsedNode], из которого сервис собирает конфиг ядра.
class ParsedNode {
  final String name;
  final String protocol; // vless, vmess, trojan, ss, hysteria2
  final String host;
  final int port;
  final Map<String, dynamic> raw; // все поля/ query-параметры
  const ParsedNode({
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    required this.raw,
  });

  @override
  String toString() => '$protocol://$name ($host:$port)';
}

class ProxyParser {
  /// Главный вход: одна ссылка, base64-саб, или много ссылок через \n.
  static List<ParsedNode> parseAny(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const [];

    // 1) Пробуем как base64-подписку.
    final decoded = _tryBase64Subscription(trimmed);
    if (decoded != null) return _parseLines(decoded);

    // 2) Много строк.
    if (trimmed.contains('\n')) return _parseLines(trimmed);

    // 3) Одна ссылка.
    final single = _parseLink(trimmed);
    return single == null ? const [] : [single];
  }

  static List<ParsedNode> _parseLines(String text) {
    final out = <ParsedNode>[];
    for (final line in const LineSplitter().convert(text)) {
      final l = line.trim();
      if (l.isEmpty || l.startsWith('#')) continue;
      final n = _parseLink(l);
      if (n != null) out.add(n);
    }
    return out;
  }

  static String? _tryBase64Subscription(String s) {
    try {
      final padded = _pad(s.replaceAll(RegExp(r'\s+'), ''));
      final str = utf8.decode(base64Decode(padded), allowMalformed: true);
      if (RegExp(r'(vless|vmess|trojan|ss|ssr|hysteria2|hy2)://').hasMatch(str)) {
        return str;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static ParsedNode? _parseLink(String link) {
    try {
      if (link.startsWith('vless://')) return _parseVless(link);
      if (link.startsWith('vmess://')) return _parseVmess(link);
      if (link.startsWith('trojan://')) return _parseTrojan(link);
      if (link.startsWith('ss://')) return _parseShadowsocks(link);
      if (link.startsWith('hysteria2://') || link.startsWith('hy2://')) {
        return _parseHysteria2(link);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _name(Uri u) =>
      Uri.decodeComponent(u.fragment.isEmpty ? u.host : u.fragment);

  static ParsedNode _parseVless(String link) {
    final u = Uri.parse(link);
    return ParsedNode(
      name: _name(u), protocol: 'vless', host: u.host, port: u.port,
      raw: {'uuid': u.userInfo, ...u.queryParameters},
    );
  }

  static ParsedNode _parseTrojan(String link) {
    final u = Uri.parse(link);
    return ParsedNode(
      name: _name(u), protocol: 'trojan', host: u.host, port: u.port,
      raw: {'password': u.userInfo, ...u.queryParameters},
    );
  }

  static ParsedNode _parseHysteria2(String link) {
    final u = Uri.parse(link);
    return ParsedNode(
      name: _name(u), protocol: 'hysteria2', host: u.host, port: u.port,
      raw: {'password': u.userInfo, ...u.queryParameters},
    );
  }

  static ParsedNode _parseVmess(String link) {
    // vmess://base64(json)
    final b64 = link.substring('vmess://'.length).split('#').first;
    final j = jsonDecode(utf8.decode(base64Decode(_pad(b64)))) as Map<String, dynamic>;
    return ParsedNode(
      name: (j['ps'] ?? j['add'] ?? '').toString(),
      protocol: 'vmess',
      host: (j['add'] ?? '').toString(),
      port: int.tryParse((j['port'] ?? '443').toString()) ?? 443,
      raw: j,
    );
  }

  static ParsedNode _parseShadowsocks(String link) {
    // ss://base64(method:pass)@host:port#name  ИЛИ  ss://base64(method:pass@host:port)
    final body = link.substring('ss://'.length);
    final hashIdx = body.indexOf('#');
    final name = hashIdx >= 0 ? Uri.decodeComponent(body.substring(hashIdx + 1)) : '';
    final main = hashIdx >= 0 ? body.substring(0, hashIdx) : body;
    String method, password, host;
    int port;
    if (main.contains('@') && !RegExp(r'^[A-Za-z0-9+/=_]+$').hasMatch(main)) {
      final at = main.indexOf('@');
      final cred = utf8.decode(base64Decode(_pad(main.substring(0, at))));
      final colon = cred.indexOf(':');
      method = cred.substring(0, colon);
      password = cred.substring(colon + 1);
      final hp = main.substring(at + 1);
      host = hp.split(':').first;
      port = int.tryParse(hp.split(':').last) ?? 443;
    } else {
      final full = utf8.decode(base64Decode(_pad(main)));
      final at = full.lastIndexOf('@');
      final cred = full.substring(0, at);
      final colon = cred.indexOf(':');
      method = cred.substring(0, colon);
      password = cred.substring(colon + 1);
      final hp = full.substring(at + 1);
      host = hp.split(':').first;
      port = int.tryParse(hp.split(':').last) ?? 443;
    }
    return ParsedNode(
      name: name.isEmpty ? host : name, protocol: 'ss', host: host, port: port,
      raw: {'method': method, 'password': password},
    );
  }

  static String _pad(String s) {
    var p = s;
    while (p.length % 4 != 0) {
      p += '=';
    }
    return p;
  }
}
