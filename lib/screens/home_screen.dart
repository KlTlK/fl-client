import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../state/vpn_state.dart';
import '../widgets/power_button.dart';
import '../widgets/traffic_chart.dart';
import '../widgets/stat_card.dart';
import 'import_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('fl-client',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    Row(children: [
                      Icon(Icons.circle, size: 10,
                          color: vpn.coreAvailable ? AppTheme.neon : AppTheme.danger),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.settings_rounded),
                      ),
                    ]),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
                const SizedBox(height: 30),
                Center(child: PowerButton(state: vpn, onTap: vpn.toggle)),
                const SizedBox(height: 24),
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _statusLabel(vpn.status),
                      key: ValueKey(vpn.status),
                      style: TextStyle(
                        fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.w600,
                        color: connected ? AppTheme.neon : Colors.white54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    node == null
                        ? 'No node selected - import a subscription'
                        : '${node.name.isEmpty ? node.host : node.name} • ${node.protocol}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
                const TrafficChart(state: vpn),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.7,
                  children: [
                    StatCard(label: 'Latency (${vpn.pingMethod.name})',
                        value: lat > 0 ? '$lat ms' : '--',
                        icon: Icons.speed_rounded, color: AppTheme.neon),
                    StatCard(label: 'Download', value: '${vpn.downSpeed.toStringAsFixed(0)} KB/s',
                        icon: Icons.arrow_downward_rounded, color: AppTheme.neonAlt),
                    StatCard(label: 'Upload', value: '${vpn.upSpeed.toStringAsFixed(0)} KB/s',
                        icon: Icons.arrow_upward_rounded, color: AppTheme.neon),
                    StatCard(label: 'Nodes', value: '${vpn.nodes.length}',
                        icon: Icons.vpn_key_rounded, color: AppTheme.neonAlt),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ImportScreen())),
                  icon: const Icon(Icons.add_link_rounded),
                  label: const Text('Import subscription / link'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.neon,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      );
    });
  }
}
