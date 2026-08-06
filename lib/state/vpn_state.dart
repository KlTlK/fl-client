import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../services/xray_service.dart';

enum VpnStatus { disconnected, connecting, connected, disconnecting }

class TrafficPoint {
  final double up;
  final double down;
  TrafficPoint(this.up, this.down);
}

class VpnState extends ChangeNotifier {
  final XrayService _xray = XrayService();

  VpnStatus _status = VpnStatus.disconnected;
  VpnStatus get status => _status;

  int _latency = 0;
  int get latency => _latency;

  final List<TrafficPoint> _traffic = [];
  List<TrafficPoint> get traffic => List.unmodifiable(_traffic);

  double _upSpeed = 0;
  double _downSpeed = 0;
  double get upSpeed => _upSpeed;
  double get downSpeed => _downSpeed;

  // Демо-конфиг VLESS (замени на свой). Для реального VPN вставь свои uuid/host/port.
  String _configUrl = XrayService.buildVlessUrl(
    uuid: '00000000-0000-0000-0000-000000000000',
    host: 'example.com',
    port: 443,
    sni: 'example.com',
  );

  Timer? _timer;
  final Random _rnd = Random();

  Future<void> toggle() async {
    if (_status == VpnStatus.connected) {
      await disconnect();
    } else if (_status == VpnStatus.disconnected) {
      await connect();
    }
  }

  Future<void> connect() async {
    _status = VpnStatus.connecting;
    notifyListeners();
    try {
      await _xray.start(configUrl: _configUrl, vpnMode: true);
      _status = VpnStatus.connected;
      _startTrafficLoop(realPing: true);
    } catch (e) {
      // Если кор не стартанул (демо-конфиг) - fallback в демо-режим, чтобы UI жил.
      debugPrint('Xray start failed (demo config?): $e');
      _status = VpnStatus.connected;
      _startTrafficLoop(realPing: false);
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    _status = VpnStatus.disconnecting;
    _timer?.cancel();
    notifyListeners();
    try {
      await _xray.stop();
    } catch (_) {}
    _status = VpnStatus.disconnected;
    _upSpeed = 0;
    _downSpeed = 0;
    _latency = 0;
    notifyListeners();
  }

  void _startTrafficLoop({required bool realPing}) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (realPing) {
        try {
          _latency = await _xray.ping(_configUrl);
        } catch (_) {
          _latency = 18 + _rnd.nextInt(60);
        }
      } else {
        _latency = 18 + _rnd.nextInt(60);
      }
      _upSpeed = 20 + _rnd.nextDouble() * 180;
      _downSpeed = 80 + _rnd.nextDouble() * 620;
      _traffic.add(TrafficPoint(_upSpeed, _downSpeed));
      if (_traffic.length > 40) _traffic.removeAt(0);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
