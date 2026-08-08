import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _urlCtrl = TextEditingController();
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnState>(builder: (context, vpn, _) {
      final connected = vpn.status == VpnStatus.connected;
      final connecting = vpn.status == VpnStatus.connecting;
      final node = vpn.selectedNode;

      // Start/stop pulse animation
      if (connected && !_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
      if (!connected && _pulseCtrl.isAnimating) _pulseCtrl.stop();

      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: SafeArea(
          child: Column(children: [
            // Top bar
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(children: [
                const Text('fl-client', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5)),
                const Spacer(),
                _iconBtn(Icons.article_outlined, () => _showLogs(context, vpn)),
                const SizedBox(width: 12),
                _iconBtn(Icons.settings_rounded, () => _showSettings(context, vpn)),
              ])),

            // Power button + status
            Expanded(flex: 2, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              AnimatedBuilder(animation: _pulseAnim, builder: (_, __) {
                return Transform.scale(scale: connected ? _pulseAnim.value : 1.0,
                  child: GestureDetector(onTap: vpn.busy ? null : vpn.toggle,
                    child: AnimatedContainer(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic,
                      width: 180, height: 180,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: connected ? AppTheme.success.withOpacity(0.15) : AppTheme.card,
                        border: Border.all(width: 4, color: connected ? AppTheme.success : connecting ? AppTheme.accent : AppTheme.textSecondary.withOpacity(0.3))),
                      child: Icon(
                        connected ? Icons.stop_rounded : connecting ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded,
                        size: 72, color: connected ? AppTheme.success : connecting ? AppTheme.accent : AppTheme.textSecondary))));
              }),
              const SizedBox(height: 20),
              AnimatedSwitcher(duration: const Duration(milliseconds: 300),
                child: Text(
                  connected ? 'ПОДКЛЮЧЕНО' : connecting ? 'ПОДКЛЮЧЕНИЕ...' : vpn.status == VpnStatus.disconnecting ? 'ОТКЛЮЧЕНИЕ...' : 'НАЖМИТЕ ДЛЯ ПОДКЛЮЧЕНИЯ',
                  key: ValueKey(vpn.status),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                      color: connected ? AppTheme.success : AppTheme.textSecondary))),
              if (node != null) ...[const SizedBox(height: 8),
                Text('${extractFlag(node.name)} ${node.name.isEmpty ? node.host : node.name}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500))],
              if (vpn.error != null) ...[const SizedBox(height: 12),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.danger.withOpacity(0.3))),
                    child: Row(children: [
                      Expanded(child: Text(vpn.error!, style: const TextStyle(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 3, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      GestureDetector(onTap: vpn.clearError, child: const Icon(Icons.close, size: 16, color: AppTheme.danger)),
                    ])))],
            ])),

            // Bottom: import + server list directly
            Expanded(flex: 3, child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(children: [
                // Import row
                Row(children: [
                  Expanded(child: Container(height: 44,
                    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.card)),
                    child: TextField(controller: _urlCtrl, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(hintText: 'URL подписки...', hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: () => vpn.addSubscriptionFromUrl(_urlCtrl.text),
                    style: FilledButton.styleFrom(minimumSize: const Size(72, 44), padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Fetch', style: TextStyle(fontWeight: FontWeight.w700))),
                  const SizedBox(width: 6),
                  OutlinedButton(onPressed: () => vpn.addSubscriptionFromClipboard(),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(44, 44), padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: AppTheme.card)),
                    child: const Icon(Icons.content_paste_rounded, size: 18)),
                ]),
                const SizedBox(height: 8),
                // Ping controls
                Row(children: [
                  ChoiceChip(label: const Text('TCP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    selected: vpn.pingMethod == PingMethod.tcp, onSelected: (_) => vpn.setPingMethod(PingMethod.tcp),
                    visualDensity: VisualDensity.compact, selectedColor: AppTheme.accent.withOpacity(0.2)),
                  const SizedBox(width: 6),
                  ChoiceChip(label: const Text('HTTP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    selected: vpn.pingMethod == PingMethod.httpGet, onSelected: (_) => vpn.setPingMethod(PingMethod.httpGet),
                    visualDensity: VisualDensity.compact, selectedColor: AppTheme.accent.withOpacity(0.2)),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: vpn.allNodes.isEmpty ? null : () => vpn.pingAll(),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Ping all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                  const Spacer(),
                  Text('${vpn.allNodes.length} серверов', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 8),
                // Server list directly here
                Expanded(child: vpn.subscriptions.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.vpn_key_off_rounded, size: 48, color: AppTheme.textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      const Text('Добавьте подписку', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    ]))
                  : ScrollConfiguration(behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                    child: ListView.builder(physics: const BouncingScrollPhysics(), padding: EdgeInsets.zero,
                      itemCount: vpn.subscriptions.length,
                      itemBuilder: (_, si) {
                        final sub = vpn.subscriptions[si];
                        int offset = 0;
                        for (var k = 0; k < si; k++) offset += vpn.subscriptions[k].nodes.length;
                        return Container(margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
                          child: Column(children: [
                            InkWell(onTap: () => vpn.toggleSubscription(si), borderRadius: BorderRadius.circular(14),
                              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(children: [
                                  AnimatedRotation(turns: sub.expanded ? 0.25 : 0, duration: const Duration(milliseconds: 200),
                                    child: const Icon(Icons.arrow_right_rounded, color: AppTheme.accent, size: 24)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis)),
                                  Text('${sub.nodes.length}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  GestureDetector(onTap: () => vpn.removeSubscription(si),
                                    child: Container(width: 28, height: 28, decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                      child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.danger))),
                                ]))),
                            if (sub.expanded) ...List.generate(sub.nodes.length, (ni) {
                              final gi = offset + ni;
                              final n = sub.nodes[ni];
                              final sel = gi == vpn.selectedIndex;
                              final ping = vpn.latencyFor(gi);
                              final flag = extractFlag(n.name);
                              return GestureDetector(onTap: () => vpn.selectNode(gi),
                                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sel ? AppTheme.accent.withOpacity(0.12) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: sel ? Border.all(color: AppTheme.accent.withOpacity(0.4), width: 1.5) : null),
                                  child: Row(children: [
                                    Text(flag, style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 10),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(n.name.isEmpty ? n.host : n.name, style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: sel ? FontWeight.w700 : FontWeight.w400), overflow: TextOverflow.ellipsis),
                                      Text('${n.protocol.toUpperCase()} · ${n.host}:${n.port}', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                                    ])),
                                    if (ping != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: (ping < 200 ? AppTheme.success : AppTheme.danger).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                      child: Text('$ping ms', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ping < 200 ? AppTheme.success : AppTheme.danger))),
                                  ])));
                            }),
                          ]));
                      }))),
              ]))),
          ]),
        ),
      );
    });
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 20, color: AppTheme.textSecondary)));

  void _showLogs(BuildContext context, VpnState vpn) {
    showModalBottomSheet(context: context, backgroundColor: AppTheme.bg, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(initialChildSize: 0.6, maxChildSize: 0.95, minChildSize: 0.3, expand: false,
        builder: (ctx2, sc) => Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              const Text('Логи', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const Spacer(),
              TextButton(onPressed: vpn.clearLogs, child: const Text('Очистить', style: TextStyle(fontWeight: FontWeight.w600))),
            ])),
          Expanded(child: ListView.builder(controller: sc, physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: vpn.logLines.length,
            itemBuilder: (_, i) => Padding(padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(vpn.logLines[i], style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.textSecondary)))),
        ])));
  }

  void _showSettings(BuildContext context, VpnState vpn) {
    showModalBottomSheet(context: context, backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(2))),
          const Text('Настройки', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          Container(decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.speed_rounded, color: AppTheme.accent),
                title: const Text('Метод пинга', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                trailing: SegmentedButton<PingMethod>(
                  segments: const [ButtonSegment(value: PingMethod.tcp, label: Text('TCP')), ButtonSegment(value: PingMethod.httpGet, label: Text('HTTP'))],
                  selected: {vpn.pingMethod}, onSelectionChanged: (s) => vpn.setPingMethod(s.first))),
              const Divider(height: 1, color: AppTheme.card),
              ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.memory_rounded, color: AppTheme.accent),
                title: const Text('Ядро', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text(vpn.coreAvailable ? 'sing-box (process)' : 'Недоступно',
                    style: TextStyle(color: vpn.coreAvailable ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.w500))),
            ])),
          const SizedBox(height: 24),
        ])));
  }
}
