import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../state/vpn_state.dart';

/// FlClash-style animated power button: pulsing glow when connected,
/// ripple on tap, smooth color morph between states.
class PowerButton extends StatelessWidget {
  final VpnState state;
  final VoidCallback onTap;
  const PowerButton({super.key, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final connected = state.status == VpnStatus.connected;
    final busy = state.status == VpnStatus.connecting ||
        state.status == VpnStatus.disconnecting;
    final color = connected
        ? AppTheme.accent
        : (busy ? AppTheme.accentSoft : AppTheme.danger);

    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withOpacity(0.35),
            color.withOpacity(0.05),
          ]),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.6), blurRadius: 50, spreadRadius: 4),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
            border: Border.all(color: color, width: 3),
          ),
          child: Icon(
            Icons.power_settings_new_rounded,
            size: 70,
            color: color,
          ),
        ),
      )
          .animate(onPlay: (c) => connected ? c.repeat() : null)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.06, 1.06),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeInOut,
          )
          .then()
          .scale(
            end: const Offset(1, 1),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeInOut,
          ),
    );
  }
}
