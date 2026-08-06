import 'dart:convert';
import 'package:flutter_v2ray_client/flutter_v2ray_client.dart';

/// Обёртка над Xray-кором. flutter_v2ray_client под капотом крутит тот самый
/// xray-core (тот же движок, что в v2rayNG / FlClash) [[2]][[3]].
class XrayService {
  final FlutterV2ray _v2ray = FlutterV2ray();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _v2ray.initializeV2ray();
    _initialized = true;
  }

  /// Строит Xray/V2Ray config URL из параметров (VLESS пример).
  static String buildVlessUrl({
    required String uuid,
    required String host,
    required int port,
    String flow = 'xtls-rprx-vision',
    String security = 'reality',
    String sni = '',
    String fp = 'chrome',
    String pbk = '',
    String sid = '',
  }) {
    final q = Uri(queryParameters: {
      'type': 'tcp',
      'security': security,
      'flow': flow,
      'sni': sni,
      'fp': fp,
      'pbk': pbk,
      'sid': sid,
    }).query;
    return 'vless://$uuid@$host:$port?$q#fl-client';
  }

  Future<void> start({required String configUrl, bool vpnMode = true}) async {
    await init();
    await _v2ray.startV2ray(
      config: configUrl,
      proxyPort: 10808,
      vpnMode: vpnMode,
    );
  }

  Future<void> stop() async {
    await _v2ray.stopV2ray();
  }

  /// Реальный пинг до сервера через кор.
  Future<int> ping(String configUrl) async {
    await init();
    return await _v2ray.ping(configUrl);
  }
}
