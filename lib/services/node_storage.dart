import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/vpn_state.dart';

class NodeStorage {
  static const _subsKey = 'fl_subs_v2';
  static const _selectedKey = 'fl_selected_v1';
  static const _pingMethodKey = 'fl_ping_method_v1';

  Future<List<Subscription>> loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_subsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Subscription.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  Future<void> saveSubscriptions(List<Subscription> subs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subsKey, jsonEncode(subs.map((s) => s.toJson()).toList()));
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
}
