import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/proxy_parser.dart';

/// Сохраняет импортированные ноды и настройки локально, чтоб не слетали при перезапуске.
class NodeStorage {
  static const _nodesKey = 'fl_nodes_v1';
  static const _selectedKey = 'fl_selected_v1';
  static const _pingMethodKey = 'fl_ping_method_v1';

  Future<List<ParsedNode>> loadNodes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_nodesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return ParsedNode(
          name: (m['name'] ?? '').toString(),
          protocol: (m['protocol'] ?? '').toString(),
          host: (m['host'] ?? '').toString(),
          port: int.tryParse((m['port'] ?? '0').toString()) ?? 0,
          raw: Map<String, dynamic>.from(m['raw'] as Map? ?? {}),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNodes(List<ParsedNode> nodes) async {
    final prefs = await SharedPreferences.getInstance();
    final enc = nodes.map((n) => {
          'name': n.name,
          'protocol': n.protocol,
          'host': n.host,
          'port': n.port,
          'raw': n.raw,
        }).toList();
    await prefs.setString(_nodesKey, jsonEncode(enc));
  }

  Future<int> loadSelected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_selectedKey) ?? 0;
  }

  Future<void> saveSelected(int i) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedKey, i);
  }

  Future<String> loadPingMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pingMethodKey) ?? 'tcp';
  }

  Future<void> savePingMethod(String m) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pingMethodKey, m);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nodesKey);
    await prefs.remove(_selectedKey);
  }
}
