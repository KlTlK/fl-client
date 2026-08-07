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

class Subscription {
  final String name;
  final String? url;
  List<ParsedNode> nodes;
  bool expanded;

  Subscription({required this.name, this.url, this.nodes = const [], this.expanded = true});

  Map<String, dynamic> toJson() => {
    'name': name, 'url': url, 'expanded': expanded,
    'nodes': nodes.map((n) => {
      'name': n.name, 'protocol': n.protocol, 'host': n.host, 'port': n.port, 'raw': n.raw,
    }).toList(),
  };

  static Subscription fromJson(Map<String, dynamic> j) => Subscription(
    name: (j['name'] ?? '').toString(),
    url: j['url']?.toString(),
    expanded: j['expanded'] ?? true,
    nodes: (j['nodes'] as List? ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return ParsedNode(
        name: (m['name'] ?? '').toString(),
        protocol: (m['protocol'] ?? '').toString(),
        host: (m['host'] ?? '').toString(),
        port: int.tryParse((m['port'] ?? '0').toString()) ?? 0,
        raw: Map<String, dynamic>.from(m['raw'] as Map? ?? {}),
      );
    }).toList(),
  );
}

class VpnState extends ChangeNotifier {
  final SingBoxService _sb = SingBoxService();
  final ConfigImporter _importer = ConfigImporter();
  final NodeStorage _storage = NodeStorage();
  final Pinger _pinger = Pinger();

  VpnStatus _status = VpnStatus.disconnected;
  VpnStatus get status => _status;

  List<Subscription> _subs = [];
  List<Subscription> get subscriptions => _subs;

  // Flat list of all nodes across all subs
  List<ParsedNode> get allNodes => _subs.expand((s) => s.nodes).toList();

  int _selectedGlobalIdx = 0;
  int get selectedIndex => _selectedGlobalIdx;
  ParsedNode? get selectedNode {
    final all = allNodes;
    return _selectedGlobalIdx < all.length ? all[_selectedGlobalIdx] : null;
  }

  PingMethod _pingMethod = PingMethod.tcp;
  PingMethod get pingMethod => _pingMethod;

  final Map<int, int?> _latencies = {};
  int? latencyFor(int i) => _latencies[i];
  int get latency => _latencies[_selectedGlobalIdx] ?? 0;

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

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    _subs = await _storage.loadSubscriptions();
    _selectedGlobalIdx = await _storage.loadSelected();
    if (_selectedGlobalIdx >= allNodes.length) _selectedGlobalIdx = 0;
    final pm = await _storage.loadPingMethod();
    _pingMethod = pm == 'http' ? PingMethod.httpGet : PingMethod.tcp;
    notifyListeners();
  }

  // --- Subscription management ---
  Future<void> addSubscriptionFromUrl(String url) async {
    try {
      final nodes = await _importer.fromUrl(url);
      if (nodes.isEmpty) { _error = 'No nodes found'; notifyListeners(); return; }
      // Check if sub with same url exists -> update it
      final existing = _subs.indexWhere((s) => s.url == url.trim());
      if (existing >= 0) {
        _subs[existing].nodes = nodes;
        _subs[existing].expanded = true;
      } else {
        // Use profile-title from response or just domain as name
        final name = Uri.parse(url).host.split('.').take(2).join('.');
        _subs.add(Subscription(name: name, url: url.trim(), nodes: nodes));
      }
      _error = null;
    } catch (e) {
      _error = 'Fetch failed: $e';
    }
    _persist();
    notifyListeners();
  }

  void addSubscriptionFromString(String raw) {
    final nodes = _importer.fromString(raw);
    if (nodes.isEmpty) { _error = 'No supported links'; notifyListeners(); return; }
    _subs.add(Subscription(name: 'Manual import', nodes: nodes));
    _error = null;
    _persist();
    notifyListeners();
  }

  Future<void> addSubscriptionFromClipboard() async {
    try {
      final nodes = await _importer.fromClipboard();
      if (nodes.isEmpty) { _error = 'Clipboard empty'; notifyListeners(); return; }
      _subs.add(Subscription(name: 'Clipboard', nodes: nodes));
      _error = null;
    } catch (e) {
      _error = 'Import failed: $e';
    }
    _persist();
    notifyListeners();
  }

  void removeSubscription(int idx) {
    if (idx < 0 || idx >= _subs.length) return;
    _subs.removeAt(idx);
    if (_selectedGlobalIdx >= allNodes.length) _selectedGlobalIdx = allNodes.isEmpty ? 0 : allNodes.length - 1;
    _persist();
    notifyListeners();
  }

  void toggleSubscription(int idx) {
    if (idx < 0 || idx >= _subs.length) return;
    _subs[idx].expanded = !_subs[idx].expanded;
    notifyListeners();
  }

  void selectNode(int globalIdx) {
    if (globalIdx < 0 || globalIdx >= allNodes.length) return;
    _selectedGlobalIdx = globalIdx;
    _storage.saveSelected(globalIdx);
    notifyListeners();
  }

  Future<void> setPingMethod(PingMethod m) async {
    _pingMethod = m;
    await _storage.savePingMethod(m == PingMethod.httpGet ? 'http' : 'tcp');
    _latencies.clear();
    notifyListeners();
  }

  Future<void> pingAll() async {
    final all = allNodes;
    for (var i = 0; i < all.length; i++) {
      final idx = i;
      final res = await _pinger.ping(all[idx], method: _pingMethod);
      _latencies[idx] = res.ms;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    await _storage.saveSubscriptions(_subs);
    await _storage.saveSelected(_selectedGlobalIdx);
  }

  // --- Connect / disconnect ---
  Future<void> toggle() async {
    if (_status == VpnStatus.connected) await disconnect();
    else if (_status == VpnStatus.disconnected) await connect();
  }

  Future<void> connect() async {
    final node = selectedNode;
    if (node == null) { _error = 'Select a node first'; notifyListeners(); return; }
    if (!_sb.coreAvailable) { _error = 'Core not available: ${_sb.coreError}'; notifyListeners(); return; }
    _status = VpnStatus.connecting;
    _error = null;
    notifyListeners();
    try {
      await _sb.startNode(node);
      _status = VpnStatus.connected;
      _startLoop();
    } catch (e) {
      _error = 'Connect failed: $e';
      _status = VpnStatus.disconnected;
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    _status = VpnStatus.disconnecting;
    _timer?.cancel(); _timer = null;
    notifyListeners();
    try { await _sb.stop(); } catch (e) { _error = 'Stop warning: $e'; }
    _status = VpnStatus.disconnected;
    _upSpeed = 0; _downSpeed = 0;
    notifyListeners();
  }

  void _startLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _upSpeed = 20 + (_upSpeed * 0.7);
      _downSpeed = 80 + (_downSpeed * 0.7);
      _traffic.add(TrafficPoint(_upSpeed.clamp(0, 1000), _downSpeed.clamp(0, 1000)));
      if (_traffic.length > 40) _traffic.removeAt(0);
      notifyListeners();
    });
  }

  @override
  void dispose() { _timer?.cancel(); _importer.dispose(); super.dispose(); }
}
