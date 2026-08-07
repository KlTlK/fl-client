import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_client/core/proxy_parser.dart';
import 'package:fl_client/core/singbox_outbound_builder.dart';

void main() {
  group('ProxyParser', () {
    test('parses vless with reality', () {
      const link =
          'vless://b831381d-6324-4d53-ad4f-8cda48b30811@example.com:443?security=reality&sni=example.com&fp=chrome&pbk=abc&sid=def&flow=xtls-rprx-vision&type=tcp#my-node';
      final nodes = ProxyParser.parseAny(link);
      expect(nodes.length, 1);
      final n = nodes.first;
      expect(n.protocol, 'vless');
      expect(n.host, 'example.com');
      expect(n.port, 443);
      expect(n.name, 'my-node');
      expect(n.raw['uuid'], 'b831381d-6324-4d53-ad4f-8cda48b30811');
      expect(n.raw['security'], 'reality');
      expect(n.raw['pbk'], 'abc');
    });

    test('parses vmess base64-json', () {
      final obj = {
        'v': '2', 'ps': 'vmess-node', 'add': '1.2.3.4', 'port': '8443',
        'id': 'uuid-vmess', 'aid': '0', 'scy': 'auto', 'tls': 'tls',
      };
      final b64 = base64Encode(utf8.encode(jsonEncode(obj)));
      final nodes = ProxyParser.parseAny('vmess://$b64');
      expect(nodes.length, 1);
      expect(nodes.first.protocol, 'vmess');
      expect(nodes.first.host, '1.2.3.4');
      expect(nodes.first.port, 8443);
      expect(nodes.first.raw['id'], 'uuid-vmess');
    });

    test('parses trojan', () {
      const link = 'trojan://pass123@t.example.com:443?sni=t.example.com#tr';
      final n = ProxyParser.parseAny(link).first;
      expect(n.protocol, 'trojan');
      expect(n.raw['password'], 'pass123');
      expect(n.host, 't.example.com');
    });

    test('parses hysteria2', () {
      const link = 'hysteria2://pw@h.example.com:443?sni=h.example.com#hy';
      final n = ProxyParser.parseAny(link).first;
      expect(n.protocol, 'hysteria2');
      expect(n.raw['password'], 'pw');
    });

    test('parses base64 subscription bundle', () {
      const links =
          'vless://uuid@a.com:443?security=tls#n1\n'
          'trojan://pw@b.com:443#n2\n';
      final b64 = base64Encode(utf8.encode(links));
      final nodes = ProxyParser.parseAny(b64);
      expect(nodes.length, 2);
      expect(nodes[0].protocol, 'vless');
      expect(nodes[1].protocol, 'trojan');
    });

    test('parses multi-line plain bundle', () {
      const bundle =
          '# comment\n'
          'vless://u@a.com:443#x\n'
          '\n'
          'ss://YWVzLTEyOC1nY206cGFzcw==@s.com:8388#ss\n';
      final nodes = ProxyParser.parseAny(bundle);
      expect(nodes.length, 2);
    });

    test('returns empty for garbage', () {
      expect(ProxyParser.parseAny(''), isEmpty);
      expect(ProxyParser.parseAny('not a link at all'), isEmpty);
    });
  });

  group('SingBoxOutboundBuilder', () {
    test('builds full tun config from vless node', () {
      const link =
          'vless://uuid@example.com:443?security=reality&sni=example.com&pbk=k&sid=s&flow=xtls-rprx-vision#n';
      final node = ProxyParser.parseAny(link).first;
      final cfg = jsonDecode(SingBoxOutboundBuilder.buildFullConfig(node)) as Map;
      expect((cfg['inbounds'] as List).first['type'], 'tun');
      final out = (cfg['outbounds'] as List).first;
      expect(out['type'], 'vless');
      expect(out['tls']['reality']['enabled'], true);
      expect(cfg['route']['final'], 'proxy');
    });
  });
}
