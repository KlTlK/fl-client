import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../state/vpn_state.dart';
import '../core/pinger.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _urlCtrl = TextEditingController();
  final _rawCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // подгружаем сохранённые ноды
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VpnState>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import')),
      body: Consumer<VpnState>(builder: (context, vpn, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Subscription URL (https)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => vpn.importFromUrl(_urlCtrl.text),
              icon: const Icon(Icons.cloud_download_rounded),
              label: const Text('Fetch subscription'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _rawCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Paste link / base64',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => vpn.importFromString(_rawCtrl.text),
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Parse text'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => vpn.importFromClipboard(),
                  icon: const Icon(Icons.content_paste_rounded),
                  label: const Text('From clipboard'),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // Переключатель метода пинга + кнопка пингануть все
            Row(children: [
              const Text('Ping: ', style: TextStyle(color: Colors.white70)),
              SegmentedButton<PingMethod>(
                segments: const [
                  ButtonSegment(value: PingMethod.tcp, label: Text('TCP')),
                  ButtonSegment(value: PingMethod.httpGet, label: Text('HTTP GET')),
                ],
                selected: {vpn.pingMethod},
                onSelectionChanged: (s) => vpn.setPingMethod(s.first),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: vpn.nodes.isEmpty ? null : () => vpn.pingAll(),
                icon: const Icon(Icons.speed_rounded),
                label: const Text('Ping all'),
              ),
            ]),
            const SizedBox(height: 16),

            if (vpn.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(vpn.error!, style: const TextStyle(color: AppTheme.danger)),
              ),
            const SizedBox(height: 12),

            Text('Nodes (${vpn.nodes.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...List.generate(vpn.nodes.length, (i) {
              final n = vpn.nodes[i];
              final selected = i == vpn.selectedIndex;
              final lat = vpn.latencyFor(i);
              return Card(
                color: selected ? AppTheme.neon.withOpacity(0.12) : AppTheme.surface,
                child: ListTile(
                  leading: Icon(Icons.vpn_key_rounded,
                      color: selected ? AppTheme.neon : Colors.white54),
                  title: Text(n.name.isEmpty ? n.host : n.name),
                  subtitle: Text('${n.protocol} • ${n.host}:${n.port}'),
                  trailing: lat == null
                      ? const Text('-- ms', style: TextStyle(color: Colors.white38))
                      : Text('$lat ms',
                          style: TextStyle(
                              color: lat < 200 ? AppTheme.neon : AppTheme.danger,
                              fontWeight: FontWeight.w700)),
                  onTap: () => vpn.selectNode(i),
                ),
              );
            }),
          ],
        );
      }),
    );
  }
}
