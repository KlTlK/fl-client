import 'package:flutter/foundation.dart';

/// Десктопный Xray-сервис. На Windows/macOS/Linux используем
/// flutter_v2ray_client_desktop, который умеет TUN и системный прокси [[13]].
///
/// ВАЖНО: плагин flutter_v2ray_client_desktop — платный/отдельный пакет.
/// Если он не добавлен в pubspec, этот файл служит заглушкой-контрактом:
/// UI компилируется, а реальный TUN на винде включится после добавления пакета.
class DesktopXrayService {
  bool _running = false;
  bool get running => _running;

  Future<void> start(String configUrl) async {
    // TODO(desktop): import 'package:flutter_v2ray_client_desktop/...'
    // await FlutterV2rayDesktop.start(config: configUrl, tunMode: true);
    debugPrint('DesktopXray: start requested for $configUrl (native TUN binding pending)');
    _running = true;
  }

  Future<void> stop() async {
    // await FlutterV2rayDesktop.stop();
    debugPrint('DesktopXray: stop');
    _running = false;
  }
}
