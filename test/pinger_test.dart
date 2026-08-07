import 'package:flutter_test/flutter_test.dart';
import 'package:fl_client/core/pinger.dart';
import 'package:fl_client/core/proxy_parser.dart';

void main() {
  group('Pinger', () {
    test('tcp returns failed for unreachable host', () async {
      final pinger = Pinger(timeout: const Duration(seconds: 2));
      final node = ParsedNode(
        name: 'x', protocol: 'vless',
        host: '10.255.255.1', port: 1, raw: const {}, // non-routable -> fast fail
      );
      final res = await pinger.ping(node, method: PingMethod.tcp);
      expect(res.ok, isFalse);
      expect(res.ms, isNull);
    });

    test('http get returns failed for unreachable host', () async {
      final pinger = Pinger(timeout: const Duration(seconds: 2));
      final node = ParsedNode(
        name: 'x', protocol: 'trojan',
        host: '10.255.255.1', port: 1, raw: const {},
      );
      final res = await pinger.ping(node, method: PingMethod.httpGet);
      expect(res.ok, isFalse);
    });

    test('tcp to a real open port measures latency', () async {
      // Публичный DNS Cloudflare обычно открыт на 443/tcp.
      final pinger = Pinger(timeout: const Duration(seconds: 5));
      final node = ParsedNode(
        name: 'cf', protocol: 'vless',
        host: '1.1.1.1', port: 443, raw: const {},
      );
      final res = await pinger.ping(node, method: PingMethod.tcp);
      // Не ассертим ok (зависит от сети CI), но если ок - мс > 0.
      if (res.ok) {
        expect(res.ms!, greaterThan(0));
      }
    });
  });
}
