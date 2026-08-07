import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../state/vpn_state.dart';
import '../widgets/power_button.dart';
import '../widgets/traffic_chart.dart';
import '../core/pinger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlCtrl = TextEditingController();

  String _statusLabel(VpnStatus s) => switch (s) {
        VpnStatus.disconnected => 'DISCONNECTED',
        VpnStatus.connecting => 'CONNECTING...',
        VpnStatus.connected => 'CONNECTED',
        VpnStatus.disconnecting => 'DISCONNECTING...',
      };

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnState>(builder: (context, vpn, _) {
      final connected = vpn.status == VpnStatus.connected;
      final node = vpn.selectedNode;
      final lat = vpn.latency;
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              // === LEFT PANEL: connect + stats ===
              SizedBox(
                width: 320,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('fl-client',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                          Icon(Icons.circle, size: 10,
                              color: vpn.coreAvailable ? AppTheme.neon : AppTheme.danger),
                        ],
                      ),
                      const SizedBox(height: 20),
                      PowerButton(state: vpn, onTap: vpn.toggle),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _statusLabel(vpn.status),
                          key: ValueKey(vpn.status),
                          style: TextStyle(
                            fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w600,
                            color: connected ? AppTheme.neon : Colors.white54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        node == null
                            ? 'No node selected'
                            : '${node.name.isEmpty ? node.host : node.name}',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: TrafficChart(state: vpn)),
                      const SizedBox(height: 12),
                      _statRow('Latency', lat > 0 ? '$lat ms' : '--', Icons.speed_rounded),
                      const SizedBox(height: 8),
                      _statRow('Download', '${vpn.downSpeed.toStringAsFixed(0)} KB/s', Icons.arrow_downward_rounded),
                      const SizedBox(height: 8),
                      _statRow('Upload', '${vpn.upSpeed.toStringAsFixed(0)} KB/s', Icons.arrow_upward_rounded),
                      const SizedBox(height: 8),
                      _statRow('Nodes', '${vpn.nodes.length}', Icons.vpn_key_rounded),
                    ],
                  ),
                ),
              ),

              // === Divider ===
              Container(width: 1, color: Colors.white12),

              // === RIGHT PANEL: import + node list ===
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Subscription',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _urlCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'https://...',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => vpn.importFromUrl(_urlCtrl.text),
                            child: const Text('Fetch'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => vpn.importFromClipboard(),
                            icon: const Icon(Icons.content_paste_rounded, size: 16),
                            label: const Text('Clipboard'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SegmentedButton<PingMethod>(
                            segments: const [
                              ButtonSegment(value: PingMethod.tcp, label: Text('TCP')),
                              ButtonSegment(value: PingMethod.httpGet, label: Text('HTTP')),
                            ],
                            selected: {vpn.pingMethod},
                            onSelectionChanged: (s) => vpn.setPingMethod(s.first),
                            style: SegmentedButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: vpn.nodes.isEmpty ? null : () => vpn.pingAll(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: const Text('Ping all'),
                          ),
                        ],
                      ),
                      if (vpn.error != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(vpn.error!,
                              style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text('Nodes (${vpn.nodes.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: vpn.nodes.isEmpty
                            ? const Center(child: Text('Import a subscription to see nodes',
                                style: TextStyle(color: Colors.white38)))
                            : ListView.builder(
                                itemCount: vpn.nodes.length,
                                itemBuilder: (_, i) {
                                  final n = vpn.nodes[i];
                                  final sel = i == vpn.selectedIndex;
                                  final ping = vpn.latencyFor(i);
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    color: sel ? AppTheme.neon.withOpacity(0.12) : AppTheme.surface,
                                    child: ListTile(
                                      dense: true,
                                      leading: Icon(Icons.vpn_key_rounded, size: 20,
                                          color: sel ? AppTheme.neon : Colors.white54),
                                      title: Text(
                                        n.name.isEmpty ? n.host : n.name,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${n.protocol} • ${n.host}:${n.port}',
                                        style: const TextStyle(fontSize: 11, color: Colors.white38),
                                      ),
                                      trailing: ping == null
                                          ? const Text('--', style: TextStyle(color: Colors.white38, fontSize: 12))
                                          : Text('$ping ms',
                                              style: TextStyle(
                                                color: ping < 200 ? AppTheme.neon : AppTheme.danger,
                                                fontWeight: FontWeight.w700, fontSize: 12)),
                                      onTap: () => vpn.selectNode(i),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _statRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.neon),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}
