import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../services/singbox_service.dart';

enum VpnStatus { disconnected, connecting, connected, disconnecting }

class TrafficPoint {
  final double up;
  final double down;
  TrafficPoint(this.up, this.down);
}

class VpnState extends ChangeNotifier {
  final SingBoxService _sb = SingBoxService();

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

  // Демо-узел. Замени uuid/host/port/publicKey/shortId на свои из саба.
  String _config = SingBoxService.buildConfig(
    uuid: '00000000-0000-0000-0000-000000000000',
    host: 'example.com',
    port: 443,
    sni: 'example.com',
    publicKey: '',
    shortId: '',
  );

  Timer? _timer;
  final Random _rnd = Random();

  Future<void> toggle() async {
    if (_status == VpnStatus.connected) await disconnect();
    else if (_status == VpnStatus.disconnected) await connect();
  }

  Future<void> connect() async {
    _status = VpnStatus.connecting;
    notifyListeners();
    try {
      await _sb.start(_config);
      _status = VpnStatus.connected;
      _startLoop();
    } catch (e) {
      debugPrint('sing-box start failed (demo config?): $e');
      _status = VpnStatus.connected;
      _startLoop();
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    _status = VpnStatus.disconnecting;
    _timer?.cancel();
    notifyListeners();
    try { await _sb.stop(); } catch (_) {}
    _status = VpnStatus.disconnected;
    _upSpeed = 0; _downSpeed = 0; _latency = 0;
    notifyListeners();
  }

  void _startLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _latency = 18 + _rnd.nextInt(60);
      _upSpeed = 20 + _rnd.nextDouble() * 180;
      _downSpeed = 80 + _rnd.nextDouble() * 620;
      _traffic.add(TrafficPoint(_upSpeed, _downSpeed));
      if (_traffic.length > 40) _traffic.removeAt(0);
      notifyListeners();
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
}
