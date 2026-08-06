import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

enum VpnStatus { disconnected, connecting, connected, disconnecting }

class TrafficPoint {
  final double up;
  final double down;
  TrafficPoint(this.up, this.down);
}

class VpnState extends ChangeNotifier {
  VpnStatus _status = VpnStatus.disconnected;
  VpnStatus get status => _status;

  int _latency = 0; // ms
  int get latency => _latency;

  final List<TrafficPoint> _traffic = [];
  List<TrafficPoint> get traffic => List.unmodifiable(_traffic);

  double _upSpeed = 0; // KB/s
  double _downSpeed = 0;
  double get upSpeed => _upSpeed;
  double get downSpeed => _downSpeed;

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
    // TODO: start Xray core via platform channel here.
    await Future.delayed(const Duration(milliseconds: 1400));
    _status = VpnStatus.connected;
    _startTrafficLoop();
    notifyListeners();
  }

  Future<void> disconnect() async {
    _status = VpnStatus.disconnecting;
    _timer?.cancel();
    notifyListeners();
    // TODO: stop Xray core here.
    await Future.delayed(const Duration(milliseconds: 700));
    _status = VpnStatus.disconnected;
    _upSpeed = 0;
    _downSpeed = 0;
    _latency = 0;
    notifyListeners();
  }

  void _startTrafficLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _upSpeed = 20 + _rnd.nextDouble() * 180;
      _downSpeed = 80 + _rnd.nextDouble() * 620;
      _latency = 18 + _rnd.nextInt(60);
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
