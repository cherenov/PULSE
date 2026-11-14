import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/database/db.dart';
import 'package:pulse/core/database/db_providers.dart';
import 'package:pulse/core/database/metrics_registory.dart';
import 'package:pulse/theme/app_colors.dart';

class IndicatorListTile extends ConsumerWidget {
  final MetricDef metric;
  final Measurement? measurement;
  final VoidCallback? onTap;

  const IndicatorListTile({
    super.key,
    required this.metric,
    required this.measurement,
    this.onTap,
  });

  MetricStatus? get status {
    if (measurement == null) return null;

    return metric.status(
      measurement!.values.take(metric.fields.length).toList(),
    );
  }

  Color _colorForStatus(MetricStatus? s) {
    switch (s) {
      case MetricStatus.ok:
        return AppColors.ok;
      case MetricStatus.warning:
        return AppColors.warning;
      case MetricStatus.critical:
        return AppColors.critical;
      case null:
        return AppColors.textDisabled;
    }
  }

  Color get statusColor => _colorForStatus(status);

  String get statusLabel {
    switch (status) {
      case MetricStatus.ok:
        return 'Normal';
      case MetricStatus.warning:
        return 'Warning';
      case MetricStatus.critical:
        return 'Critical';
      case null:
        return 'No data';
    }
  }

  String get formattedValue {
    final record = measurement;
    if (record == null) return '—';

    final values = record.values;
    final lines = <String>[];

    for (var i = 0; i < metric.fields.length; i++) {
      final value = values[i];
      if (value == null) continue;

      final formatted = metric.format(value);

      if (metric.fields.length == 1) {
        lines.add('$formatted ${metric.unit}');
      } else {
        lines.add('${metric.fields[i]}: $formatted ${metric.unit}');
      }
    }

    return lines.isEmpty ? '—' : lines.join('\n');
  }

  String get recordedTime {
    final record = measurement;
    if (record == null) return '';

    final date = record.takenAt.toLocal();
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');

    if (isToday) {
      return 'Today, $hours:$minutes';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month, $hours:$minutes';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasData = measurement != null;
    final color = statusColor;
    final historyAsync = ref.watch(indicatorHistoryProvider(metric.id));

    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Вертикальний індикатор статусу
              Container(
                width: 6,
                height: 51,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              const SizedBox(width: 12),

              // Назва показника та статус
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasData
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: hasData ? color : AppColors.textDisabled,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Міні-прев'ю графіка (спарклайн)
              if (hasData) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  height: 36,
                  child: historyAsync.maybeWhen(
                    data: (records) => _MiniSparkline(
                      metric: metric,
                      records: records,
                      colorForStatus: _colorForStatus,
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ),
              ],

              const SizedBox(width: 10),

              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedValue,
                      textAlign: TextAlign.end,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasData
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                        fontSize: hasData ? 13 : 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasData) ...[
                      const SizedBox(height: 6),
                      Text(
                        recordedTime,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final MetricDef metric;
  final List<Measurement> records;
  final Color Function(MetricStatus?) colorForStatus;

  const _MiniSparkline({
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
