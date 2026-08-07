import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/proxy_parser.dart';
import '../core/pinger.dart';
import '../services/singbox_service.dart';
import '../services/config_importer.dart';
import '../services/node_storage.dart';

enum VpnStatus { disconnected, connecting, connected, disconnecting }

class TrafficPoint {
  final double up;
  final double down;
  TrafficPoint(this.up, this.down);
}

class VpnState extends ChangeNotifier {
  final SingBoxService _sb = SingBoxService();
  final ConfigImporter _importer = ConfigImporter();
  final NodeStorage _storage = NodeStorage();
  final Pinger _pinger = Pinger();

  VpnStatus _status = VpnStatus.disconnected;
  VpnStatus get status => _status;

  List<ParsedNode> _nodes = const [];
  List<ParsedNode> get nodes => _nodes;

  int _selected = 0;
  int get selectedIndex => _selected;
  ParsedNode? get selectedNode => _nodes.isEmpty ? null : _nodes[_selected];

  PingMethod _pingMethod = PingMethod.tcp;
  PingMethod get pingMethod => _pingMethod;

  // latency по каждой ноде (индекс -> мс, null = unreachable)
  final Map<int, int?> _latencies = {};
  int? latencyFor(int i) => _latencies[i];
  int get latency => _latencies[_selected] ?? 0;

  final List<TrafficPoint> _traffic = [];
  List<TrafficPoint> get traffic => List.unmodifiable(_traffic);
  double _upSpeed = 0, _downSpeed = 0;
  double get upSpeed => _upSpeed;
  double get downSpeed => _downSpeed;

  String? _error;
  String? get error => _error;
  bool get coreAvailable => _sb.coreAvailable;

  Timer? _timer;
  bool _bootstrapped = false;

  /// Загрузка сохранённых нод при старте. Вызывать один раз из UI (init).
  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    _nodes = await _storage.loadNodes();
    _selected = await _storage.loadSelected();
    if (_selected >= _nodes.length) _selected = _nodes.isEmpty ? 0 : _nodes.length - 1;
    final pm = await _storage.loadPingMethod();
    _pingMethod = pm == 'http' ? PingMethod.httpGet : PingMethod.tcp;
    notifyListeners();
  }

  // ---- Импорт (с автосохранением) ----
  void importFromString(String raw) {
    _nodes = _importer.fromString(raw);
    _selected = 0;
    _error = _nodes.isEmpty ? 'No supported links found' : null;
    _persist();
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
    _persist();
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
    _persist();
    notifyListeners();
  }

  Future<void> selectNode(int i) async {
    if (i < 0 || i >= _nodes.length) return;
    _selected = i;
    await _storage.saveSelected(i);
    notifyListeners();
  }

  Future<void> setPingMethod(PingMethod m) async {
    _pingMethod = m;
    await _storage.savePingMethod(m == PingMethod.httpGet ? 'http' : 'tcp');
    _latencies.clear();
    notifyListeners();
  }

  /// Пингует все ноды выбранным методом (tcp / http get).
  Future<void> pingAll() async {
    for (var i = 0; i < _nodes.length; i++) {
      final idx = i;
      final res = await _pinger.ping(_nodes[idx], method: _pingMethod);
      _latencies[idx] = res.ms;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    await _storage.saveNodes(_nodes);
    await _storage.saveSelected(_selected);
  }

  // ---- Connect / disconnect ----
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
    if (!_sb.coreAvailable) {
      _error = 'Native core not loaded: ${_sb.coreError}';
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
    _timer = null;
    notifyListeners();
    try {
      await _sb.stop(); // graceful shutdown + propagate ошибок
    } catch (e) {
      debugPrint('stop failed: $e');
      _error = 'Disconnect warning: $e';
    }
    _status = VpnStatus.disconnected;
    _upSpeed = 0; _downSpeed = 0;
    notifyListeners();
  }

  void _startLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // TODO: брать реальные байты из callback'ов ядра вместо симуляции.
      _upSpeed = 20 + (_upSpeed * 0.7);
      _downSpeed = 80 + (_downSpeed * 0.7);
      _traffic.add(TrafficPoint(_upSpeed.clamp(0, 1000), _downSpeed.clamp(0, 1000)));
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
