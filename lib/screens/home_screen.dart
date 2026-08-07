import 'package:flutter/material.dart';
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
              // LEFT: connect + stats
              SizedBox(
                width: 300,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('fl-client', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          Icon(Icons.circle, size: 10, color: vpn.coreAvailable ? AppTheme.neon : AppTheme.danger),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PowerButton(state: vpn, onTap: vpn.toggle),
                      const SizedBox(height: 12),
                      Text(
                        connected ? 'CONNECTED' : vpn.status.name.toUpperCase(),
                        style: TextStyle(fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.w600,
                            color: connected ? AppTheme.neon : Colors.white54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        node == null ? 'No node' : (node.name.isEmpty ? node.host : node.name),
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: TrafficChart(state: vpn)),
                      const SizedBox(height: 10),
                      _row('Latency', lat > 0 ? '$lat ms' : '--'),
                      _row('Down', '${vpn.downSpeed.toStringAsFixed(0)} KB/s'),
                      _row('Up', '${vpn.upSpeed.toStringAsFixed(0)} KB/s'),
                      _row('Nodes', '${vpn.nodes.length}'),
                    ],
                  ),
                ),
              ),
              Container(width: 1, color: Colors.white12),
              // RIGHT: import + nodes
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Subscription', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: TextField(
                          controller: _urlCtrl,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(hintText: 'https://...', isDense: true,
                              border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        )),
                        const SizedBox(width: 6),
                        FilledButton(onPressed: () => vpn.importFromUrl(_urlCtrl.text),
                            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                            child: const Text('Fetch', style: TextStyle(fontSize: 12))),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        OutlinedButton.icon(
                          onPressed: () => vpn.importFromClipboard(),
                          icon: const Icon(Icons.content_paste_rounded, size: 14),
                          label: const Text('Clipboard', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('TCP', style: TextStyle(fontSize: 11)),
                          selected: vpn.pingMethod == PingMethod.tcp,
                          onSelected: (_) => vpn.setPingMethod(PingMethod.tcp),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 4),
                        ChoiceChip(
                          label: const Text('HTTP', style: TextStyle(fontSize: 11)),
                          selected: vpn.pingMethod == PingMethod.httpGet,
                          onSelected: (_) => vpn.setPingMethod(PingMethod.httpGet),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: vpn.nodes.isEmpty ? null : () => vpn.pingAll(),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                          child: const Text('Ping all', style: TextStyle(fontSize: 11)),
                        ),
                      ]),
                      if (vpn.error != null) ...[
                        const SizedBox(height: 6),
                        Container(padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(vpn.error!, style: const TextStyle(color: AppTheme.danger, fontSize: 11))),
                      ],
                      const SizedBox(height: 10),
                      Text('Nodes (${vpn.nodes.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Expanded(
                        child: vpn.nodes.isEmpty
                            ? const Center(child: Text('Import a subscription', style: TextStyle(color: Colors.white38)))
                            : ListView.builder(
                                itemCount: vpn.nodes.length,
                                itemBuilder: (_, i) {
                                  final n = vpn.nodes[i];
                                  final sel = i == vpn.selectedIndex;
                                  final ping = vpn.latencyFor(i);
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    color: sel ? AppTheme.neon.withOpacity(0.12) : AppTheme.surface,
                                    child: ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      leading: Icon(Icons.vpn_key_rounded, size: 18, color: sel ? AppTheme.neon : Colors.white54),
                                      title: Text(n.name.isEmpty ? n.host : n.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                      subtitle: Text('${n.protocol} • ${n.host}:${n.port}', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                                      trailing: ping == null
                                          ? const Text('--', style: TextStyle(color: Colors.white38, fontSize: 11))
                                          : Text('$ping ms', style: TextStyle(color: ping < 200 ? AppTheme.neon : AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 11)),
                                      onTap: () => vpn.selectNode(i),
                                    ),
                                  );
                                }),
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

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Text(l, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      const Spacer(),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    ]),
  );
}
