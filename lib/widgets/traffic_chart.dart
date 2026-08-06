import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../state/vpn_state.dart';

class TrafficChart extends StatelessWidget {
  final VpnState state;
  const TrafficChart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final spotsUp = [
      for (var i = 0; i < state.traffic.length; i++)
        FlSpot(i.toDouble(), state.traffic[i].up)
    ];
    final spotsDown = [
      for (var i = 0; i < state.traffic.length; i++)
        FlSpot(i.toDouble(), state.traffic[i].down)
    ];
    final maxY = (state.traffic.isEmpty
            ? 100.0
            : state.traffic.map((e) => e.down).reduce((a, b) => a > b ? a : b)) +
        50;

    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            animationDuration: const Duration(milliseconds: 600),
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: 40,
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spotsDown,
                isCurved: true,
                color: AppTheme.neonAlt,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.neonAlt.withOpacity(0.18),
                ),
              ),
              LineChartBarData(
                spots: spotsUp,
                isCurved: true,
                color: AppTheme.neon,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.neon.withOpacity(0.18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
