import 'dart:async';
import 'dart:convert';
import '../core/singbox_ffi.dart';

/// Высокоуровневый сервис поверх FFI-ядра (Hiddify-style: Flutter UI + libsingbox через dart:ffi).
/// Один кор на все платформы, TUN нативный везде (sing-tun на Windows).
class SingBoxService {
  final SingBoxFFI _ffi = SingBoxFFI();
  int _handle = 0;
  bool get running => _handle > 0;

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
      'type': 'vless', 'tag': 'proxy',
      'server': host, 'server_port': port, 'uuid': uuid, 'flow': flow,
      'tls': {
        'enabled': true,
        'server_name': sni.isEmpty ? host : sni,
        'utls': {'enabled': true, 'fingerprint': fingerprint},
        if (security == 'reality')
          'reality': {'enabled': true, 'public_key': publicKey, 'short_id': shortId},
      },
    };
    return jsonEncode({
      'log': {'level': 'warn'},
      'inbounds': [
        {
          'type': 'tun', 'tag': 'tun-in',
          'inet4_address': '172.19.0.1/30',
          'auto_route': true, 'strict_route': true, 'stack': 'system',
        }
      ],
      'outbounds': [
        outbound,
        {'type': 'direct', 'tag': 'direct'},
        {'type': 'block', 'tag': 'block'},
      ],
      'route': {
        'rules': [{'ip_is_private': true, 'outbound': 'direct'}],
        'final': 'proxy',
        'auto_detect_interface': true,
      },
    });
  }

  /// Валидирует конфиг до старта (ошибка -> exception).
  void validate(String configJson) {
    final err = _ffi.validate(configJson);
    if (err.isNotEmpty) throw ArgumentError('sing-box config invalid: $err');
  }

  Future<void> start(String configJson) async {
    validate(configJson);
    final h = _ffi.start(configJson);
    if (h <= 0) throw StateError('sing-box failed to start (code $h)');
    _handle = h;
  }

  Future<void> stop() async {
    if (_handle > 0) {
      _ffi.stop(_handle);
      _handle = 0;
    }
  }
}
