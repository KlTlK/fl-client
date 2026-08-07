import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../state/vpn_state.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _urlCtrl = TextEditingController();
  final _rawCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import')),
      body: Consumer<VpnState>(builder: (context, vpn, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // URL подписки
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

            // Raw строка / QR результат
            TextField(
              controller: _rawCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Paste link / base64 / QR result',
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

            if (vpn.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(vpn.error!, style: const TextStyle(color: AppTheme.danger)),
              ),

            const SizedBox(height: 16),
            Text('Nodes (${vpn.nodes.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...List.generate(vpn.nodes.length, (i) {
              final n = vpn.nodes[i];
              final selected = i == vpn.selectedIndex;
              return Card(
                color: selected ? AppTheme.neon.withOpacity(0.12) : AppTheme.surface,
                child: ListTile(
                  leading: Icon(Icons.vpn_key_rounded,
                      color: selected ? AppTheme.neon : Colors.white54),
                  title: Text(n.name.isEmpty ? n.host : n.name),
                  subtitle: Text('${n.protocol} • ${n.host}:${n.port}'),
                  trailing: selected
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.neon)
                      : null,
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
