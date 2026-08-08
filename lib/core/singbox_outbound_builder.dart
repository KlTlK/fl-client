import 'dart:convert';
import 'proxy_parser.dart';

class SingBoxOutboundBuilder {
  static Map<String, dynamic> build(ParsedNode n) {
    switch (n.protocol) {
      case 'vless': return _vless(n);
      case 'vmess': return _vmess(n);
      case 'trojan': return _trojan(n);
      case 'ss': return _shadowsocks(n);
      case 'hysteria2': return _hysteria2(n);
      default: throw ArgumentError('unsupported: ${n.protocol}');
    }
  }

  static Map<String, dynamic> _vless(ParsedNode n) {
    final sec = (n.raw['security'] ?? '').toString();
    return {
      'type': 'vless', 'tag': 'proxy', 'server': n.host, 'server_port': n.port,
      'uuid': (n.raw['uuid'] ?? '').toString(),
      'flow': (n.raw['flow'] ?? '').toString(),
      if (sec.isNotEmpty) 'tls': _tls(n, reality: sec == 'reality'),
    };
  }

  static Map<String, dynamic> _vmess(ParsedNode n) {
    final tls = (n.raw['tls'] ?? '').toString() == 'tls';
    return {
      'type': 'vmess', 'tag': 'proxy', 'server': n.host, 'server_port': n.port,
      'uuid': (n.raw['id'] ?? '').toString(),
      'security': (n.raw['scy'] ?? 'auto').toString(),
      'alter_id': int.tryParse((n.raw['aid'] ?? '0').toString()) ?? 0,
      if (tls) 'tls': _tls(n),
    };
  }

  static Map<String, dynamic> _trojan(ParsedNode n) => {
    'type': 'trojan', 'tag': 'proxy', 'server': n.host, 'server_port': n.port,
    'password': (n.raw['password'] ?? '').toString(), 'tls': _tls(n),
  };

  static Map<String, dynamic> _shadowsocks(ParsedNode n) => {
    'type': 'shadowsocks', 'tag': 'proxy', 'server': n.host, 'server_port': n.port,
    'method': (n.raw['method'] ?? 'aes-128-gcm').toString(),
    'password': (n.raw['password'] ?? '').toString(),
  };

  static Map<String, dynamic> _hysteria2(ParsedNode n) => {
    'type': 'hysteria2', 'tag': 'proxy', 'server': n.host, 'server_port': n.port,
    'password': (n.raw['password'] ?? '').toString(), 'tls': _tls(n),
  };

  static Map<String, dynamic> _tls(ParsedNode n, {bool reality = false}) {
    final sni = (n.raw['sni'] ?? n.host).toString();
    final fp = (n.raw['fp'] ?? 'chrome').toString();
    return {
      'enabled': true, 'server_name': sni,
      'utls': {'enabled': true, 'fingerprint': fp},
      if (reality) 'reality': {
        'enabled': true,
        'public_key': (n.raw['pbk'] ?? '').toString(),
        'short_id': (n.raw['sid'] ?? '').toString(),
      },
    };
  }

  static String buildFullConfig(ParsedNode n) {
    return jsonEncode({
      'log': {'level': 'info'},
      'inbounds': [{
        'type': 'tun', 'tag': 'tun-in',
        'address': ['172.19.0.1/30'],
        'auto_route': true,
        'strict_route': false,
        'stack': 'gvisor',
      }],
      'outbounds': [
        build(n),
        {'type': 'direct', 'tag': 'direct'},
        {'type': 'block', 'tag': 'block'},
        {'type': 'dns', 'tag': 'dns-out'},
      ],
      'route': {
        'rules': [
          {'ip_is_private': true, 'outbound': 'direct'},
          {'protocol': 'dns', 'outbound': 'dns-out'},
        ],
        'final': 'proxy',
        'auto_detect_interface': true,
      },
    });
  }
}
