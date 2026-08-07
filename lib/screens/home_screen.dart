import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../state/vpn_state.dart';
import '../core/pinger.dart';
import '../core/flags.dart';

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
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Top bar
              Row(children: [
                const Text('fl-client', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const Spacer(),
                _iconBtn(Icons.article_outlined, () => _showLogs(context, vpn)),
                const SizedBox(width: 8),
                _iconBtn(Icons.settings_rounded, () => _showSettings(context, vpn)),
              ]),
              const SizedBox(height: 24),
              // Main area: left = nodes, right = connect button
              Expanded(child: Row(children: [
                // LEFT: subscription + nodes
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // Import row
                  Row(children: [
                    Expanded(child: Container(
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                      child: TextField(controller: _urlCtrl, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(hintText: 'Subscription URL...', hintStyle: TextStyle(color: AppTheme.textSecondary),
                            border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                    )),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: () => vpn.addSubscriptionFromUrl(_urlCtrl.text),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Fetch')),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    _chip('Clipboard', Icons.content_paste_rounded, () => vpn.addSubscriptionFromClipboard()),
                    ChoiceChip(label: const Text('TCP', style: TextStyle(fontSize: 11)),
                      selected: vpn.pingMethod == PingMethod.tcp,
                      onSelected: (_) => vpn.setPingMethod(PingMethod.tcp), visualDensity: VisualDensity.compact,
                      side: BorderSide(color: vpn.pingMethod == PingMethod.tcp ? AppTheme.accent : Colors.transparent)),
                    ChoiceChip(label: const Text('HTTP', style: TextStyle(fontSize: 11)),
                      selected: vpn.pingMethod == PingMethod.httpGet,
                      onSelected: (_) => vpn.setPingMethod(PingMethod.httpGet), visualDensity: VisualDensity.compact,
                      side: BorderSide(color: vpn.pingMethod == PingMethod.httpGet ? AppTheme.accent : Colors.transparent)),
                    _chip('Ping all', Icons.speed_rounded, vpn.allNodes.isEmpty ? null : () => vpn.pingAll()),
                  ]),
                  if (vpn.error != null) ...[const SizedBox(height: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [Expanded(child: Text(vpn.error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12))),
                        IconButton(icon: const Icon(Icons.close, size: 14), onPressed: () { vpn.clearError(); }, padding: EdgeInsets.zero, constraints: const BoxConstraints())]))],
                  const SizedBox(height: 12),
                  // Nodes list with smooth scrolling
                  Expanded(child: vpn.subscriptions.isEmpty
                    ? Center(child: Text('Import a subscription', style: TextStyle(color: AppTheme.textSecondary)))
                    : ScrollConfiguration(behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: vpn.subscriptions.length,
                        itemBuilder: (_, si) {
                          final sub = vpn.subscriptions[si];
                          int offset = 0;
                          for (var k = 0; k < si; k++) offset += vpn.subscriptions[k].nodes.length;
                          return Container(margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
                            child: Column(children: [
                              InkWell(onTap: () => vpn.toggleSubscription(si), borderRadius: BorderRadius.circular(14),
                                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(children: [
                                    Icon(sub.expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded, color: AppTheme.accentSoft),
                                    const SizedBox(width: 8),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis),
                                      Text('${sub.nodes.length} nodes', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                    ])),
                                    IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.danger),
                                      onPressed: () => vpn.removeSubscription(si), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                                  ]))),
                              if (sub.expanded) ...List.generate(sub.nodes.length, (ni) {
                                final gi = offset + ni;
                                final n = sub.nodes[ni];
                                final sel = gi == vpn.selectedIndex;
                                final ping = vpn.latencyFor(gi);
                                final flag = extractFlag(n.name);
                                return InkWell(onTap: () => vpn.selectNode(gi), borderRadius: BorderRadius.circular(10),
                                  child: Container(margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel ? AppTheme.accent.withOpacity(0.15) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: sel ? Border.all(color: AppTheme.accent.withOpacity(0.4)) : null),
                                    child: Row(children: [
                                      Text(flag, style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 10),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(n.name.isEmpty ? n.host : n.name, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal), overflow: TextOverflow.ellipsis),
                                        Text('${n.protocol} • ${n.host}:${n.port}', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                      ])),
                                      if (ping != null) Text('$ping ms', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ping < 200 ? AppTheme.success : AppTheme.danger)),
                                    ])));
                              }),
                            ]));
                        }))),
                ])),
                const SizedBox(width: 24),
                // RIGHT: big connect button + status
                SizedBox(width: 200, child: Column(children: [
                  const Spacer(),
                  // Status
                  AnimatedSwitcher(duration: const Duration(milliseconds: 300),
                    child: Text(connected ? 'Connected' : vpn.status.name.toUpperCase().replaceAll('_', ' '),
                      key: ValueKey(vpn.status),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1,
                          color: connected ? AppTheme.success : AppTheme.textSecondary))),
                  const SizedBox(height: 8),
                  if (node != null) Text(extractFlag(node.name) + ' ' + (node.name.isEmpty ? node.host : node.name),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  // BIG connect button
                  GestureDetector(onTap: vpn.toggle,
                    child: AnimatedContainer(duration: const Duration(milliseconds: 300),
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: connected ? AppTheme.success.withOpacity(0.15) : AppTheme.card,
                        border: Border.all(color: connected ? AppTheme.success : AppTheme.accent, width: 3),
                        boxShadow: [BoxShadow(color: (connected ? AppTheme.success : AppTheme.accent).withOpacity(0.3), blurRadius: 30, spreadRadius: 5)]),
                      child: Icon(connected ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          size: 64, color: connected ? AppTheme.success : AppTheme.accent))),
                  const SizedBox(height: 16),
                  Text(vpn.allNodes.length > 0 ? '${vpn.allNodes.length} nodes' : '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const Spacer(),
                ])),
              ])),
            ]),
          ),
        ),
      );
    });
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(10),
    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 20, color: AppTheme.textSecondary)));

  Widget _chip(String label, IconData icon, VoidCallback? onTap) => OutlinedButton.icon(
    onPressed: onTap, icon: Icon(icon, size: 14), label: Text(label, style: const TextStyle(fontSize: 11)),
    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppTheme.card)));

  void _showLogs(BuildContext context, VpnState vpn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.3, expand: false,
        builder: (ctx, sc) => Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            const Text('Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const Spacer(),
            TextButton(onPressed: () => vpn.clearLogs(), child: const Text('Clear')),
          ])),
          Expanded(child: ListView.builder(
            controller: sc,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: vpn.logLines.length,
            itemBuilder: (ctx2, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(vpn.logLines[i], style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.textSecondary)),
            ),
          )),
        ]),
      ),
    );
  }

  void _showSettings(BuildContext context, VpnState vpn) {
    showModalBottomSheet(context: context, backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.speed_rounded, color: AppTheme.accentSoft),
            title: const Text('Ping method', style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: Text(vpn.pingMethod.name, style: const TextStyle(color: AppTheme.textSecondary)),
            trailing: SegmentedButton<PingMethod>(
              segments: const [ButtonSegment(value: PingMethod.tcp, label: Text('TCP')), ButtonSegment(value: PingMethod.httpGet, label: Text('HTTP'))],
              selected: {vpn.pingMethod}, onSelectionChanged: (s) => vpn.setPingMethod(s.first))),
          const Divider(color: AppTheme.card),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.info_outline_rounded, color: AppTheme.accentSoft),
            title: const Text('Core', style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: Text(vpn.coreAvailable ? 'sing-box (process mode)' : 'Not available: ${vpn.coreError}',
                style: TextStyle(color: vpn.coreAvailable ? AppTheme.success : AppTheme.danger))),
          const SizedBox(height: 20),
        ])));
  }
}
