import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/proxy_parser.dart';
import '../services/singbox_service.dart';
import '../services/config_importer.dart';

enum VpnStatus { disconnected, connecting, connected, disconnecting }

class TrafficPoint {
  final double up;
  final double down;
  TrafficPoint(this.up, this.down);
}

class VpnState extends ChangeNotifier {
  final SingBoxService _sb = SingBoxService();
  final ConfigImporter _importer = ConfigImporter();

  VpnStatus _status = VpnStatus.disconnected;
  VpnStatus get status => _status;

  List<ParsedNode> _nodes = const [];
  List<ParsedNode> get nodes => _nodes;

  int _selected = 0;
  int get selectedIndex => _selected;
  ParsedNode? get selectedNode => _nodes.isEmpty ? null : _nodes[_selected];

  int _latency = 0;
  int get latency => _latency;
  final List<TrafficPoint> _traffic = [];
  List<TrafficPoint> get traffic => List.unmodifiable(_traffic);
  double _upSpeed = 0, _downSpeed = 0;
  double get upSpeed => _upSpeed;
  double get downSpeed => _downSpeed;

  String? _error;
  String? get error => _error;

  Timer? _timer;
  final Random _rnd = Random();

  // ---- Импорт ----
  void importFromString(String raw) {
    _nodes = _importer.fromString(raw);
    _selected = 0;
    _error = _nodes.isEmpty ? 'No supported links found' : null;
    notifyListeners();
  }

  Future<void> importFromClipboard() async {
    try {
      _nodes = await _importer.fromClipboard();
      _selected = 0;
      _error = _nodes.isEmpty ? 'Clipboard empty or no supported links' : null;
    } catch (e) {
      _error = 'Import failed: $e';
    }
    notifyListeners();
  }

  Future<void> importFromUrl(String url) async {
    try {
      _nodes = await _importer.fromUrl(url);
      _selected = 0;
      _error = _nodes.isEmpty ? 'Subscription returned no supported links' : null;
    } catch (e) {
      _error = 'Subscription fetch failed: $e';
    }
    notifyListeners();
  }

  void selectNode(int i) {
    if (i < 0 || i >= _nodes.length) return;
    _selected = i;
    notifyListeners();
  }

  // ---- Connect / disconnect с нормальным lifecycle ----
  Future<void> toggle() async {
    if (_status == VpnStatus.connected) await disconnect();
    else if (_status == VpnStatus.disconnected) await connect();
  }

  Future<void> connect() async {
    if (_nodes.isEmpty) {
      _error = 'Import a subscription first';
      notifyListeners();
      return;
    }
    _status = VpnStatus.connecting;
    _error = null;
    notifyListeners();
    try {
      await _sb.startNode(selectedNode!);
      _status = VpnStatus.connected;
      _startLoop();
    } catch (e) {
      debugPrint('connect failed: $e');
      _error = 'Connect failed: $e';
      _status = VpnStatus.disconnected;
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    _status = VpnStatus.disconnecting;
    _timer?.cancel();
    notifyListeners();
    try {
      await _sb.stop();
    } catch (e) {
      debugPrint('stop failed: $e');
    }
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
  void dispose() {
    _timer?.cancel();
    _importer.dispose();
    super.dispose();
  }
}
