import 'dart:convert';
import 'package:flutter_singbox_vpn/flutter_singbox_vpn.dart';

/// Сервис на sing-box ядре. Жрёт любые сабы: VLESS / VMess / Trojan /
/// Shadowsocks / Hysteria2 / TUIC / WireGuard — sing-box поддерживает всё [[1]].
class SingBoxService {
  final FlutterSingboxVpn _vpn = FlutterSingboxVpn();

  /// Строит sing-box config из параметров VLESS/Reality узла.
  static String buildConfig({
    required String uuid,
    required String host,
    required int port,
    String flow = 'xtls-rprx-vision',
    String security = 'reality',
    String sni = '',
    String publicKey = '',
    String shortId = '',
    String fingerprint = 'chrome',
  }) {
    final outbound = {
      'type': 'vless',
      'tag': 'proxy',
      'server': host,
      'server_port': port,
      'uuid': uuid,
      'flow': flow,
      'tls': {
        'enabled': true,
        'server_name': sni.isEmpty ? host : sni,
        'utls': {'enabled': true, 'fingerprint': fingerprint},
        if (security == 'reality') ...{
          'reality': {
            'enabled': true,
            'public_key': publicKey,
            'short_id': shortId,
          }
        }
      },
    };

    final config = {
      'log': {'level': 'warn'},
      'inbounds': [
        {
          'type': 'tun',
          'tag': 'tun-in',
          'inet4_address': '172.19.0.1/30',
          'auto_route': true,
          'strict_route': true,
          'stack': 'system',
        }
      ],
      'outbounds': [
        outbound,
        {'type': 'direct', 'tag': 'direct'},
        {'type': 'block', 'tag': 'block'},
      ],
      'route': {
        'rules': [
          {'ip_is_private': true, 'outbound': 'direct'},
        ],
        'final': 'proxy',
        'auto_detect_interface': true,
      },
    };
    return jsonEncode(config);
  }

  Future<void> start(String configJson) async {
    await _vpn.start(config: configJson);
  }

  Future<void> stop() async {
    await _vpn.stop();
  }

  /// Реальный пинг/статус через sing-box.
  Stream<Map<String, dynamic>> get statusStream => _vpn.statusStream;
}
