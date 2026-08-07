import 'dart:convert';

class ParsedNode {
  final String name;
  final String protocol;
  final String host;
  final int port;
  final Map<String, dynamic> raw;
  const ParsedNode({
    required this.name, required this.protocol,
    required this.host, required this.port, required this.raw,
  });
  @override
  String toString() => '$protocol://$name ($host:$port)';
}

class ProxyParser {
  static List<ParsedNode> parseAny(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return [];

    // 1. Try direct share links first
    final direct = _parseShareLines(trimmed);
    if (direct.isNotEmpty) return direct;

    // 2. Try base64 decode then parse lines
    final decoded = _decodeBase64(trimmed);
    if (decoded != null && decoded.trim() != trimmed) {
      final decodedLinks = _parseShareLines(decoded);
      if (decodedLinks.isNotEmpty) return decodedLinks;
    }

    // 3. Try as single link
    final single = _parseLink(trimmed);
    if (single != null) return [single];

    // 4. Try decoded as single link
    if (decoded != null) {
      final s = _parseLink(decoded.trim());
      if (s != null) return [s];
    }

    return [];
  }

  static List<ParsedNode> _parseShareLines(String input) {
    final out = <ParsedNode>[];
    for (final line in input.split(RegExp(r'[\r\n]+'))) {
      final l = line.trim();
      if (l.isEmpty || l.startsWith('#')) continue;
      if (!_hasScheme(l)) continue;
      final n = _parseLink(l);
      if (n != null) out.add(n);
    }
    return out;
  }

  static bool _hasScheme(String v) {
    final s = v.split('://').first.toLowerCase();
    return {'vmess','vless','trojan','ss','socks','hysteria2','hy2'}.contains(s);
  }

  /// Base64 decode как в flutter_vless: normalize URL-safe chars + padding
  static String? _decodeBase64(String input) {
    var normalized = input.replaceAll(RegExp(r'\s+'), '');
    normalized = normalized.replaceAll('-', '+').replaceAll('_', '/');
    if (normalized.length % 4 > 0) {
      normalized += '=' * (4 - normalized.length % 4);
    }
    try {
      return utf8.decode(base64Decode(normalized));
    } catch (_) {
      return null;
    }
  }

  static ParsedNode? _parseLink(String link) {
    try {
      if (link.startsWith('vless://')) return _parseVless(link);
      if (link.startsWith('vmess://')) return _parseVmess(link);
      if (link.startsWith('trojan://')) return _parseTrojan(link);
      if (link.startsWith('ss://')) return _parseSS(link);
      if (link.startsWith('hysteria2://') || link.startsWith('hy2://')) return _parseHy2(link);
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _frag(Uri u) => Uri.decodeComponent(u.fragment.isEmpty ? u.host : u.fragment);

  static ParsedNode _parseVless(String link) {
    final u = Uri.parse(link);
    return ParsedNode(name: _frag(u), protocol: 'vless', host: u.host, port: u.port,
        raw: {'uuid': u.userInfo, ...u.queryParameters});
  }

  static ParsedNode _parseTrojan(String link) {
    final u = Uri.parse(link);
    return ParsedNode(name: _frag(u), protocol: 'trojan', host: u.host, port: u.port,
        raw: {'password': u.userInfo, ...u.queryParameters});
  }

  static ParsedNode _parseHy2(String link) {
    final u = Uri.parse(link);
    return ParsedNode(name: _frag(u), protocol: 'hysteria2', host: u.host, port: u.port,
        raw: {'password': u.userInfo, ...u.queryParameters});
  }

  static ParsedNode _parseVmess(String link) {
    final b64 = link.substring('vmess://'.length).split('#').first;
    var padded = b64.replaceAll(RegExp(r'\s+'), '');
    padded = padded.replaceAll('-', '+').replaceAll('_', '/');
    if (padded.length % 4 > 0) padded += '=' * (4 - padded.length % 4);
    final j = jsonDecode(utf8.decode(base64Decode(padded))) as Map<String, dynamic>;
    return ParsedNode(
      name: (j['ps'] ?? j['add'] ?? '').toString(),
      protocol: 'vmess',
      host: (j['add'] ?? '').toString(),
      port: int.tryParse((j['port'] ?? '443').toString()) ?? 443,
      raw: j,
    );
  }

  static ParsedNode _parseSS(String link) {
    final body = link.substring('ss://'.length);
    final hashIdx = body.indexOf('#');
    final name = hashIdx >= 0 ? Uri.decodeComponent(body.substring(hashIdx + 1)) : '';
    final main = hashIdx >= 0 ? body.substring(0, hashIdx) : body;
    String method, password, host;
    int port;
    if (main.contains('@') && !RegExp(r'^[A-Za-z0-9+/=_]+$').hasMatch(main)) {
      final at = main.indexOf('@');
      var b64part = main.substring(0, at).replaceAll('-', '+').replaceAll('_', '/');
      if (b64part.length % 4 > 0) b64part += '=' * (4 - b64part.length % 4);
      final cred = utf8.decode(base64Decode(b64part));
      final colon = cred.indexOf(':');
      method = cred.substring(0, colon);
      password = cred.substring(colon + 1);
      final hp = main.substring(at + 1);
      host = hp.split(':').first;
      port = int.tryParse(hp.split(':').last) ?? 443;
    } else {
      var padded = main.replaceAll('-', '+').replaceAll('_', '/');
      if (padded.length % 4 > 0) padded += '=' * (4 - padded.length % 4);
      final full = utf8.decode(base64Decode(padded));
      final at = full.lastIndexOf('@');
      final cred = full.substring(0, at);
      final colon = cred.indexOf(':');
      method = cred.substring(0, colon);
      password = cred.substring(colon + 1);
      final hp = full.substring(at + 1);
      host = hp.split(':').first;
      port = int.tryParse(hp.split(':').last) ?? 443;
    }
    return ParsedNode(name: name.isEmpty ? host : name, protocol: 'ss', host: host, port: port,
        raw: {'method': method, 'password': password});
  }
}
