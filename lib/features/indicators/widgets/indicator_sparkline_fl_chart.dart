// Fallback sparkline on fl_chart.
// To restore: in indicator_list_tile.dart replace IndicatorSparkline
// with FlChartMiniSparkline from this file.

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pulse/core/database/db.dart';
import 'package:pulse/core/database/metrics_registory.dart';
import 'package:pulse/theme/app_colors.dart';

class FlChartMiniSparkline extends StatelessWidget {
  final MetricDef metric;
  final List<Measurement> records;
  final Color Function(MetricStatus?) colorForStatus;

  const FlChartMiniSparkline({
    super.key,
    required this.metric,
    required this.records,
    required this.colorForStatus,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = records.where((r) => r.values[0] != null).toList();
    if (filtered.length < 2) return const SizedBox.shrink();

    final recent = filtered.length > 16
        ? filtered.sublist(filtered.length - 16)
        : filtered;

    final spots = <FlSpot>[];
    for (var i = 0; i < recent.length; i++) {
      spots.add(FlSpot(i.toDouble(), recent[i].values[0]!));
    }

    final normalMin = metric.normal[0][0];
    final normalMax = metric.normal[0][1];

    final allY = <double>[...spots.map((s) => s.y), ?normalMin, ?normalMax];

    final minY = allY.reduce(min);
    final maxY = allY.reduce(max);
    final span = maxY - minY;
    final pad = span > 0 ? span * 0.15 : 1.0;

    return IgnorePointer(
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY - pad,
          maxY: maxY + pad,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (normalMin != null)
                HorizontalLine(
                  y: normalMin,
                  color: AppColors.ok.withValues(alpha: 0.45),
                  strokeWidth: 0.8,
                  dashArray: [3, 3],
                ),
              if (normalMax != null)
                HorizontalLine(
                  y: normalMax,
                  color: AppColors.ok.withValues(alpha: 0.45),
                  strokeWidth: 0.8,
                  dashArray: [3, 3],
                ),
            ],
          ),
          lineBarsData: _buildZoneBars(spots),
        ),
        duration: Duration.zero,
      ),
    );
  }

  List<LineChartBarData> _buildZoneBars(List<FlSpot> spots) {
    final cuts = <double>{
      ...[?metric.critical[0][0], ?metric.critical[0][1]],
      ...[?metric.normal[0][0], ?metric.normal[0][1]],
    }.toList()..sort();

    final bars = <LineChartBarData>[];
    var piece = <FlSpot>[];
    MetricStatus? pieceStatus;

    void flush() {
      if (piece.length > 1 && pieceStatus != null) {
        bars.add(
          LineChartBarData(
            spots: piece,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: colorForStatus(pieceStatus),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        );
      }
      piece = [];
    }

    void addSegment(FlSpot a, FlSpot b) {
      final status = metric.fieldStatus(0, (a.y + b.y) / 2);
      if (status != pieceStatus) {
        flush();
        pieceStatus = status;
        piece = [a];
      }
      piece.add(b);
    }

    for (var i = 0; i < spots.length - 1; i++) {
      final a = spots[i];
      final b = spots[i + 1];
      final lo = min(a.y, b.y);
      final hi = max(a.y, b.y);
      final inside = cuts.where((c) => c > lo && c < hi).toList();
      final crossings = a.y < b.y ? inside : inside.reversed.toList();

      var from = a;
      for (final c in crossings) {
        final t = (c - a.y) / (b.y - a.y);
        final point = FlSpot(a.x + (b.x - a.x) * t, c);
        addSegment(from, point);
        from = point;
      }
      addSegment(from, b);
    }
    flush();

    return bars;
  }
}
