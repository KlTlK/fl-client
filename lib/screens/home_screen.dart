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
          child: Row(children: [
            // LEFT
            SizedBox(width: 300, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('fl-client', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Icon(Icons.circle, size: 10, color: vpn.coreAvailable ? AppTheme.neon : AppTheme.danger),
                ]),
                const SizedBox(height: 16),
                PowerButton(state: vpn, onTap: vpn.toggle),
                const SizedBox(height: 12),
                Text(connected ? 'CONNECTED' : vpn.status.name.toUpperCase(),
                    style: TextStyle(fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.w600,
                        color: connected ? AppTheme.neon : Colors.white54)),
                const SizedBox(height: 4),
                Text(node == null ? 'No node' : (node.name.isEmpty ? node.host : node.name),
                    style: const TextStyle(color: Colors.white38, fontSize: 11), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Expanded(child: TrafficChart(state: vpn)),
                const SizedBox(height: 10),
                _row('Latency', lat > 0 ? '$lat ms' : '--'),
                _row('Down', '${vpn.downSpeed.toStringAsFixed(0)} KB/s'),
                _row('Up', '${vpn.upSpeed.toStringAsFixed(0)} KB/s'),
                _row('Nodes', '${vpn.allNodes.length}'),
              ]),
            )),
            Container(width: 1, color: Colors.white12),
            // RIGHT
            Expanded(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Subscription', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: _urlCtrl, style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(hintText: 'https://...', isDense: true,
                        border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)))),
                  const SizedBox(width: 6),
                  FilledButton(onPressed: () => vpn.addSubscriptionFromUrl(_urlCtrl.text),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                      child: const Text('Fetch', style: TextStyle(fontSize: 12))),
                ]),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  OutlinedButton.icon(onPressed: () => vpn.addSubscriptionFromClipboard(),
                    icon: const Icon(Icons.content_paste_rounded, size: 14),
                    label: const Text('Clipboard', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6))),
                  ChoiceChip(label: const Text('TCP', style: TextStyle(fontSize: 11)),
                    selected: vpn.pingMethod == PingMethod.tcp,
                    onSelected: (_) => vpn.setPingMethod(PingMethod.tcp), visualDensity: VisualDensity.compact),
                  ChoiceChip(label: const Text('HTTP', style: TextStyle(fontSize: 11)),
                    selected: vpn.pingMethod == PingMethod.httpGet,
                    onSelected: (_) => vpn.setPingMethod(PingMethod.httpGet), visualDensity: VisualDensity.compact),
                  OutlinedButton(onPressed: vpn.allNodes.isEmpty ? null : () => vpn.pingAll(),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                    child: const Text('Ping all', style: TextStyle(fontSize: 11))),
                ]),
                if (vpn.error != null) ...[const SizedBox(height: 6),
                  Container(padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(vpn.error!, style: const TextStyle(color: AppTheme.danger, fontSize: 11)))],
                const SizedBox(height: 10),
                Expanded(child: vpn.subscriptions.isEmpty
                  ? const Center(child: Text('Import a subscription', style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                    itemCount: vpn.subscriptions.length,
                    itemBuilder: (_, si) {
                      final sub = vpn.subscriptions[si];
                      // Calculate global index offset for this subscription
                      int offset = 0;
                      for (var k = 0; k < si; k++) offset += vpn.subscriptions[k].nodes.length;

                      return Card(margin: const EdgeInsets.only(bottom: 8), color: AppTheme.surface,
                        child: Column(children: [
                          // Subscription header (tap to expand/collapse)
                          InkWell(onTap: () => vpn.toggleSubscription(si),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(children: [
                                Icon(sub.expanded ? Icons.expand_more : Icons.chevron_right, size: 20, color: AppTheme.neon),
                                const SizedBox(width: 8),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
                                  Text('${sub.nodes.length} nodes${sub.url != null ? " • ${Uri.parse(sub.url!).host}" : ""}',
                                      style: const TextStyle(fontSize: 10, color: Colors.white38)),
                                ])),
                                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                                  onPressed: () => vpn.removeSubscription(si), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                              ]))),
                          // Nodes list (collapsible)
                          if (sub.expanded) ...List.generate(sub.nodes.length, (ni) {
                            final gi = offset + ni;
                            final n = sub.nodes[ni];
                            final sel = gi == vpn.selectedIndex;
                            final ping = vpn.latencyFor(gi);
                            return ListTile(dense: true, visualDensity: VisualDensity.compact,
                              leading: Icon(Icons.vpn_key_rounded, size: 18, color: sel ? AppTheme.neon : Colors.white54),
                              title: Text(n.name.isEmpty ? n.host : n.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              subtitle: Text('${n.protocol} • ${n.host}:${n.port}', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                              trailing: ping == null
                                ? const Text('--', style: TextStyle(color: Colors.white38, fontSize: 11))
                                : Text('$ping ms', style: TextStyle(color: ping < 200 ? AppTheme.neon : AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 11)),
                              onTap: () => vpn.selectNode(gi),
                              selected: sel, selectedTileColor: AppTheme.neon.withOpacity(0.08));
                          }),
                        ]));
                    })),
              ]),
            )),
          ]),
        ),
      );
    });
  }

  Widget _row(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [Text(l, style: const TextStyle(color: Colors.white54, fontSize: 11)), const Spacer(),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))]));
}
