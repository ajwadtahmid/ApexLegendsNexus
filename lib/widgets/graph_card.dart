import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/storage.dart';
import '../utils/theme.dart';
import '../utils/format.dart' show fmtRp;

class GraphCard extends StatelessWidget {
  final List<StatSnapshot> snapshots;
  final String title;

  const GraphCard({super.key, required this.snapshots, required this.title});

  @override
  Widget build(BuildContext context) {
    final spots = snapshots.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.rp.toDouble());
    }).toList();

    final dateLabel = snapshots.length >= 2
        ? '${DateFormat('MMM d').format(snapshots.first.timestamp)} – ${DateFormat('MMM d').format(snapshots.last.timestamp)}'
        : '';

    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.muted,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.md),
          SizedBox(
            height: 110,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surface2,
                    getTooltipItems: (spots) => spots.map((s) {
                      final idx = s.x.toInt().clamp(0, snapshots.length - 1);
                      final snap = snapshots[idx];
                      return LineTooltipItem(
                        '${fmtRp(snap.rp)} RP\n${DateFormat('MMM d, h:mm a').format(snap.timestamp)}',
                        const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: AppTheme.accent,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 3,
                            color: AppTheme.accent,
                            strokeColor: AppTheme.surface,
                            strokeWidth: 1.5,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.accent.withAlpha(40),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
