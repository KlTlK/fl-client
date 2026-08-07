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
        backgroundColor: AppTheme.bg,
        body: SafeArea(
          child: Column(children: [
            // Top bar
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                const Row(children: [
                  Icon(Icons.auto_awesome_rounded, color: AppTheme.accentSoft, size: 24),
                  SizedBox(width: 8),
                  Text('fl-client', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                ]),
                const Spacer(),
                _iconBtn(Icons.article_outlined, () => _showLogs(context, vpn)),
                const SizedBox(width: 10),
                _iconBtn(Icons.tune_rounded, () => _showServers(context, vpn)),
                const SizedBox(width: 10),
                _iconBtn(Icons.settings_rounded, () => _showSettings(context, vpn)),
              ])),

            // Center: big power button
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(onTap: vpn.toggle,
                child: Container(width: 220, height: 220,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: AppTheme.card,
                    border: Border.all(color: connected ? AppTheme.success.withOpacity(0.5) : AppTheme.surface, width: 3),
                    boxShadow: [BoxShadow(color: (connected ? AppTheme.success : AppTheme.accent).withOpacity(0.15), blurRadius: 40, spreadRadius: 10)]),
                  child: Icon(connected ? Icons.power_settings_new_rounded : Icons.power_settings_new_rounded,
                      size: 80, color: connected ? AppTheme.success : AppTheme.textSecondary))),
              const SizedBox(height: 24),
              Text(
                connected ? 'Подключено' : vpn.status == VpnStatus.connecting ? 'Подключение...' : 'Нажмите для подключения',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: connected ? AppTheme.success : AppTheme.textPrimary)),
              const SizedBox(height: 8),
              if (node != null) Text(
                '${extractFlag(node.name)} ${node.name.isEmpty ? node.host : node.name}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              if (vpn.error != null) ...[const SizedBox(height: 12),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Expanded(child: Text(vpn.error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12))),
                      GestureDetector(onTap: () => vpn.clearError(), child: const Icon(Icons.close, size: 14, color: AppTheme.danger)),
                    ])))],
            ])),

            // Bottom: servers button + import
            Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(children: [
                if (vpn.allNodes.isEmpty)
                  const Padding(padding: EdgeInsets.only(bottom: 12),
                    child: Text('Серверов пока нет — добавьте подписку', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                // Import row (compact)
                Row(children: [
                  Expanded(child: Container(
                    height: 44, decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                    child: TextField(controller: _urlCtrl, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(hintText: 'URL подписки...', hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: () => vpn.addSubscriptionFromUrl(_urlCtrl.text),
                    style: FilledButton.styleFrom(minimumSize: const Size(70, 44), padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: AppTheme.accent),
                    child: const Text('Fetch', style: TextStyle(fontSize: 12))),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(onPressed: () => vpn.addSubscriptionFromClipboard(),
                    icon: const Icon(Icons.content_paste_rounded, size: 14), label: const Text('', ),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(44, 44), padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: AppTheme.card))),
                ]),
                const SizedBox(height: 10),
                // All servers button
                SizedBox(width: double.infinity, height: 52,
                  child: FilledButton.icon(
                    onPressed: vpn.allNodes.isEmpty ? null : () => _showServers(context, vpn),
                    icon: const Icon(Icons.view_list_rounded, size: 20),
                    label: Text(vpn.allNodes.isEmpty ? 'Нет серверов' : 'Все серверы (${vpn.allNodes.length})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.surface, foregroundColor: AppTheme.textPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0))),
              ])),
          ]),
        ),
      );
    });
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 20, color: AppTheme.textSecondary)));

  void _showServers(BuildContext context, VpnState vpn) {
    showModalBottomSheet(context: context, backgroundColor: AppTheme.bg, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
        builder: (ctx, sc) => Consumer<VpnState>(builder: (_, vpn2, __) => Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              const Text('Серверы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const Spacer(),
              ChoiceChip(label: const Text('TCP', style: TextStyle(fontSize: 11)), selected: vpn2.pingMethod == PingMethod.tcp,
                onSelected: (_) => vpn2.setPingMethod(PingMethod.tcp), visualDensity: VisualDensity.compact),
              const SizedBox(width: 4),
              ChoiceChip(label: const Text('HTTP', style: TextStyle(fontSize: 11)), selected: vpn2.pingMethod == PingMethod.httpGet,
                onSelected: (_) => vpn2.setPingMethod(PingMethod.httpGet), visualDensity: VisualDensity.compact),
              const SizedBox(width: 6),
              OutlinedButton(onPressed: vpn2.allNodes.isEmpty ? null : () => vpn2.pingAll(),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('Ping', style: TextStyle(fontSize: 11))),
            ])),
          Expanded(child: ScrollConfiguration(behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: ListView.builder(controller: sc, physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: vpn2.subscriptions.length,
              itemBuilder: (_, si) {
                final sub = vpn2.subscriptions[si];
                int offset = 0;
                for (var k = 0; k < si; k++) offset += vpn2.subscriptions[k].nodes.length;
                return Container(margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    InkWell(onTap: () => vpn2.toggleSubscription(si), borderRadius: BorderRadius.circular(16),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(children: [
                          Icon(sub.expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded, color: AppTheme.accentSoft, size: 22),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis),
                            Text('${sub.nodes.length} серверов', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ])),
                          GestureDetector(onTap: () => vpn2.removeSubscription(si),
                            child: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.danger))),
                        ]))),
                    if (sub.expanded) ...List.generate(sub.nodes.length, (ni) {
                      final gi = offset + ni;
                      final n = sub.nodes[ni];
                      final sel = gi == vpn2.selectedIndex;
                      final ping = vpn2.latencyFor(gi);
                      final flag = extractFlag(n.name);
                      return GestureDetector(onTap: () => vpn2.selectNode(gi),
                        child: Container(margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: sel ? AppTheme.accent.withOpacity(0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12), border: sel ? Border.all(color: AppTheme.accent.withOpacity(0.3)) : null),
                          child: Row(children: [
                            Text(flag, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(n.name.isEmpty ? n.host : n.name, style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal), overflow: TextOverflow.ellipsis),
                              Text('${n.protocol.toUpperCase()} • ${n.host}:${n.port}', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                            ])),
                            if (ping != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: (ping < 200 ? AppTheme.success : AppTheme.danger).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text('$ping ms', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ping < 200 ? AppTheme.success : AppTheme.danger))),
                          ])));
                    }),
                  ]));
              }))),
        ]))),
      ));
  }

  void _showLogs(BuildContext context, VpnState vpn) {
    showModalBottomSheet(context: context, backgroundColor: AppTheme.bg, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.6, maxChildSize: 0.95, minChildSize: 0.3, expand: false,
        builder: (ctx, sc) => Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              const Text('Логи', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const Spacer(),
              TextButton(onPressed: () => vpn.clearLogs(), child: const Text('Очистить')),
            ])),
          Expanded(child: ListView.builder(controller: sc, physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: vpn.logLines.length,
            itemBuilder: (_, i) => Padding(padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(vpn.logLines[i], style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.textSecondary)))),
        ])),
      ));
  }

  void _showSettings(BuildContext context, VpnState vpn) {
    showModalBottomSheet(context: context, backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(2))),
          const Text('Настройки', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          Container(decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16), leading: const Icon(Icons.speed_rounded, color: AppTheme.accentSoft),
                title: const Text('Метод пинга', style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(vpn.pingMethod.name.toUpperCase(), style: const TextStyle(color: AppTheme.textSecondary)),
                trailing: SegmentedButton<PingMethod>(
                  segments: const [ButtonSegment(value: PingMethod.tcp, label: Text('TCP')), ButtonSegment(value: PingMethod.httpGet, label: Text('HTTP'))],
                  selected: {vpn.pingMethod}, onSelectionChanged: (s) => vpn.setPingMethod(s.first))),
              const Divider(height: 1, color: AppTheme.card),
              ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16), leading: const Icon(Icons.memory_rounded, color: AppTheme.accentSoft),
                title: const Text('Ядро', style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(vpn.coreAvailable ? 'sing-box (process)' : 'Недоступно',
                    style: TextStyle(color: vpn.coreAvailable ? AppTheme.success : AppTheme.danger))),
            ])),
          const SizedBox(height: 24),
        ])));
  }
}
